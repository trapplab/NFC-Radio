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
                )).toList(),
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
                    ElevatedButton(
                      onPressed: () async {
                        await nfcService.startNfcSession();
                        if (nfcService.currentNfcUuid != null) {
                          // Check if this NFC tag is already connected to a song
                          final connectedSong = songProvider.songs.firstWhere(
                            (song) => song.connectedNfcUuid == nfcService.currentNfcUuid,
                            orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
                          );
                          
                          if (connectedSong.id.isNotEmpty) {
                            // Play the connected song
                            await musicPlayer.playMusic(connectedSong.filePath);
                          } else {
                            // Show dialog to connect this NFC tag to a song
                            _showConnectNfcDialog(context, nfcService.currentNfcUuid!, songProvider);
                          }
                        }
                      },
                      child: const Text('Scan NFC Tag'),
                    ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    
                    if (result != null && result.files.single.path != null) {
                      filePathController.text = result.files.single.path!;
                    }
                  },
                ),
              ],
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
              if (filePathController.text.isNotEmpty) {
                // Use provided title or auto-generate from filename
                String finalTitle = titleController.text.isNotEmpty
                  ? titleController.text
                  : basenameWithoutExtension(filePathController.text);
                
                songProvider.addSong(
                  Song(
                    id: const Uuid().v4(),
                    title: finalTitle,
                    filePath: filePathController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showConnectNfcDialog(BuildContext context, String nfcUuid, SongProvider songProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect NFC Tag to Song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a song to connect to this NFC tag:'),
            const SizedBox(height: 16),
            ...songProvider.songs.map((song) => ListTile(
              title: Text(song.title),
              subtitle: Text(song.filePath),
              trailing: song.connectedNfcUuid != null
                  ? const Icon(Icons.link, color: Colors.green)
                  : null,
              onTap: () {
                // Disconnect from previous song if any
                if (song.connectedNfcUuid != null) {
                  songProvider.disconnectSongFromNfc(song.id);
                }
                songProvider.connectSongToNfc(song.id, nfcUuid);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connected ${song.title} to NFC tag')),
                );
              },
            )).toList(),
            if (songProvider.songs.isEmpty) ...[
              const Text('No songs available. Add a song first.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class ManageMappingsPage extends StatefulWidget {
  const ManageMappingsPage({super.key});

  @override
  State<ManageMappingsPage> createState() => _ManageMappingsPageState();
}

class _ManageMappingsPageState extends State<ManageMappingsPage> {
  final TextEditingController _nfcUuidController = TextEditingController();
  final TextEditingController _musicFilePathController = TextEditingController();

  @override
  void dispose() {
    _nfcUuidController.dispose();
    _musicFilePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context);

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
            TextField(
              controller: _musicFilePathController,
              decoration: const InputDecoration(labelText: 'Music File Path'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nfcUuidController.text.isNotEmpty && _musicFilePathController.text.isNotEmpty) {
                  mappingProvider.addMapping(
                    NFCMusicMapping(
                      nfcUuid: _nfcUuidController.text,
                      musicFilePath: _musicFilePathController.text,
                    ),
                  );
                  _nfcUuidController.clear();
                  _musicFilePathController.clear();
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
                  return ListTile(
                    title: Text(mapping.nfcUuid),
                    subtitle: Text(mapping.musicFilePath),
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
