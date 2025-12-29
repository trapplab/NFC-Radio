import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'nfc_music_mapping.dart';
import 'nfc_service.dart';
import 'music_player.dart';
import 'song.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NFCMusicMappingProvider()),
        ChangeNotifierProvider(create: (_) => NFCService()),
        ChangeNotifierProvider(create: (_) => MusicPlayer()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Radio',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NFCJukeboxHomePage(),
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
      ),
      body: Column(
        children: [
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
                      IconButton(
                        icon: Icon(
                          musicPlayer.isSongPlaying(song.filePath)
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 24,
                          color: Colors.blue,
                        ),
                        onPressed: () async {
                          if (musicPlayer.isSongPlaying(song.filePath)) {
                            await musicPlayer.pauseMusic();
                          } else {
                            await musicPlayer.playMusic(song.filePath);
                          }
                        },
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!nfcService.isNfcAvailable) ...[
                    const Text('NFC is not available on this device.'),
                  ] else ...[
                    const Text('Ready to scan NFC tags'),
                    const SizedBox(height: 20),
                    if (musicPlayer.isPlaying) ...[
                      Text('Now Playing: ${musicPlayer.currentMusicFilePath}'),
                      ElevatedButton(
                        onPressed: musicPlayer.pauseMusic,
                        child: const Text('Pause'),
                      ),
                      ElevatedButton(
                        onPressed: musicPlayer.stopMusic,
                        child: const Text('Stop'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageMappingsPage()),
          );
        },
        tooltip: 'Manage Mappings',
        child: const Icon(Icons.settings),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context, SongProvider songProvider) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController filePathController = TextEditingController();
    String? nfcUuid;
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);

    // Listen for NFC tag changes
    void updateNfcUuid() {
      if (nfcService.currentNfcUuid != null) {
        nfcUuid = nfcService.currentNfcUuid;
      }
    }
    nfcService.addListener(updateNfcUuid);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Listen to NFC service changes
          final nfcService = Provider.of<NFCService>(context);
          
          // Update local nfcUuid when service notifies of changes
          if (nfcService.currentNfcUuid != null) {
            nfcUuid = nfcService.currentNfcUuid;
          }

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
                            filePathController.text = file.path!;
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (nfcService.isNfcAvailable) ...[
                  const Text('Scan NFC Tag (Automatic)'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: nfcUuid != null
                      ? Text(
                          'NFC UUID: $nfcUuid',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (filePathController.text.isNotEmpty) {
                    // Use provided title or auto-generate from filename
                    String finalTitle = titleController.text.isNotEmpty
                      ? titleController.text
                      : basenameWithoutExtension(filePathController.text);
                    
                    final song = Song(
                      id: const Uuid().v4(),
                      title: finalTitle,
                      filePath: filePathController.text,
                    );
                    
                    songProvider.addSong(song);
                    
                    // If an NFC tag was scanned, create a mapping
                    if (nfcUuid != null) {
                      mappingProvider.addMapping(
                        NFCMusicMapping(
                          nfcUuid: nfcUuid!,
                          songId: song.id,
                        ),
                      );
                    }
                    
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Clean up listener and stop NFC session when dialog is closed
      nfcService.removeListener(updateNfcUuid);
      nfcService.stopNfcSession();
    });

    // Start NFC scanning automatically when dialog opens
    if (nfcService.isNfcAvailable) {
      nfcService.startNfcSession();
    }
  }

}

class ManageMappingsPage extends StatefulWidget {
  const ManageMappingsPage({super.key});

  @override
  State<ManageMappingsPage> createState() => _ManageMappingsPageState();
}

class _ManageMappingsPageState extends State<ManageMappingsPage> {
  final TextEditingController _nfcUuidController = TextEditingController();
  final TextEditingController _songIdController = TextEditingController();

  @override
  void dispose() {
    _nfcUuidController.dispose();
    _songIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Mappings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nfcUuidController,
              decoration: const InputDecoration(labelText: 'NFC UUID'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _songIdController.text.isNotEmpty ? _songIdController.text : null,
              items: songProvider.songs.map((song) => DropdownMenuItem<String>(
                value: song.id,
                child: Text('${song.title} (${song.id})'),
              )).toList(),
              onChanged: (value) {
                _songIdController.text = value ?? '';
              },
              decoration: const InputDecoration(labelText: 'Song'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nfcUuidController.text.isNotEmpty && _songIdController.text.isNotEmpty) {
                  mappingProvider.addMapping(
                    NFCMusicMapping(
                      nfcUuid: _nfcUuidController.text,
                      songId: _songIdController.text,
                    ),
                  );
                  _nfcUuidController.clear();
                  _songIdController.clear();
                }
              },
              child: const Text('Add Mapping'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: mappingProvider.mappings.length,
                itemBuilder: (context, index) {
                  final mapping = mappingProvider.mappings[index];
                  final song = songProvider.songs.firstWhere(
                    (song) => song.id == mapping.songId,
                    orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
                  );
                  return ListTile(
                    title: Text(mapping.nfcUuid),
                    subtitle: Text(song.title.isNotEmpty ? song.title : 'Unknown Song'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        mappingProvider.removeMapping(mapping.nfcUuid);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
