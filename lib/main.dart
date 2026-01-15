import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'nfc_music_mapping.dart';
import 'nfc_service.dart';
import 'music_player.dart';
import 'song.dart';
import 'folder.dart';
import 'storage_service.dart';
import 'dimmed_mode_service.dart';
import 'dimmed_mode_wrapper.dart';
import 'update_service.dart';
import 'config.dart';
import 'iap_service.dart';
import 'services/audio_intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  
  // Initialize audio intent service
  AudioIntentService().initialize();
  
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
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayer()),
        ChangeNotifierProvider(create: (_) => DimmedModeService()),
        ChangeNotifierProvider(create: (_) => NFCService()),
        ChangeNotifierProvider.value(value: IAPService.instance),
      ],
      child: MaterialApp(
        title: 'NFC Radio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: DimmedModeWrapper(child: const NFCJukeboxHomePage()),
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
  StreamSubscription<String>? _nfcMessageSubscription;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Get app version
    _getAppVersion();

    // Initialize IAP service for Google Play flavor
    // For other flavors, this sets isPremium=true (unlimited access)
    if (AppConfig.isGooglePlayRelease) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await IAPService.instance.initialize();
        }
      });
    }

    // Automatic update check on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(manual: false);
    });
    
    debugPrint('🚀 ===== APP INITIALIZATION STARTED =====');
    debugPrint('🚀 Timestamp: ${DateTime.now()}');
    
    debugPrint('🚀 ===== APP INITIALIZATION COMPLETED =====');
  }
  
  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error getting app version: $e');
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }
  
  Future<void> _checkForUpdates({bool manual = true}) async {
    if (!AppConfig.isGitHubRelease) {
      return;
    }
    
    try {
      await UpdateService.checkGithubUpdate(context, 'trapplab', 'NFC-Radio', manual: manual);
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update check failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get display name from file path or URI
  String _getDisplayName(String? path) {
    if (path == null || path.isEmpty) return 'Unknown';
    String name;
    if (path.startsWith('content://')) {
      final uri = Uri.parse(path);
      name = uri.pathSegments.lastOrNull ?? 'Unknown';
    } else {
      name = path.split('/').last;
    }

    // Strip timestamp prefix (e.g., 1736590000000_filename.mp3)
    final regex = RegExp(r'^\d{13}_');
    if (regex.hasMatch(name)) {
      name = name.replaceFirst(regex, '');
    }

    // Strip extension
    name = name.replaceAll(RegExp(r'\.[^.]+$'), '');

    return name;
  }

  /// Check if we're running in a test environment
  bool _isTestEnvironment() {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
           Platform.environment.containsKey('DART_VM_OPTIONS');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to NFC service messages
    _nfcMessageSubscription?.cancel();
    final nfcService = Provider.of<NFCService>(context, listen: false);
    _nfcMessageSubscription = nfcService.messages.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Initialize providers after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
  
      try {
        final songProvider = Provider.of<SongProvider>(context, listen: false);
        final folderProvider = Provider.of<FolderProvider>(context, listen: false);
        final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);
        final musicPlayer = Provider.of<MusicPlayer>(context, listen: false);
        final nfcService = Provider.of<NFCService>(context, listen: false);
  
        if (!songProvider.isInitialized || !folderProvider.isInitialized) {
          debugPrint('🔄 Initializing providers with persisted data...');
  
          // Initialize providers in parallel
          await Future.wait([
            songProvider.initialize(),
            folderProvider.initialize(),
            mappingProvider.initialize(),
          ]);

          // Set providers for NFCService after initialization
          nfcService.setProviders(
            mappingProvider: mappingProvider,
            songProvider: songProvider,
            folderProvider: folderProvider,
            musicPlayer: musicPlayer,
          );
  
          debugPrint('✅ All providers initialized successfully');
          debugPrint('📊 Songs loaded: ${songProvider.songs.length}');
          debugPrint('📊 Folders loaded: ${folderProvider.folders.length}');
          debugPrint('📊 Mappings loaded: ${mappingProvider.mappings.length}');
  
          // Show success message if we loaded existing data
          if (mounted && (songProvider.songs.isNotEmpty || folderProvider.folders.isNotEmpty || mappingProvider.mappings.isNotEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎵 Loaded your saved songs, folders, and NFC mappings!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (mounted) {
            debugPrint('ℹ️ No existing data found. A default folder should have been created.');
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
    _nfcMessageSubscription?.cancel();
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
    final iapService = Provider.of<IAPService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NFC Radio'),
        actions: [
          // App version display (visible in all flavors, clickable for GitHub flavor)
          GestureDetector(
            onTap: AppConfig.isGitHubRelease ? _checkForUpdates : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppConfig.isGitHubRelease ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConfig.isGitHubRelease ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Upgrade info button (only for GP flavor when not premium)
          if (AppConfig.isGooglePlayRelease && !iapService.isPremium)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _showUpgradeDialog(context),
              tooltip: 'Upgrade to Premium',
            ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 150),
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
                
                // Vertical ListView for folders
                Consumer<FolderProvider>(
                  builder: (context, folderProvider, child) {
                    return Column(
                      children: [
                        // Folders list or empty state message
                        if (folderProvider.folders.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No folders yet. Create a folder to organize your songs!',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                          // Add button when no folders exist
                          _buildAddFolderButton(context, folderProvider),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: folderProvider.folders.length + 1, // +1 for the add button
                            itemBuilder: (context, index) {
                              if (index < folderProvider.folders.length) {
                                final folder = folderProvider.folders[index];
                                return _buildFolderWidget(context, folder, folderProvider, songProvider, musicPlayer);
                              } else {
                                // Last item is the "Add New Folder" button
                                return _buildAddFolderButton(context, folderProvider);
                              }
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Music Player Section - Absolutely positioned at the bottom
          // Audio player should only be visible when not in "Add New Song" or "Edit Song" mode
          // Since nfcService.setEditMode is true when in those dialogs, we can use that flag
          if ((musicPlayer.isPlaying || musicPlayer.isPaused) && !nfcService.isInEditMode)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Now Playing: ${musicPlayer.currentSongTitle ?? _getDisplayName(musicPlayer.currentMusicFilePath)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (musicPlayer.totalDuration > Duration.zero)
                      Text(
                        'Position: ${musicPlayer.getCurrentPositionString()} / ${musicPlayer.getTotalDurationString()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: musicPlayer.togglePlayPause,
                          icon: Icon(musicPlayer.isPlaying ? Icons.pause : Icons.play_arrow),
                          tooltip: musicPlayer.isPlaying ? 'Pause' : 'Play',
                        ),
                        IconButton(
                          onPressed: musicPlayer.stopMusic,
                          icon: const Icon(Icons.stop),
                          tooltip: 'Stop',
                        ),
                        if (musicPlayer.totalDuration > Duration.zero)
                          Expanded(
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
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddFolderButton(BuildContext context, FolderProvider folderProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          if (folderProvider.isFolderLimitReached()) {
            folderProvider.showFolderLimitDialog(context);
          } else {
            _showAddFolderDialog(context, folderProvider);
          }
        },
        icon: const Icon(Icons.create_new_folder),
        label: const Text('Add New Folder'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildAddSongButton(BuildContext context, SongProvider songProvider, {String? folderId}) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (folderId != null && folderProvider.isSongLimitReached(folderId)) {
            folderProvider.showSongLimitDialog(context);
          } else {
            _showSongDialog(context, songProvider, folderId: folderId);
          }
        },
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
    );
  }

  void _showAddFolderDialog(BuildContext context, FolderProvider folderProvider) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Folder Name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final folder = Folder(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  songIds: [],
                  isExpanded: false,
                );
                folderProvider.addFolder(folder);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSongDialog(BuildContext context, SongProvider songProvider, {Song? song, String? folderId}) {
    final bool isEditing = song != null;
    final TextEditingController titleController = TextEditingController(text: song?.title ?? '');
    final TextEditingController filePathController = TextEditingController(text: song?.filePath ?? '');
    String? dialogNfcUuid = song?.connectedNfcUuid;
    
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);

    // Identify the current folder
    String? currentFolderId = folderId;
    if (currentFolderId == null && song != null) {
      try {
        currentFolderId = folderProvider.folders.firstWhere((f) => f.songIds.contains(song.id)).id;
      } catch (_) {}
    }
    if (currentFolderId == null) {
      // Fallback to expanded folder or first folder
      try {
        currentFolderId = folderProvider.folders.firstWhere((f) => f.isExpanded).id;
      } catch (_) {
        if (folderProvider.folders.isNotEmpty) {
          currentFolderId = folderProvider.folders.first.id;
        }
      }
    }

    // Create a stateful wrapper to track dialog state
    final dialogState = _DialogState();
    
    // Enable edit mode to pause player triggering during editing
    nfcService.setEditMode(true);
    
    // Store the listener function so we can remove it later
    late void Function() updateNfcUuid;
    StreamSubscription? audioSubscription;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Define the listener function
          updateNfcUuid = () {
            if (!dialogState.isOpen) {
              nfcService.removeListener(updateNfcUuid);
              nfcService.setEditMode(false);
              return;
            }
            
            final currentNfcUuid = nfcService.currentNfcUuid;
            if (currentNfcUuid != null && currentNfcUuid != dialogNfcUuid) {
              // Check if this NFC is already linked in the same folder
              Song? existingSong;
              try {
                if (currentFolderId != null) {
                  final currentFolder = folderProvider.folders.firstWhere((f) => f.id == currentFolderId);
                  existingSong = songProvider.songs.firstWhere(
                    (s) => s.connectedNfcUuid == currentNfcUuid &&
                           currentFolder.songIds.contains(s.id) &&
                           (song == null || s.id != song.id),
                  );
                }
              } catch (_) {
                existingSong = null;
              }

              if (existingSong == null) {
                // Automatically link if not already linked to another song in this folder
                setState(() {
                  dialogNfcUuid = currentNfcUuid;
                });
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('🔗 NFC tag linked automatically'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                // Just trigger rebuild to show the "Use This NFC" button for manual resolution
                setState(() {});
              }
            }
          };
          
          nfcService.addListener(updateNfcUuid);

          // Listen for audio picked from external apps
          audioSubscription ??= AudioIntentService().onAudioPicked.listen((audioFile) {
            if (dialogState.isOpen) {
              setState(() {
                if (audioFile.sourceUri.isScheme('file')) {
                  filePathController.text = audioFile.sourceUri.toFilePath();
                } else {
                  filePathController.text = audioFile.sourceUri.toString();
                }
                
                if (titleController.text.isEmpty && audioFile.displayName != null) {
                  titleController.text = audioFile.displayName!.replaceAll(RegExp(r'\.[^.]+$'), '');
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('📥 Audio selected: ${audioFile.displayName ?? "Unknown"}')),
              );
            }
          });

          return AlertDialog(
            title: Text(isEditing ? 'Edit Song' : 'Add New Song'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: filePathController,
                          decoration: const InputDecoration(labelText: 'Audio Source'),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final success = await AudioIntentService().pickAudioFromApp();
                          if (!success && dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('❌ Failed to launch audio picker')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Song Title'),
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
                          if (dialogNfcUuid != null) ...[
                            Text(
                              'Assigned NFC: ${dialogNfcUuid!.substring(0, 8)}...',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          if (nfcService.currentNfcUuid != null && nfcService.currentNfcUuid != dialogNfcUuid) ...[
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
                                      final currentNfcUuid = nfcService.currentNfcUuid;
                                      if (currentNfcUuid == null) return;
                                      
                                      Song? existingSong;
                                      try {
                                        // Only check for existing connection within the same folder
                                        if (currentFolderId != null) {
                                          final currentFolder = folderProvider.folders.firstWhere((f) => f.id == currentFolderId);
                                          existingSong = songProvider.songs.firstWhere(
                                            (s) => s.connectedNfcUuid == currentNfcUuid &&
                                                   currentFolder.songIds.contains(s.id) &&
                                                   (song == null || s.id != song.id),
                                          );
                                        }
                                      } catch (_) {
                                        existingSong = null;
                                      }
                                      
                                      bool shouldUseNewNfc = true;
                                      if (existingSong != null) {
                                        if (!dialogContext.mounted) return;
                                        shouldUseNewNfc = await showDialog<bool>(
                                          context: dialogContext,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('NFC Tag Already Connected'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('This NFC tag is already connected to:'),
                                                  const SizedBox(height: 8),
                                                  Text('"${existingSong!.title}"', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  const Text('Do you want to replace the connection?'),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Existing')),
                                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Replace Connection')),
                                              ],
                                            );
                                          },
                                        ) ?? false;
                                      }
                                      
                                      if (shouldUseNewNfc) {
                                        // Only remove mapping from songs in the same folder
                                        if (currentFolderId != null) {
                                          final currentFolder = folderProvider.folders.firstWhere((f) => f.id == currentFolderId);
                                          final songsWithThisNfcInFolder = songProvider.songs
                                              .where((s) => s.connectedNfcUuid == currentNfcUuid &&
                                                            currentFolder.songIds.contains(s.id) &&
                                                            (song == null || s.id != song.id))
                                              .toList();
                                          for (final s in songsWithThisNfcInFolder) {
                                            songProvider.updateSong(Song(
                                              id: s.id,
                                              title: s.title,
                                              filePath: s.filePath,
                                              connectedNfcUuid: null,
                                            ));
                                          }
                                        }
                                        setState(() {
                                          dialogNfcUuid = currentNfcUuid;
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
                          
                          if (nfcService.currentNfcUuid == null || nfcService.currentNfcUuid == dialogNfcUuid)
                            dialogNfcUuid != null
                              ? const Text('NFC is assigned and ready')
                              : nfcService.isScanning
                                ? const Text('Scanning for NFC tags...', style: TextStyle(color: Colors.blue))
                                : const Text('Waiting for NFC tag...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogState.isOpen = false;
                  nfcService.removeListener(updateNfcUuid);
                  nfcService.setEditMode(false);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (filePathController.text.isNotEmpty) {
                    final String finalTitle = titleController.text.isNotEmpty
                        ? titleController.text
                        : _getDisplayName(filePathController.text);

                    final newSong = Song(
                      id: song?.id ?? const Uuid().v4(),
                      title: finalTitle,
                      filePath: filePathController.text,
                      connectedNfcUuid: dialogNfcUuid,
                    );

                    if (isEditing) {
                      songProvider.updateSong(newSong);
                    } else {
                      songProvider.addSong(newSong);
                      
                      // Add to folder if provided
                      if (folderId != null) {
                        folderProvider.addSongToFolder(folderId, newSong.id);
                      }
                    }

                    if (dialogNfcUuid != song?.connectedNfcUuid) {
                      if (song != null) {
                        mappingProvider.removeMapping(song.id);
                      }
                      if (dialogNfcUuid != null) {
                        mappingProvider.addMapping(NFCMusicMapping(
                          nfcUuid: dialogNfcUuid!,
                          songId: newSong.id,
                        ));
                      }
                    }

                    dialogState.isOpen = false;
                    nfcService.removeListener(updateNfcUuid);
                    audioSubscription?.cancel();
                    nfcService.setEditMode(false);
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );

    if (nfcService.isNfcAvailable && !nfcService.isScanning) {
      nfcService.startNfcSession();
    }
  }

  Widget _buildFolderWidget(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
    SongProvider songProvider,
    MusicPlayer musicPlayer,
  ) {
    // Get songs in this folder
    final folderSongs = songProvider.songs.where((song) => folder.songIds.contains(song.id)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Folder header
          InkWell(
            onTap: () => folderProvider.toggleFolderExpansion(folder.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: folder.isExpanded ? Colors.blue[50] : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    folder.isExpanded ? Icons.folder_open : Icons.folder,
                    color: Colors.blue[700],
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  Icon(
                    folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditFolderDialog(context, folder, folderProvider);
                      } else if (value == 'delete') {
                        _showDeleteFolderDialog(context, folder, folderProvider);
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
            ),
          ),

          // Folder content (songs)
          if (folder.isExpanded) ...[
            // Horizontal ListView for songs in this folder
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (folderSongs.isEmpty) ...[
                    _buildAddSongButton(context, songProvider, folderId: folder.id),
                  ] else ...[
                    ...folderSongs.map((song) => Container(
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
                                    await musicPlayer.playMusic(song.filePath, songTitle: song.title);
                                  }
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 16),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showSongDialog(context, songProvider, song: song);
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
                    _buildAddSongButton(context, songProvider, folderId: folder.id),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditFolderDialog(BuildContext context, Folder folder, FolderProvider folderProvider) {
    final TextEditingController nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Folder Name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedFolder = Folder(
                  id: folder.id,
                  name: nameController.text,
                  songIds: folder.songIds,
                  isExpanded: folder.isExpanded,
                );
                folderProvider.updateFolder(updatedFolder);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, Folder folder, FolderProvider folderProvider) {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to delete this folder?'),
            const SizedBox(height: 8),
            Text('Name: ${folder.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Songs in folder: ${folder.songIds.length}'),
            if (folder.songIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Note: All songs in this folder and their audio files will also be deleted.',
                style: TextStyle(fontSize: 12, color: Colors.red),
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
            onPressed: () async {
              // Delete all songs in the folder
              for (final songId in folder.songIds) {
                try {
                  final song = songProvider.songs.firstWhere((s) => s.id == songId);
                  
                  // Remove NFC mapping
                  mappingProvider.removeMapping(song.id);
                  
                  // Delete physical file
                  if (song.filePath.isNotEmpty) {
                    final file = File(song.filePath);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  }
                  
                  // Remove from song provider
                  songProvider.removeSong(song.id);
                } catch (e) {
                  debugPrint('⚠️ Error deleting song $songId during folder deletion: $e');
                }
              }

              // Finally remove the folder
              folderProvider.removeFolder(folder.id);
              Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 8),
            const Text(
              'The audio file will also be deleted from the app storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Remove NFC mapping if it exists
              mappingProvider.removeMapping(song.id);
              
              // Delete the physical file if it's in the app's audio directory
              final filePath = song.filePath;
              if (filePath.isNotEmpty) {
                try {
                  final file = File(filePath);
                  if (await file.exists()) {
                    await file.delete();
                    debugPrint('🗑️ Deleted audio file: $filePath');
                  }
                } catch (e) {
                  debugPrint('⚠️ Failed to delete audio file: $e');
                }
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

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'In the free version you can add up to 2 folders with 6 audio files each.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium to unlock unlimited folders and audio files, and support the developers!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await IAPService.instance.buyPremium();
            },
            child: const Text('Upgrade'),
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
              
              const Text('IAP/Premium Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (AppConfig.isGooglePlayRelease) ...[
                Text('• Premium: ${IAPService.instance.isPremium}'),
              ] else ...[
                const Text('• Premium: N/A (non-GP flavor)'),
              ],
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
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await storageService.forceReinitialize();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Storage reinitialized'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Reinitialization failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Force Reinitialize'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await storageService.clearAllData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('All storage data cleared'), backgroundColor: Colors.orange),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Clear failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Clear All Data'),
                  ),
                  if (AppConfig.isGooglePlayRelease) ...[
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('💾 IAP Premium Status: ${IAPService.instance.isPremium}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Premium status: ${IAPService.instance.isPremium}')),
                        );
                      },
                      child: const Text('Log Premium Status'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final box = await Hive.openBox('premium_status');
                          await box.delete('is_premium');
                          debugPrint('🗑️ Premium status cleared');
                          // Refresh the IAP service to get the new value
                          await IAPService.instance.refreshPremiumStatus();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Premium status cleared'), backgroundColor: Colors.orange),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Clear failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Clear Premium Status'),
                    ),
                  ],
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
              
              const Text('Flavor Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• GitHub Release: ${AppConfig.isGitHubRelease}'),
              Text('• F-Droid Release: ${AppConfig.isFdroidRelease}'),
              Text('• Google Play Release: ${AppConfig.isGooglePlayRelease}'),
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
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        if (nfcService.isScanning) {
                          await nfcService.stopNfcSession();
                        } else {
                          await nfcService.startNfcSession();
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(nfcService.isScanning ? 'NFC scanning started' : 'NFC scanning stopped')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('NFC operation failed: $e')),
                          );
                        }
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
