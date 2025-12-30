import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'nfc_music_mapping.dart';
import 'nfc_service.dart';
import 'music_player.dart';
import 'song.dart';
import 'storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  
  // Initialize storage service first
  try {
    debugPrint('🚀 Initializing StorageService...');
    await StorageService.instance.initialize();
    debugPrint('✅ StorageService initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize StorageService: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    // Continue without storage - app will work in memory-only mode
  }
  
  runApp(const NFCJukeboxApp());
}

class NFCJukeboxApp extends StatelessWidget {
  const NFCJukeboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NFCMusicMappingProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayer()),
        ChangeNotifierProxyProvider3<NFCMusicMappingProvider, SongProvider, MusicPlayer, NFCService>(
          create: (_) => NFCService(),
          update: (_, mapping, song, player, nfc) {
            nfc!.setProviders(
              mappingProvider: mapping,
              songProvider: song,
              musicPlayer: player,
            );
            return nfc;
          },
        ),
      ],
      child: MaterialApp(
        title: 'NFC Radio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const NFCJukeboxHomePage(),
      ),
    );
  }
}

class NFCJukeboxHomePage extends StatefulWidget {
  const NFCJukeboxHomePage({super.key});

  @override
  State<NFCJukeboxHomePage> createState() => _NFCJukeboxHomePageState();
}

