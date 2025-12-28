import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'nfc_music_mapping.dart';
import 'nfc_service.dart';
import 'music_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NFCMusicMappingProvider()),
        ChangeNotifierProvider(create: (_) => NFCService()),
        ChangeNotifierProvider(create: (_) => MusicPlayer()),
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
      title: 'NFC Jukebox',
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
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NFC Jukebox'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            if (!nfcService.isNfcAvailable) ...[
              const Text('NFC is not available on this device.'),
            ] else ...[
              ElevatedButton(
                onPressed: () async {
                  await nfcService.startNfcSession();
                  if (nfcService.currentNfcUuid != null) {
                    final musicFilePath = mappingProvider.getMusicFilePath(nfcService.currentNfcUuid!);
                    if (musicFilePath != null) {
                      await musicPlayer.playMusic(musicFilePath);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No music file mapped to this NFC tag.')),
                      );
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
