import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'nfc/nfc_music_mapping.dart';
import 'nfc/nfc_service.dart';
import 'audio/music_player.dart';
import 'storage/song.dart';
import 'storage/folder.dart';
import 'storage/storage_service.dart';
import 'lockscreen/dimmed_mode_service.dart';
import 'lockscreen/dimmed_mode_wrapper.dart';
import 'config/update_service.dart';
import 'config/config.dart';
import 'iap/iap_service.dart';
import 'services/audio_intent_service.dart';
import 'services/github_audio_service.dart';
import 'models/github_audio_folder.dart';
import 'config/settings_provider.dart';
import 'config/theme_provider.dart';
import 'config/color_chooser.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'tutorial/tutorial_service.dart';
import 'tutorial/tutorial_steps.dart';
import 'l10n/app_localizations.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'NFC Radio',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.currentColor,
                brightness: themeProvider.currentColor == Colors.black
                    ? Brightness.dark
                    : Brightness.light,
              ),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            home: DimmedModeWrapper(child: const NFCJukeboxHomePage()),
          );
        },
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
  List<GitHubAudioFolder>? _githubFolders;
  bool _isLoadingGithubFolders = false;
  bool _initializationStarted = false;

  // Global keys for tutorial
  final GlobalKey _addFolderButtonKey = GlobalKey();
  final GlobalKey _addSongButtonKey = GlobalKey();
  final GlobalKey _attachFileButtonKey = GlobalKey();
  final GlobalKey _nfcAreaKey = GlobalKey();
  final GlobalKey _settingsMenuKey = GlobalKey();

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
      _fetchGithubFolders();
    });
    
    // Initialize tutorial service and show tutorial if needed
    _initializeTutorial();
    
    debugPrint('🚀 ===== APP INITIALIZATION STARTED =====');
    debugPrint('🚀 Timestamp: ${DateTime.now()}');
    
    debugPrint('🚀 ===== APP INITIALIZATION COMPLETED =====');
  }

  Future<void> _fetchGithubFolders() async {
    if (_isLoadingGithubFolders) return;
    setState(() {
      _isLoadingGithubFolders = true;
    });
    try {
      final folders = await GitHubAudioService.fetchFolders();
      if (mounted) {
        setState(() {
          _githubFolders = folders;
          _isLoadingGithubFolders = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching GitHub folders: $e');
      if (mounted) {
        setState(() {
          _isLoadingGithubFolders = false;
        });
      }
    }
  }

  void _showImportConfirmation(BuildContext context, GitHubAudioFolder githubFolder) {
    final locale = Localizations.localeOf(context).toString();
    final localization = githubFolder.getLocalization(locale);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import "${localization?.title ?? githubFolder.folderName}"?'),
        content: Text('This will download ${localization?.files.length ?? 0} audio files and create a new folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importGithubFolder(githubFolder);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importGithubFolder(GitHubAudioFolder githubFolder) async {
    final locale = Localizations.localeOf(context).toString();
    final localization = githubFolder.getLocalization(locale);
    if (localization == null) return;

    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final songProvider = Provider.of<SongProvider>(context, listen: false);

    if (folderProvider.isFolderLimitReached()) {
      folderProvider.showFolderLimitDialog(context);
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading audio files...'),
          ],
        ),
      ),
    );

    try {
      final List<String> songIds = [];
      final List<String> failedFiles = [];

      for (final githubFile in localization.files) {
        try {
          final localPath = await GitHubAudioService.downloadAudioFile(githubFolder.folderName, githubFile.name);
          
          final song = Song(
            id: const Uuid().v4(),
            title: githubFile.title,
            filePath: localPath,
          );
          songProvider.addSong(song);
          songIds.add(song.id);
        } catch (e) {
          debugPrint('⚠️ Failed to download ${githubFile.name}: $e');
          failedFiles.add(githubFile.title);
        }
      }

      if (songIds.isNotEmpty) {
        final folder = Folder(
          id: const Uuid().v4(),
          name: localization.title,
          songIds: songIds,
          isExpanded: true,
        );
        folderProvider.addFolder(folder);
        _initializeTutorial();

        // Show settings tutorial after import if it's the first time
        if (TutorialService.instance.shouldShowSettingsTutorial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final targets = createTutorialTargets(
              context: context,
              settingsMenuKey: _settingsMenuKey,
            );
            if (targets.isNotEmpty) {
              showTutorial(
                context: context,
                targets: targets,
                onFinish: () => TutorialService.instance.markSettingsTutorialShown(),
                onSkip: () => TutorialService.instance.markSettingsTutorialShown(),
              );
            }
          });
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        if (failedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported "${localization.title}"')),
          );
        } else if (songIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import any files from "${localization.title}"'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Partial Import'),
              content: Text('Imported ${songIds.length} files, but ${failedFiles.length} files failed to download:\n\n${failedFiles.join(', ')}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import folder: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      if (!mounted) return;
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
    if (!_initializationStarted) {
      _initializationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
    
        try {
          final songProvider = Provider.of<SongProvider>(context, listen: false);
          final folderProvider = Provider.of<FolderProvider>(context, listen: false);
          final mappingProvider = Provider.of<NFCMusicMappingProvider>(context, listen: false);
          final musicPlayer = Provider.of<MusicPlayer>(context, listen: false);
          final nfcService = Provider.of<NFCService>(context, listen: false);
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

          // Set callback for position changes to persist in song
          musicPlayer.onPositionChangedCallback = (position) {
            if (musicPlayer.currentSong != null) {
              songProvider.updateSongPosition(musicPlayer.currentSong!.id, position.inMilliseconds);
            }
          };
    
          if (!songProvider.isInitialized || !folderProvider.isInitialized || !settingsProvider.isInitialized) {
            debugPrint('🔄 Initializing providers with persisted data...');

            // Ensure StorageService is initialized before initializing providers
            if (!StorageService.instance.isInitialized) {
              debugPrint('⏳ StorageService not ready yet, waiting...');
              await StorageService.instance.initialize();
              debugPrint('✅ StorageService now ready');
            }

            // Initialize providers in parallel
            await Future.wait([
              songProvider.initialize(),
              folderProvider.initialize(),
              mappingProvider.initialize(),
              settingsProvider.initialize(),
            ]);

            // Sync mappings with songs to ensure consistency
            mappingProvider.syncWithSongs(songProvider.songs);

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
      // Save current playback position when app goes to background
      final musicPlayer = Provider.of<MusicPlayer>(context, listen: false);
      musicPlayer.saveCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nfcService = Provider.of<NFCService>(context);
    final musicPlayer = Provider.of<MusicPlayer>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final iapService = Provider.of<IAPService>(context);

    return Scaffold(
      endDrawer: Drawer(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.settingsTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)!.audioPacksTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isLoadingGithubFolders)
                  const Center(child: CircularProgressIndicator())
                else if (_githubFolders == null || _githubFolders!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.couldNotLoadTemplates),
                        TextButton(
                          onPressed: _fetchGithubFolders,
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  )
                else
                  ExpansionTile(
                    title: Text(AppLocalizations.of(context)!.audioStarterPacks),
                    leading: const Icon(Icons.cloud_download),
                    children: _githubFolders!.map((githubFolder) {
                      final locale = Localizations.localeOf(context).toString();
                      final localization = githubFolder.getLocalization(locale);
                      return ListTile(
                        title: Text(localization?.title ?? githubFolder.folderName),
                        subtitle: Text(localization?.description ?? ''),
                        onTap: () => _showImportConfirmation(context, githubFolder),
                      );
                    }).toList(),
                  ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.browseAudioOnly),
                  subtitle: Text(settings.filterAudioOnly 
                    ? AppLocalizations.of(context)!.filterAudio 
                    : AppLocalizations.of(context)!.filterAll),
                  value: settings.filterAudioOnly,
                  onChanged: (value) {
                    settings.setFilterAudioOnly(value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.useKioskMode),
                  subtitle: Text(AppLocalizations.of(context)!.requiresSystemAlertPermission),
                  value: settings.useSystemOverlay,
                  onChanged: (value) {
                    settings.setUseSystemOverlay(value);
                  },
                ),
                const Divider(),
                const ColorChooser(),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.appVersion),
                  subtitle: Text(_appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...'),
                  trailing: AppConfig.isGitHubRelease ? const Icon(Icons.refresh) : null,
                  onTap: AppConfig.isGitHubRelease ? () => _checkForUpdates(manual: true) : null,
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).bannerColor,
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          // Upgrade info button (only for GP flavor when not premium)
          if (AppConfig.isGooglePlayRelease && !iapService.isPremium)
            IconButton(
              icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => _showUpgradeDialog(context),
              tooltip: AppLocalizations.of(context)!.upgradeToPremium,
            ),
          // Debug info button (debug only)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => _showDebugDialog(context),
              tooltip: AppLocalizations.of(context)!.debugInformation,
            ),
          // Storage debug button (debug only)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.storage),
              onPressed: () => _showStorageDebugDialog(context),
              tooltip: AppLocalizations.of(context)!.storageDebug,
            ),
          Builder(
            builder: (context) => IconButton(
              key: _settingsMenuKey,
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: AppLocalizations.of(context)!.settingsTitle,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                          Text(AppLocalizations.of(context)!.nfcNotAvailable),
                        ] else ...[
                          Text(AppLocalizations.of(context)!.readyToScanNfc, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  ? AppLocalizations.of(context)!.scanningForNfc
                                  : AppLocalizations.of(context)!.scanningPaused,
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
                                child: Text(AppLocalizations.of(context)!.startScanning),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: nfcService.isScanning ? () {
                                  nfcService.stopNfcSession();
                                } : null,
                                child: Text(AppLocalizations.of(context)!.stopScanning),
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
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppLocalizations.of(context)!.noFoldersYet,
                                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                            // Add button when no folders exist
                            _buildAddFolderButton(context, folderProvider),
                          ] else ...[
                            ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: folderProvider.folders.length,
                              itemBuilder: (context, index) {
                                final folder = folderProvider.folders[index];
                                return _buildDraggableFolderWidget(context, folder, folderProvider, songProvider, musicPlayer, index);
                              },
                              onReorder: (oldIndex, newIndex) {
                                folderProvider.reorderFolders(oldIndex, newIndex);
                              },
                            ),
                            // Add button at the end (not reorderable)
                            _buildAddFolderButton(context, folderProvider),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Music Player Section - Fixed at the bottom
          // Audio player should only be visible when not in "Add New Song" or "Edit Song" mode
          // Since nfcService.setEditMode is true when in those dialogs, we can use that flag
          if ((musicPlayer.isPlaying || musicPlayer.isPaused) && !nfcService.isInEditMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context).footerColor,
                border: Border.all(color: Provider.of<ThemeProvider>(context).bannerColor),
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
                            onChangeStart: (_) {
                              musicPlayer.setSeeking(true);
                            },
                            onChanged: (value) {
                              musicPlayer.seekTo(Duration(seconds: value.toInt()));
                            },
                            onChangeEnd: (value) {
                              musicPlayer.seekTo(Duration(seconds: value.toInt()), persist: true);
                              musicPlayer.setSeeking(false);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddFolderButton(BuildContext context, FolderProvider folderProvider) {
    return Container(
      key: _addFolderButtonKey,
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
        label: Text(AppLocalizations.of(context)!.addNewFolder),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildAddSongButton(BuildContext context, SongProvider songProvider, {String? folderId}) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final isFirstFolder = folderId != null && folderProvider.folders.isNotEmpty && folderProvider.folders.first.id == folderId;
    
    return Container(
      key: isFirstFolder ? _addSongButtonKey : null,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.addAudioFile,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        title: Text(AppLocalizations.of(context)!.addNewFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.folderName),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final folder = Folder(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  songIds: [],
                  isExpanded: true,
                );
                folderProvider.addFolder(folder);
                Navigator.pop(context);
                _initializeTutorial();
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
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
    bool tutorialTriggered = false;

    // Playback options
    bool isLoopEnabled = song?.isLoopEnabled ?? false;
    bool rememberPosition = song?.rememberPosition ?? false;

    // Enable edit mode to pause player triggering during editing
    nfcService.setEditMode(true);

    // Store the listener function so we can remove it later
    late void Function() updateNfcUuid;
    StreamSubscription? audioSubscription;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Show tutorial if needed (Step 1: Attach File)
          if (!tutorialTriggered && TutorialService.instance.shouldShowSongDialogTutorial) {
            tutorialTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final targets = createTutorialTargets(
              context: dialogContext,
              attachFileButtonKey: _attachFileButtonKey,
            );
              
              if (targets.isNotEmpty) {
                showTutorial(
                  context: dialogContext,
                  targets: targets,
                  onFinish: () {
                    TutorialService.instance.markSongDialogTutorialShown();
                  },
                  onSkip: () {
                    TutorialService.instance.markSongDialogTutorialShown();
                  },
                );
              }
            });
          }

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
          audioSubscription ??= AudioIntentService().onAudioPicked.listen((audioFile) async {
            if (dialogState.isOpen) {
              final path = audioFile.sourceUri.isScheme('file')
                  ? audioFile.sourceUri.toFilePath()
                  : audioFile.sourceUri.toString();
              
              final isValid = await _isValidAudioFile(path);
              if (!isValid) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Rejected: Selected file is not a valid audio file.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                filePathController.text = path;
                
                if (titleController.text.isEmpty && audioFile.displayName != null) {
                  titleController.text = audioFile.displayName!.replaceAll(RegExp(r'\.[^.]+$'), '');
                }
              });
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('📥 Audio selected: ${audioFile.displayName ?? "Unknown"}')),
              );

              // Show tutorial Step 2: NFC Connection
              if (TutorialService.instance.shouldShowNfcConnectionTutorial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final targets = createTutorialTargets(
                    context: dialogContext,
                    nfcAreaKey: _nfcAreaKey,
                  );
                  if (targets.isNotEmpty) {
                    showTutorial(
                      context: dialogContext,
                      targets: targets,
                      onFinish: () => TutorialService.instance.markNfcConnectionTutorialShown(),
                      onSkip: () => TutorialService.instance.markNfcConnectionTutorialShown(),
                    );
                  }
                });
              }
            }
          });

          return AlertDialog(
            title: Text(isEditing ? AppLocalizations.of(context)!.editSong : AppLocalizations.of(context)!.addNewSong),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: filePathController,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.audioSource),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        key: _attachFileButtonKey,
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final settings = Provider.of<SettingsProvider>(context, listen: false);
                          final success = await AudioIntentService().pickAudioFromApp(
                            filterAudioOnly: settings.filterAudioOnly,
                          );
                          if (!success && dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchAudioPicker)),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        tooltip: 'Record Audio',
                        onPressed: () {
                          _openVoiceRecorderApp(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.playbackOptions, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context)!.loopPlayback),
                      const Spacer(),
                      Switch(
                        value: isLoopEnabled,
                        onChanged: (value) {
                          setState(() {
                            isLoopEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.restore),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context)!.rememberPosition),
                      const Spacer(),
                      Switch(
                        value: rememberPosition,
                        onChanged: (value) {
                          setState(() {
                            rememberPosition = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (nfcService.isNfcAvailable) ...[
                    Text(AppLocalizations.of(context)!.nfcConfiguration),
                    const SizedBox(height: 8),
                    Container(
                      key: _nfcAreaKey,
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
                                    AppLocalizations.of(context)!.newNfcDetected(nfcService.currentNfcUuid!.substring(0, 8)),
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
                                              title: Text(AppLocalizations.of(context)!.nfcTagAlreadyConnected),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(AppLocalizations.of(context)!.nfcAlreadyConnectedTo),
                                                  const SizedBox(height: 8),
                                                  Text('"${existingSong!.title}"', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  Text(AppLocalizations.of(context)!.replaceConnectionQuestion),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.keepExisting)),
                                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocalizations.of(context)!.replaceConnection)),
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
                                              isLoopEnabled: s.isLoopEnabled,
                                              rememberPosition: s.rememberPosition,
                                              savedPositionMs: s.savedPositionMs,
                                            ));
                                            mappingProvider.removeMapping(s.id);
                                          }
                                        }
                                        setState(() {
                                          dialogNfcUuid = currentNfcUuid;
                                        });
                                      }
                                    },
                                    child: Text(AppLocalizations.of(context)!.useThisNfc),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          if (nfcService.currentNfcUuid == null || nfcService.currentNfcUuid == dialogNfcUuid)
                            dialogNfcUuid != null
                              ? Text(AppLocalizations.of(context)!.nfcAssignedReady)
                              : nfcService.isScanning
                                ? Text(AppLocalizations.of(context)!.scanningForNfc, style: const TextStyle(color: Colors.blue))
                                : Text(AppLocalizations.of(context)!.waitingForNfc, style: const TextStyle(color: Colors.grey)),
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
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  if (filePathController.text.isNotEmpty) {
                    if (!dialogContext.mounted) return;
                    final isValid = await _isValidAudioFile(filePathController.text);
                    if (!isValid) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.cannotSaveInvalidAudio),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final String finalTitle = titleController.text.isNotEmpty
                        ? titleController.text
                        : _getDisplayName(filePathController.text);

                    final newSong = Song(
                      id: song?.id ?? const Uuid().v4(),
                      title: finalTitle,
                      filePath: filePathController.text,
                      connectedNfcUuid: dialogNfcUuid,
                      isLoopEnabled: isLoopEnabled,
                      rememberPosition: rememberPosition,
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
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    // Show settings tutorial if a new song was added and it's the first time
                    if (!isEditing && TutorialService.instance.shouldShowSettingsTutorial) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final targets = createTutorialTargets(
                          context: context,
                          settingsMenuKey: _settingsMenuKey,
                        );
                        if (targets.isNotEmpty) {
                          showTutorial(
                            context: context,
                            targets: targets,
                            onFinish: () => TutorialService.instance.markSettingsTutorialShown(),
                            onSkip: () => TutorialService.instance.markSettingsTutorialShown(),
                          );
                        }
                      });
                    }
                  }
                },
                child: Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.create),
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
    int index,
  ) {
    // Get songs in this folder
    final folderSongs = songProvider.songs.where((song) => folder.songIds.contains(song.id)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).footerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Provider.of<ThemeProvider>(context).bannerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Folder header
          InkWell(
            onTap: () => folderProvider.toggleFolderExpansion(folder.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: folder.isExpanded ? Provider.of<ThemeProvider>(context).bannerColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    folder.isExpanded ? Icons.folder_open : Icons.folder,
                    color: Provider.of<ThemeProvider>(context).bannerColor,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Provider.of<ThemeProvider>(context).bannerColor,
                      ),
                    ),
                  ),
                  Icon(
                    folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Provider.of<ThemeProvider>(context).bannerColor,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
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
                  const SizedBox(width: 4),
                  ReorderableDragStartListener(
                    index: index,
                    child: IconButton(
                      icon: const Icon(Icons.drag_handle, size: 18),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
                        color: Provider.of<ThemeProvider>(context).bannerColor.withValues(alpha: 0.1),
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
                                    await musicPlayer.playMusic(song);
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
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 16),
                                        const SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)!.editSong),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, size: 16),
                                        const SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)!.deleteSong),
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

  Widget _buildDraggableFolderWidget(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
    SongProvider songProvider,
    MusicPlayer musicPlayer,
    int index,
  ) {
    return Container(
      key: Key('folder_${folder.id}'),
      child: _buildFolderWidget(context, folder, folderProvider, songProvider, musicPlayer, index),
    );
  }

  void _showEditFolderDialog(BuildContext context, Folder folder, FolderProvider folderProvider) {
    final TextEditingController nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.folderName),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.save),
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
        title: Text(AppLocalizations.of(context)!.deleteFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.areYouSureDeleteFolder),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.folderName}: ${folder.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.songsInFolder(folder.songIds.length)),
            if (folder.songIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noteDeleteSongs,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
              if (!context.mounted) return;
              final navigator = Navigator.of(context);
              navigator.pop();
            },
            child: Text(AppLocalizations.of(context)!.deleteAll, style: const TextStyle(color: Colors.red)),
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
        title: Text(AppLocalizations.of(context)!.deleteSong),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.areYouSureDeleteSong),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.title}: ${song.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (song.connectedNfcUuid != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.nfcMappingRemoved(song.connectedNfcUuid!),
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.audioFileDeleted,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.upgradeToPremium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.freeVersionLimit,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.upgradeToUnlock,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.later),
          ),
          ElevatedButton(
            onPressed: () async {
              await IAPService.instance.buyPremium();
              if (!mounted) return;
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.upgrade),
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
        title: Text(AppLocalizations.of(context)!.storageDebug),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.storageServiceStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• ${AppLocalizations.of(context)!.initialized(storageService.isInitialized)}'),
              Text('• ${AppLocalizations.of(context)!.platform(Platform.operatingSystem)}'),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.storageStatistics, style: const TextStyle(fontWeight: FontWeight.bold)),
              ...storageService.getStorageStats().entries.map(
                (entry) => Text('• ${entry.key}: ${entry.value}')
              ),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.iapPremiumStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (AppConfig.isGooglePlayRelease) ...[
                Text('• ${AppLocalizations.of(context)!.premiumStatus(IAPService.instance.isPremium)}'),
              ] else ...[
                Text('• ${AppLocalizations.of(context)!.premiumNotAvailable}'),
              ],
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.actions, style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      storageService.debugStorageStatus();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.storageDebugInfoLogged)),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.logDebugInfo),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await storageService.forceReinitialize();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.storageReinitialized), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.reinitializationFailed(e)), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.forceReinitialize),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await storageService.clearAllData();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.allStorageDataCleared), backgroundColor: Colors.orange),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.clearFailed(e)), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.clearAllData),
                  ),
                  if (AppConfig.isGooglePlayRelease) ...[
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('💾 IAP Premium Status: ${IAPService.instance.isPremium}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.premiumStatus(IAPService.instance.isPremium))),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.logPremiumStatus),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final localizations = AppLocalizations.of(context)!;
                        try {
                          final box = await Hive.openBox('premium_status');
                          await box.delete('is_premium');
                          debugPrint('🗑️ Premium status cleared');
                          // Refresh the IAP service to get the new value
                          await IAPService.instance.refreshPremiumStatus();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(localizations.clearPremiumStatus), backgroundColor: Colors.orange),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(localizations.clearFailed(e)), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.clearPremiumStatus),
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
            child: Text(AppLocalizations.of(context)!.close),
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
        title: Text(AppLocalizations.of(context)!.debugInformation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.nfcServiceStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• ${AppLocalizations.of(context)!.nfcAvailable(nfcService.isNfcAvailable)}'),
              Text('• ${AppLocalizations.of(context)!.nfcScanning(nfcService.isScanning)}'),
              Text('• ${AppLocalizations.of(context)!.currentUuid(nfcService.currentNfcUuid ?? "None")}'),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.musicPlayerStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• ${AppLocalizations.of(context)!.currentState(musicPlayer.currentState)}'),
              Text('• ${AppLocalizations.of(context)!.isPlaying(musicPlayer.isPlaying)}'),
              Text('• ${AppLocalizations.of(context)!.isPaused(musicPlayer.isPaused)}'),
              Text('• ${AppLocalizations.of(context)!.currentFile(musicPlayer.currentMusicFilePath ?? "None")}'),
              Text('• ${AppLocalizations.of(context)!.position(musicPlayer.savedPosition)}'),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.songsMappings, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• ${AppLocalizations.of(context)!.totalSongs(songProvider.songs.length)}'),
              for (int i = 0; i < songProvider.songs.length; i++)
                Text('• ${AppLocalizations.of(context)!.songWithUuid(i, songProvider.songs[i].title, songProvider.songs[i].connectedNfcUuid ?? "None")}'),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.flavorInformation, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• ${AppLocalizations.of(context)!.githubRelease(AppConfig.isGitHubRelease)}'),
              Text('• ${AppLocalizations.of(context)!.fdroidRelease(AppConfig.isFdroidRelease)}'),
              Text('• ${AppLocalizations.of(context)!.googlePlayRelease(AppConfig.isGooglePlayRelease)}'),
              const SizedBox(height: 16),
              
              Text(AppLocalizations.of(context)!.actions, style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final debugInfo = nfcService.getDebugInfo();
                      debugPrint('📊 NFC Debug Info: $debugInfo');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.debugInfoLogged)),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.logDebugInfo),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      musicPlayer.simulateStateTest();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.stateTestLogged)),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.testPlayerState),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        if (nfcService.isScanning) {
                          await nfcService.stopNfcSession();
                        } else {
                          await nfcService.startNfcSession();
                        }
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(nfcService.isScanning ? 'NFC scanning started' : 'NFC scanning stopped')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.nfcOperationFailed(e))),
                        );
                      }
                    },
                    child: Text(nfcService.isScanning ? 'Stop NFC' : 'Start NFC'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      nfcService.forceProcessCurrentUuid();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.forceProcessedUuid)),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.forceProcessUuid),
                  ),
                  if (kDebugMode)
                    ElevatedButton(
                      onPressed: () async {
                        await TutorialService.instance.resetTutorial();
                        if (!mounted) return;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.tutorialReset)),
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.resetTutorial),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeTutorial() async {
    await TutorialService.instance.initialize();
    if (TutorialService.instance.shouldShowTutorial) {
      // Wait for the first frame to be rendered so keys are available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        final folderProvider = Provider.of<FolderProvider>(context, listen: false);
        final targets = createTutorialTargets(
          context: context,
          addFolderButtonKey: folderProvider.folders.isEmpty ? _addFolderButtonKey : null,
          addSongButtonKey: folderProvider.folders.isNotEmpty ? _addSongButtonKey : null,
        );
        
        if (targets.isNotEmpty) {
          showTutorial(
            context: context,
            targets: targets,
            onFinish: () {
              // Only mark as shown if we've shown the Add Audio File step
              if (folderProvider.folders.isNotEmpty) {
                TutorialService.instance.markTutorialShown();
              }
            },
            onSkip: () {
              // Mark as shown if they skip
              TutorialService.instance.markTutorialShown();
            },
          );
        }
      });
    }
  }

  String _getDisplayName(String? path) {
    if (path == null || path.isEmpty) return 'Unknown';
    return p.basename(path);
  }

  Future<bool> _isValidAudioFile(String path) async {
    if (path.isEmpty) return false;

    // Check if it's a content URI (from Android intent) or a file path
    if (path.startsWith('content://')) {
      return true;
    }

    final file = File(path);
    if (!await file.exists()) return false;

    final extension = p.extension(path).toLowerCase();
    final validExtensions = ['.mp3', '.m4a', '.wav', '.ogg', '.flac', '.aac'];
    return validExtensions.contains(extension);
  }

  void _openVoiceRecorderApp(BuildContext context) async {
    const packageName = 'org.fossify.voicerecorder';
    
    // Try to open the app first
    final appOpened = await AudioIntentService().openApp(packageName);
    if (appOpened) return;

    // If app not found, open the store/github URL
    String url;
    if (AppConfig.isGooglePlayRelease) {
      url = 'https://play.google.com/store/apps/details?id=$packageName';
    } else if (AppConfig.isFdroidRelease) {
      url = 'https://f-droid.org/en/packages/$packageName/';
    } else {
      url = 'https://github.com/FossifyOrg/Voice-Recorder/releases';
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to open link: $e')),
        );
      }
    }
  }

}

class _DialogState {
  bool isOpen = true;
}