class _NFCJukeboxHomePageState extends State<NFCJukeboxHomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    debugPrint('🚀 ===== APP INITIALIZATION STARTED =====');
    debugPrint('🚀 Timestamp: ${DateTime.now()}');
    
    debugPrint('🚀 ===== APP INITIALIZATION COMPLETED =====');
  }

  /// Check if we're running in a test environment
  bool _isTestEnvironment() {
    return Platform.environment.containsKey('FLUTTER_TEST') || 
           Platform.environment.containsKey('DART_VM_OPTIONS');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize providers after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      try {
        final songProvider = Provider.of<SongProvider>(context, listen: false);
        final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);
        
        if (!songProvider.isInitialized) {
          debugPrint('🔄 Initializing providers with persisted data...');
          
          // Initialize providers in parallel
          await Future.wait([
            songProvider.initialize(),
            mappingProvider.initialize(),
          ]);
          
          debugPrint('✅ All providers initialized successfully');
          debugPrint('📊 Songs loaded: ${songProvider.songs.length}');
          debugPrint('📊 Mappings loaded: ${mappingProvider.mappings.length}');
          
          // Show success message if we loaded existing data
          if (mounted && (songProvider.songs.isNotEmpty || mappingProvider.mappings.isNotEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎵 Loaded your saved songs and NFC mappings!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to initialize providers: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        
        // Show error message to user (only in non-test environments)
        if (mounted && !_isTestEnvironment()) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Failed to load saved data. App will work with empty data.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          } catch (contextError) {
            debugPrint('⚠️ Could not show error message: $contextError');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Hide UI when the app is in the background or screen is locked
      // This is handled by the Wakelock package to keep the screen awake
    }
  }

  @override
  Widget build(BuildContext context) {
    final nfcService = Provider.of<NFCService>(context);
    final musicPlayer = Provider.of<MusicPlayer>(context);
    final songProvider = Provider.of<SongProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NFC Radio'),
        actions: [
          // Debug info button (debug only)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => _showDebugDialog(context),
              tooltip: 'Debug Info',
            ),
          // Storage debug button (debug only)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.storage),
              onPressed: () => _showStorageDebugDialog(context),
              tooltip: 'Storage Debug',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // NFC Status Section (debug only)
            if (kDebugMode) Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: nfcService.isScanning ? Colors.green : Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (!nfcService.isNfcAvailable) ...[
                    const Text('NFC is not available on this device.'),
                  ] else ...[
                    const Text('Ready to scan NFC tags', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          nfcService.isScanning ? Icons.radio : Icons.radio_button_off,
                          color: nfcService.isScanning ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nfcService.isScanning 
                            ? 'Scanning for NFC tags...' 
                            : 'Scanning paused',
                          style: TextStyle(
                            color: nfcService.isScanning ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (nfcService.currentNfcUuid != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last detected: ${nfcService.currentNfcUuid}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: nfcService.isScanning ? null : () {
                            nfcService.startNfcSession();
                          },
                          child: const Text('Start Scanning'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: nfcService.isScanning ? () {
                            nfcService.stopNfcSession();
                          } : null,
                          child: const Text('Stop Scanning'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Horizontal ListView for songs
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...songProvider.songs.map((song) => Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: song.connectedNfcUuid != null
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          song.connectedNfcUuid != null ? Icons.music_note : Icons.music_off,
                          size: 40,
                          color: song.connectedNfcUuid != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.title,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (song.connectedNfcUuid != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Connected',
                            style: TextStyle(fontSize: 10, color: Colors.green[700]),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                musicPlayer.isSongPlaying(song.filePath)
                                    ? Icons.pause
                                    : musicPlayer.isSongPaused(song.filePath)
                                        ? Icons.play_arrow
                                        : musicPlayer.isSongStopped(song.filePath)
                                            ? Icons.play_arrow
                                            : Icons.play_arrow,
                                size: 20,
                                color: musicPlayer.isSongPlaying(song.filePath) 
                                    ? Colors.red 
                                    : musicPlayer.isSongPaused(song.filePath)
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                              onPressed: () async {
                                if (musicPlayer.isSongPlaying(song.filePath) || musicPlayer.isSongPaused(song.filePath)) {
                                  await musicPlayer.togglePlayPause();
                                } else {
                                  await musicPlayer.playMusic(song.filePath);
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditSongDialog(context, song, songProvider);
                                } else if (value == 'delete') {
                                  _showDeleteSongDialog(context, song, songProvider);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                  // Add new song button
                  Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: InkWell(
                      onTap: () => _showAddSongDialog(context, songProvider),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Add Song',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Music Player Section
            if (musicPlayer.isPlaying || musicPlayer.isPaused) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Now Playing: ${musicPlayer.currentMusicFilePath?.split('/').last ?? 'Unknown'}'),
                    if (musicPlayer.totalDuration > Duration.zero) ...[
                      Text('Position: ${musicPlayer.getCurrentPositionString()} / ${musicPlayer.getTotalDurationString()}'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: Slider(
                          value: musicPlayer.savedPosition.inSeconds.toDouble(),
                          min: 0,
                          max: musicPlayer.totalDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            musicPlayer.seekTo(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: musicPlayer.togglePlayPause,
                          child: Text(musicPlayer.isPlaying ? 'Pause' : 'Play'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: musicPlayer.stopMusic,
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context, SongProvider songProvider) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController filePathController = TextEditingController();
    String? dialogNfcUuid;
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);

    // Create a stateful wrapper to track dialog state
    final dialogState = _DialogState();
    
    // Store the listener function so we can remove it later
    late void Function() updateNfcUuid;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Define the listener function
          updateNfcUuid = () {
            if (!dialogState.isOpen) {
              nfcService.removeListener(updateNfcUuid);
              return;
            }
            if (nfcService.currentNfcUuid != null) {
              // Trigger UI update to show 'New NFC' button, don't auto-assign
              setState(() {
                // Just trigger a rebuild to show the "New NFC" button
              });
            }
          };
          
          // Add listener when building
          nfcService.addListener(updateNfcUuid);

          // Initialize dialogNfcUuid from current NFC state - but don't auto-assign
          // Only set if there was already an NFC assigned to this song
          // New NFC detection will show a 'New NFC' button instead

          return AlertDialog(
            title: const Text('Add New Song'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Song Title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filePathController,
                        decoration: const InputDecoration(labelText: 'File Path'),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.audio,
                          allowMultiple: false,
                        );
                        
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.path != null) {
                            final newTitle = p.basenameWithoutExtension(file.path!);
                            
                            // Check if title should be updated
                            if (titleController.text.isNotEmpty && 
                                titleController.text != newTitle) {
                              // Show confirmation dialog
                              final shouldUpdateTitle = await showDialog<bool>(
                                context: dialogContext,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Update Title?'),
                                    content: Text(
                                      'Do you want to update the title to "$newTitle"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Keep Original'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Update Title'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              
                              if (shouldUpdateTitle == true) {
                                titleController.text = newTitle;
                              }
                            }
                            
                            filePathController.text = file.path!;
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (nfcService.isNfcAvailable) ...[
                  const Text('NFC Configuration'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: dialogNfcUuid != null ? Colors.green : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: dialogNfcUuid != null
                      ? Text(
                          'Assigned NFC: ${dialogNfcUuid!.substring(0, 8)}...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : nfcService.currentNfcUuid != null
                        ? Column(
                            children: [
                              Text(
                                'New NFC detected: ${nfcService.currentNfcUuid!.substring(0, 8)}...',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    dialogNfcUuid = nfcService.currentNfcUuid;
                                  });
                                },
                                child: const Text('Use This NFC'),
                              ),
                            ],
                          )
                        : nfcService.isScanning
                          ? const Text(
                              'Scanning for NFC tags...',
                              style: TextStyle(color: Colors.blue),
                            )
                          : const Text(
                              'Waiting for NFC tag...',
                              style: TextStyle(color: Colors.grey),
                            ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogState.isOpen = false;
                  nfcService.removeListener(updateNfcUuid);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (filePathController.text.isNotEmpty) {
                    // Use provided title or auto-generate from filename
                    String finalTitle = titleController.text.isNotEmpty
                      ? titleController.text
                      : p.basenameWithoutExtension(filePathController.text);

                    final song = Song(
                      id: const Uuid().v4(),
                      title: finalTitle,
                      filePath: filePathController.text,
                    );

                    songProvider.addSong(song);

                    // If an NFC tag was scanned, create a mapping (with conflict check)
                    if (dialogNfcUuid != null) {
                      // Check if this NFC UUID is already connected to another song
                      Song? existingSong;
                      try {
                        existingSong = songProvider.songs.firstWhere(
                          (s) => s.connectedNfcUuid == dialogNfcUuid,
                        );
                      } catch (e) {
                        // No existing song found with this NFC
                        existingSong = null;
                      }
                      
                      if (existingSong != null) {
                        // Show confirmation dialog for NFC conflict
                        final shouldReplaceConnection = await showDialog<bool>(
                          context: dialogContext,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('NFC Tag Already Connected'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('This NFC tag is already connected to:'),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${existingSong!.title}"',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Do you want to:'),
                                  const SizedBox(height: 4),
                                  const Text('• Replace the connection (old song will lose NFC)'),
                                  const Text('• Keep the existing connection'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Keep Existing'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Replace Connection'),
                                ),
                              ],
                            );
                          },
                        ) ?? false;
                        
                        if (shouldReplaceConnection) {
                          // Remove NFC connection from ALL songs that have this NFC UUID
                          final songsWithThisNfc = songProvider.songs
                              .where((s) => s.connectedNfcUuid == dialogNfcUuid)
                              .toList();
                          
                          for (final songWithNfc in songsWithThisNfc) {
                            final updatedSong = Song(
                              id: songWithNfc.id,
                              title: songWithNfc.title,
                              filePath: songWithNfc.filePath,
                              connectedNfcUuid: null, // Remove NFC connection
                            );
                            songProvider.updateSong(updatedSong);
                          }
                          
                          // Add new mapping for the current song
                          mappingProvider.addMapping(
                            NFCMusicMapping(
                              nfcUuid: dialogNfcUuid!,
                              songId: song.id,
                            ),
                          );
                        }
                        // If user chose "Keep Existing", don't create any mapping
                      } else {
                        // No conflict - add mapping normally
                        mappingProvider.addMapping(
                          NFCMusicMapping(
                            nfcUuid: dialogNfcUuid!,
                            songId: song.id,
                          ),
                        );
                      }
                    }

                    dialogState.isOpen = false;
                    nfcService.removeListener(updateNfcUuid);
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    // Start NFC scanning automatically when dialog opens (if not already scanning)
    if (nfcService.isNfcAvailable && !nfcService.isScanning) {
      nfcService.startNfcSession();
    }
  }

  void _showEditSongDialog(BuildContext context, Song song, SongProvider songProvider) {
    final TextEditingController titleController = TextEditingController(text: song.title);
    final TextEditingController filePathController = TextEditingController(text: song.filePath);
    String? dialogNfcUuid = song.connectedNfcUuid;
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);

    // Create a stateful wrapper to track dialog state
    final dialogState = _DialogState();
    
    // Enable edit mode to pause player triggering during editing
    nfcService.setEditMode(true);
    
    // Store the listener function so we can remove it later
    late void Function() updateNfcUuid;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Define the listener function
          updateNfcUuid = () {
            if (!dialogState.isOpen) {
              nfcService.removeListener(updateNfcUuid);
              nfcService.setEditMode(false); // Ensure edit mode is disabled
              return;
            }
            if (nfcService.currentNfcUuid != null) {
              // Trigger UI update to show 'New NFC' button, don't auto-assign
              setState(() {
                // Just trigger a rebuild to show the "New NFC" button
              });
            }
          };
          
          // Add listener when building
          nfcService.addListener(updateNfcUuid);

          // Initialize dialogNfcUuid from current NFC state - but don't auto-assign
          // Only set if there was already an NFC assigned to this song
          // New NFC detection will show a 'New NFC' button instead

          return AlertDialog(
            title: const Text('Edit Song'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Song Title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filePathController,
                        decoration: const InputDecoration(labelText: 'File Path'),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.audio,
                          allowMultiple: false,
                        );
                        
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.path != null) {
                            final newTitle = p.basenameWithoutExtension(file.path!);
                            
                            // Check if title should be updated
                            if (titleController.text.isNotEmpty && 
                                titleController.text != newTitle) {
                              // Show confirmation dialog
                              final shouldUpdateTitle = await showDialog<bool>(
                                context: dialogContext,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Update Title?'),
                                    content: Text(
                                      'Do you want to update the title to "$newTitle"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Keep Original'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Update Title'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              
                              if (shouldUpdateTitle == true) {
                                titleController.text = newTitle;
                              }
                            }
                            
                            filePathController.text = file.path!;
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (nfcService.isNfcAvailable) ...[
                  const Text('NFC Configuration'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: dialogNfcUuid != null ? Colors.green : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show currently assigned NFC (if any)
                        if (dialogNfcUuid != null) ...[
                          Text(
                            'Assigned NFC: ${dialogNfcUuid!.substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Show new NFC detection (only if different from assigned)
                        if (nfcService.currentNfcUuid != null && 
                            nfcService.currentNfcUuid != dialogNfcUuid) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New NFC detected: ${nfcService.currentNfcUuid!.substring(0, 8)}...',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Check if this NFC UUID is already connected to another song
                                    final currentNfcUuid = nfcService.currentNfcUuid;
                                    if (currentNfcUuid == null) {
                                      // No NFC UUID available, cannot proceed
                                      return;
                                    }
                                    
                                    Song? existingSong = songProvider.songs.firstWhere(
                                      (s) => s.connectedNfcUuid == currentNfcUuid && s.id != song.id,
                                      orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
                                    );
                                    
                                    // Check if we found a valid existing song (not the empty orElse default)
                                    if (existingSong.filePath.isEmpty) {
                                      existingSong = null;
                                    }
                                    
                                    bool shouldUseNewNfc = true;
                                    
                                    if (existingSong != null && existingSong.filePath.isNotEmpty) {
                                      // Show confirmation dialog
                                      shouldUseNewNfc = await showDialog<bool>(
                                        context: dialogContext,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('NFC Tag Already Connected'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('This NFC tag is already connected to:'),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '"${existingSong!.title}"',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text('Do you want to:'),
                                                const SizedBox(height: 4),
                                                const Text('• Replace the connection (old song will lose this NFC connection)'),
                                                const Text('• Keep the existing connection'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Keep Existing'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Replace Connection'),
                                              ),
                                            ],
                                          );
                                        },
                                      ) ?? false;
                                    }
                                    
                                    if (shouldUseNewNfc) {
                                      final currentNfcUuid = nfcService.currentNfcUuid;
                                      if (currentNfcUuid != null) {
                                        // Remove NFC connection from ALL songs that have this NFC UUID
                                        final songsWithThisNfc = songProvider.songs
                                            .where((s) => s.connectedNfcUuid == currentNfcUuid && s.id != song.id)
                                            .toList();
                                        
                                        for (final songWithNfc in songsWithThisNfc) {
                                          final updatedSong = Song(
                                            id: songWithNfc.id,
                                            title: songWithNfc.title,
                                            filePath: songWithNfc.filePath,
                                            connectedNfcUuid: null, // Remove NFC connection
                                          );
                                          songProvider.updateSong(updatedSong);
                                        }
                                      }
                                      
                                      setState(() {
                                        dialogNfcUuid = nfcService.currentNfcUuid;
                                      });
                                    }
                                  },
                                  child: const Text('Use This NFC'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Show scanning status
                        if (nfcService.currentNfcUuid == null || nfcService.currentNfcUuid == dialogNfcUuid)
                          dialogNfcUuid != null
                            ? const Text('NFC is assigned and ready')
                            : nfcService.isScanning
                              ? const Text(
                                  'Scanning for NFC tags...',
                                  style: TextStyle(color: Colors.blue),
                                )
                              : const Text(
                                  'Waiting for NFC tag...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogState.isOpen = false;
                  nfcService.removeListener(updateNfcUuid);
                  nfcService.setEditMode(false); // Disable edit mode
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && filePathController.text.isNotEmpty) {
                    // Update song details
                    final updatedSong = Song(
                      id: song.id,
                      title: titleController.text,
                      filePath: filePathController.text,
                      connectedNfcUuid: dialogNfcUuid,
                    );
                    
                    songProvider.updateSong(updatedSong);

                    // Update NFC mapping if needed
                    if (dialogNfcUuid != song.connectedNfcUuid) {
                      // Remove old mapping if it existed
                      if (song.connectedNfcUuid != null) {
                        mappingProvider.removeMapping(song.connectedNfcUuid!);
                      }
                      
                      // Add new mapping if NFC UUID is set
                      if (dialogNfcUuid != null) {
                        mappingProvider.addMapping(
                          NFCMusicMapping(
                            nfcUuid: dialogNfcUuid!,
                            songId: song.id,
                          ),
                        );
                      }
                    }

                    dialogState.isOpen = false;
                    nfcService.removeListener(updateNfcUuid);
                    nfcService.setEditMode(false); // Disable edit mode
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    // Start NFC scanning automatically when dialog opens (if not already scanning)
    if (nfcService.isNfcAvailable && !nfcService.isScanning) {
      nfcService.startNfcSession();
    }
  }

  void _showDeleteSongDialog(BuildContext context, Song song, SongProvider songProvider) {
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to delete this song?'),
            const SizedBox(height: 8),
            Text('Title: ${song.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (song.connectedNfcUuid != null) ...[
              const SizedBox(height: 8),
              Text(
                'This will also remove the NFC mapping for: ${song.connectedNfcUuid}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove NFC mapping if it exists
              if (song.connectedNfcUuid != null) {
                mappingProvider.removeMapping(song.connectedNfcUuid!);
              }
              
              // Delete the song
              songProvider.removeSong(song.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStorageDebugDialog(BuildContext context) {
    final storageService = StorageService.instance;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗄️ Storage Debug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Storage Service Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Initialized: ${storageService.isInitialized}'),
              Text('• Platform: ${Platform.operatingSystem}'),
              const SizedBox(height: 16),
              
              const Text('Storage Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...storageService.getStorageStats().entries.map(
                (entry) => Text('• ${entry.key}: ${entry.value}')
              ),
              const SizedBox(height: 16),
              
              const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      storageService.debugStorageStatus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Storage debug info logged to console')),
                      );
                    },
                    child: const Text('Log Debug Info'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await storageService.forceReinitialize();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Storage reinitialized'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reinitialization failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Force Reinitialize'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await storageService.clearAllData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All storage data cleared'), backgroundColor: Colors.orange),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Clear failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Clear All Data'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final musicPlayer = Provider.of<MusicPlayer>(context, listen: false);
    final songProvider = Provider.of<SongProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NFC Service Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• NFC Available: ${nfcService.isNfcAvailable}'),
              Text('• NFC Scanning: ${nfcService.isScanning}'),
              Text('• Current UUID: ${nfcService.currentNfcUuid ?? "None"}'),
              const SizedBox(height: 16),
              
              const Text('Music Player Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Current State: ${musicPlayer.currentState}'),
              Text('• Is Playing: ${musicPlayer.isPlaying}'),
              Text('• Is Paused: ${musicPlayer.isPaused}'),
              Text('• Current File: ${musicPlayer.currentMusicFilePath ?? "None"}'),
              Text('• Position: ${musicPlayer.savedPosition}'),
              const SizedBox(height: 16),
              
              const Text('Songs & Mappings:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Total Songs: ${songProvider.songs.length}'),
              for (int i = 0; i < songProvider.songs.length; i++)
                Text('• Song $i: ${songProvider.songs[i].title} (UUID: ${songProvider.songs[i].connectedNfcUuid ?? "None"})'),
              const SizedBox(height: 16),
              
              const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final debugInfo = nfcService.getDebugInfo();
                      debugPrint('📊 NFC Debug Info: $debugInfo');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debug info logged to console')),
                      );
                    },
                    child: const Text('Log Debug Info'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      musicPlayer.simulateStateTest();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('State test logged to console')),
                      );
                    },
                    child: const Text('Test Player State'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        if (nfcService.isScanning) {
                          await nfcService.stopNfcSession();
                        } else {
                          await nfcService.startNfcSession();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(nfcService.isScanning ? 'NFC scanning started' : 'NFC scanning stopped')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('NFC operation failed: $e')),
                        );
                      }
                    },
                    child: Text(nfcService.isScanning ? 'Stop NFC' : 'Start NFC'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      nfcService.forceProcessCurrentUuid();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Force processed current UUID')),
                      );
                    },
                    child: const Text('Force Process UUID'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}

class _DialogState {
  bool isOpen = true;
}
