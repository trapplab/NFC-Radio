import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:collection/collection.dart';
import 'nfc/nfc_music_mapping.dart';
import 'nfc/nfc_service.dart';
import 'audio/music_player.dart';
import 'audio/player_widget.dart';
import 'audio/sleep_timer_service.dart';
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
import 'config/social_icon_bar.dart';
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
        ChangeNotifierProvider(create: (_) => SleepTimerService()),
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
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
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

class _NFCJukeboxHomePageState extends State<NFCJukeboxHomePage>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _nfcMessageSubscription;
  String _appVersion = '';
  List<GitHubAudioFolder>? _githubFolders;
  bool _isLoadingGithubFolders = false;
  bool _initializationStarted = false;

  // Quick Connect Tag Mode
  bool _quickConnectMode = false;
  String? _quickConnectSelectedSongId;
  String? _quickConnectSelectedFolderId;
  final Set<String> _quickConnectFlashSuccessIds = {};
  VoidCallback? _quickConnectNfcListener;
  NFCService? _nfcServiceRef;

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

  void _showImportConfirmation(
    BuildContext context,
    GitHubAudioFolder githubFolder,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final localization = githubFolder.getLocalization(locale);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.importQuestion(localization?.title ?? githubFolder.folderName),
        ),
        content: Text(l10n.importDescription(localization?.files.length ?? 0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importGithubFolder(githubFolder);
            },
            child: Text(l10n.importButton),
          ),
        ],
      ),
    );
  }

  /// Format bytes into human-readable format (KB, MB, GB)
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
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

    // Show progress dialog with file counter and size
    int currentFile = 0;
    final totalFiles = localization.files.length;
    int downloadedBytes = 0;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          dialogSetState = setState;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.downloadingAudioFiles),
                const SizedBox(height: 8),
                Text(
                  '$currentFile / $totalFiles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Downloaded: ${_formatBytes(downloadedBytes)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final List<String> songIds = [];
      final List<String> failedFiles = [];

      for (final githubFile in localization.files) {
        try {
          currentFile++;
          if (mounted && dialogSetState != null) {
            dialogSetState!(() {}); // Update progress
          }
          final result = await GitHubAudioService.downloadAudioFile(
            githubFolder.folderName,
            githubFile.name,
          );
          downloadedBytes += result.sizeBytes;

          if (mounted && dialogSetState != null) {
            dialogSetState!(() {}); // Update progress with size
          }

          final song = Song(
            id: const Uuid().v4(),
            title: githubFile.title,
            filePath: result.path,
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
                onFinish: () =>
                    TutorialService.instance.markSettingsTutorialShown(),
                onSkip: () =>
                    TutorialService.instance.markSettingsTutorialShown(),
              );
            }
          });
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        final l10n = AppLocalizations.of(context)!;

        if (failedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importSuccess(localization.title))),
          );
        } else if (songIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.importFailed(localization.title)),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.partialImport),
              content: Text(
                '${l10n.importedFiles(songIds.length, failedFiles.length)}\n\n${failedFiles.join(', ')}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToImport(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
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
      await UpdateService.checkGithubUpdate(
        context,
        'trapplab',
        'NFC-Radio',
        manual: manual,
      );
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.updateCheckFailed(e.toString()),
            ),
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

    // Set up Quick Connect NFC listener (once)
    if (_quickConnectNfcListener == null) {
      _nfcServiceRef = nfcService;
      _quickConnectNfcListener = () {
        if (!_quickConnectMode) return;
        if (!nfcService.isProcessingTag) return;
        final uuid = nfcService.currentNfcUuid;
        if (uuid == null) return;
        _handleQuickConnectNfcScan(uuid);
      };
      nfcService.addListener(_quickConnectNfcListener!);
    }

    // Initialize providers after first frame to ensure context is available
    if (!_initializationStarted) {
      _initializationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          final songProvider = Provider.of<SongProvider>(
            context,
            listen: false,
          );
          final folderProvider = Provider.of<FolderProvider>(
            context,
            listen: false,
          );
          final mappingProvider = Provider.of<NFCMusicMappingProvider>(
            context,
            listen: false,
          );
          final musicPlayer = Provider.of<MusicPlayer>(context, listen: false);
          final nfcService = Provider.of<NFCService>(context, listen: false);
          final settingsProvider = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          final sleepTimerService = Provider.of<SleepTimerService>(
            context,
            listen: false,
          );

          // Wire up sleep timer with music player
          sleepTimerService.setMusicPlayer(musicPlayer);

          // Listen for playback state changes to manage sleep timer
          musicPlayer.addListener(() {
            if (musicPlayer.isPlaying && !sleepTimerService.isActive) {
              // Auto-start sleep timer if enabled
              if (sleepTimerService.shouldAutoEnable(
                autoEnabled: settingsProvider.autoSleepTimerEnabled,
                restrictHours: settingsProvider.autoSleepTimerRestrictHours,
                startHour: settingsProvider.autoSleepTimerStartHour,
                endHour: settingsProvider.autoSleepTimerEndHour,
              )) {
                final duration = settingsProvider.sleepTimerDurationMinutes == 0
                    ? const Duration(seconds: 10)
                    : Duration(
                        minutes: settingsProvider.sleepTimerDurationMinutes,
                      );
                sleepTimerService.start(duration);
              }
            } else if (musicPlayer.isPlaying && sleepTimerService.isActive) {
              // Resume timer if it was paused
              sleepTimerService.resume();
            } else if (musicPlayer.isPaused && sleepTimerService.isActive) {
              sleepTimerService.pause();
            } else if (musicPlayer.isStopped && sleepTimerService.isActive) {
              sleepTimerService.cancel();
            }
          });

          // Re-evaluate sleep timer when settings change
          settingsProvider.addListener(() {
            if (!sleepTimerService.isActive || !musicPlayer.isPlaying) return;
            final shouldBeActive = sleepTimerService.shouldAutoEnable(
              autoEnabled: settingsProvider.autoSleepTimerEnabled,
              restrictHours: settingsProvider.autoSleepTimerRestrictHours,
              startHour: settingsProvider.autoSleepTimerStartHour,
              endHour: settingsProvider.autoSleepTimerEndHour,
            );
            if (!shouldBeActive) {
              sleepTimerService.cancel();
            }
          });

          // Set callback for position changes to persist in song
          musicPlayer.onPositionChangedCallback = (position) {
            if (musicPlayer.currentSong != null) {
              songProvider.updateSongPosition(
                musicPlayer.currentSong!.id,
                position.inMilliseconds,
              );
            }
          };

          // Set callback for playlist position changes to persist in folder
          musicPlayer.onPlaylistPositionChanged =
              (folderId, songIndex, positionMs) {
                folderProvider.updateFolderPlaybackState(
                  folderId,
                  lastPlayedSongIndex: songIndex,
                  lastPlayedPositionMs: positionMs,
                );
              };

          if (!songProvider.isInitialized ||
              !folderProvider.isInitialized ||
              !settingsProvider.isInitialized) {
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
            debugPrint(
              '📊 Mappings loaded: ${mappingProvider.mappings.length}',
            );

            // Show success message if we loaded existing data
            if (mounted &&
                (songProvider.songs.isNotEmpty ||
                    folderProvider.folders.isNotEmpty ||
                    mappingProvider.mappings.isNotEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.loadedData),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (mounted) {
              debugPrint(
                'ℹ️ No existing data found. A default folder should have been created.',
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
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.failedToLoadData),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
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
    if (_quickConnectNfcListener != null) {
      _nfcServiceRef?.removeListener(_quickConnectNfcListener!);
    }
    super.dispose();
  }

  Future<void> _handleQuickConnectNfcScan(String uuid) async {
    if (!mounted) return;

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    if (_quickConnectSelectedSongId == null &&
        _quickConnectSelectedFolderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quickConnectSelectFirst),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Find conflicts: tag already assigned to another song or folder
    Song? conflictingSong;
    Folder? conflictingFolder;

    for (final s in songProvider.songs) {
      if (s.connectedNfcUuid == uuid && s.id != _quickConnectSelectedSongId) {
        conflictingSong = s;
        break;
      }
    }
    for (final f in folderProvider.folders) {
      if (f.connectedNfcUuid == uuid && f.id != _quickConnectSelectedFolderId) {
        conflictingFolder = f;
        break;
      }
    }

    bool shouldConnect = true;

    if (conflictingSong != null && mounted) {
      shouldConnect =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.nfcTagAlreadyConnected),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nfcAlreadyConnectedTo),
                  const SizedBox(height: 8),
                  Text(
                    '"${conflictingSong!.title}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.replaceConnectionQuestion),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.keepExisting),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.replaceConnection),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldConnect) {
        songProvider.disconnectSongFromNfc(conflictingSong.id);
        mappingProvider.removeMapping(conflictingSong.id);
      }
    }

    if (conflictingFolder != null && shouldConnect && mounted) {
      shouldConnect =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.nfcTagAlreadyConnected),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nfcAlreadyConnectedToFolder),
                  const SizedBox(height: 8),
                  Text(
                    '"${conflictingFolder!.name}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.replaceConnectionQuestion),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.keepExisting),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.replaceConnection),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldConnect) {
        folderProvider.disconnectFolderFromNfc(conflictingFolder.id);
      }
    }

    if (!shouldConnect || !mounted) return;

    // Connect and flash success
    if (_quickConnectSelectedSongId != null) {
      final songId = _quickConnectSelectedSongId!;
      songProvider.connectSongToNfc(songId, uuid);
      mappingProvider.removeMapping(songId);
      mappingProvider.addMapping(
        NFCMusicMapping(nfcUuid: uuid, songId: songId),
      );
      setState(() {
        _quickConnectFlashSuccessIds.add(songId);
        _quickConnectSelectedSongId = null;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted)
          setState(() => _quickConnectFlashSuccessIds.remove(songId));
      });
    } else if (_quickConnectSelectedFolderId != null) {
      final folderId = _quickConnectSelectedFolderId!;
      folderProvider.connectFolderToNfc(folderId, uuid);
      setState(() {
        _quickConnectFlashSuccessIds.add(folderId);
        _quickConnectSelectedFolderId = null;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted)
          setState(() => _quickConnectFlashSuccessIds.remove(folderId));
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingGithubFolders)
                  const Center(child: CircularProgressIndicator())
                else if (_githubFolders == null || _githubFolders!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.couldNotLoadTemplates,
                        ),
                        TextButton(
                          onPressed: _fetchGithubFolders,
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  )
                else
                  ExpansionTile(
                    title: Text(
                      AppLocalizations.of(context)!.audioStarterPacks,
                    ),
                    leading: const Icon(Icons.cloud_download),
                    children: _githubFolders!.map((githubFolder) {
                      final locale = Localizations.localeOf(context).toString();
                      final localization = githubFolder.getLocalization(locale);
                      return ListTile(
                        title: Text(
                          localization?.title ?? githubFolder.folderName,
                        ),
                        subtitle: Text(localization?.description ?? ''),
                        onTap: () =>
                            _showImportConfirmation(context, githubFolder),
                      );
                    }).toList(),
                  ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.browseAudioOnly),
                  subtitle: Text(
                    settings.filterAudioOnly
                        ? AppLocalizations.of(context)!.filterAudio
                        : AppLocalizations.of(context)!.filterAll,
                  ),
                  value: settings.filterAudioOnly,
                  onChanged: (value) {
                    settings.setFilterAudioOnly(value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.useKioskMode),
                  subtitle: Text(
                    AppLocalizations.of(context)!.requiresSystemAlertPermission,
                  ),
                  value: settings.useSystemOverlay,
                  onChanged: (value) {
                    settings.setUseSystemOverlay(value);
                  },
                ),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.showAudioControlsOnLockscreen,
                  ),
                  value: settings.showAudioControlsOnLockscreen,
                  onChanged: (value) {
                    settings.setShowAudioControlsOnLockscreen(value);
                  },
                ),
                ExpansionTile(
                  title: Text(AppLocalizations.of(context)!.sleepTimer),
                  leading: const Icon(Icons.bedtime),
                  children: [
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.sleepTimerDuration,
                      ),
                      trailing: DropdownButton<int>(
                        value: settings.sleepTimerDurationMinutes,
                        onChanged: (value) {
                          if (value != null) {
                            settings.setSleepTimerDurationMinutes(value);
                            final sleepTimer = Provider.of<SleepTimerService>(
                              context,
                              listen: false,
                            );
                            if (sleepTimer.isActive) {
                              final duration = value == 0
                                  ? const Duration(seconds: 10)
                                  : Duration(minutes: value);
                              sleepTimer.start(duration);
                            }
                          }
                        },
                        items: [5, 10, 15, 30, 45, 60, 90].map((minutes) {
                          return DropdownMenuItem<int>(
                            value: minutes,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.sleepTimerMinutes(minutes),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.autoSleepTimer),
                      subtitle: Text(
                        AppLocalizations.of(context)!.autoSleepTimerDescription,
                      ),
                      value: settings.autoSleepTimerEnabled,
                      onChanged: (value) {
                        settings.setAutoSleepTimerEnabled(value);
                      },
                    ),
                    if (settings.autoSleepTimerEnabled) ...[
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.restrictToHours,
                        ),
                        value: settings.autoSleepTimerRestrictHours,
                        onChanged: (value) {
                          settings.setAutoSleepTimerRestrictHours(value);
                        },
                      ),
                      if (settings.autoSleepTimerRestrictHours) ...[
                        Builder(
                          builder: (context) {
                            final use24h = MediaQuery.of(
                              context,
                            ).alwaysUse24HourFormat;
                            String formatHour(int hour) {
                              if (use24h)
                                return '${hour.toString().padLeft(2, '0')}:00';
                              final displayHour = hour == 0
                                  ? 12
                                  : (hour > 12 ? hour - 12 : hour);
                              final period = hour < 12 ? 'AM' : 'PM';
                              return '$displayHour:00 $period';
                            }

                            return Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.sleepTimerFrom,
                                  ),
                                  trailing: DropdownButton<int>(
                                    value: settings.autoSleepTimerStartHour,
                                    onChanged: (value) {
                                      if (value != null) {
                                        settings.setAutoSleepTimerStartHour(
                                          value,
                                        );
                                      }
                                    },
                                    items: List.generate(24, (hour) {
                                      return DropdownMenuItem<int>(
                                        value: hour,
                                        child: Text(formatHour(hour)),
                                      );
                                    }),
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.sleepTimerTo,
                                  ),
                                  trailing: DropdownButton<int>(
                                    value: settings.autoSleepTimerEndHour,
                                    onChanged: (value) {
                                      if (value != null) {
                                        settings.setAutoSleepTimerEndHour(
                                          value,
                                        );
                                      }
                                    },
                                    items: List.generate(24, (hour) {
                                      return DropdownMenuItem<int>(
                                        value: hour,
                                        child: Text(formatHour(hour)),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
                const Divider(),
                const ColorChooser(),
                const Divider(),
                const SocialIconBar(),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.appVersion),
                  subtitle: Text(
                    _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...',
                  ),
                  trailing: AppConfig.isGitHubRelease
                      ? const Icon(Icons.refresh)
                      : null,
                  onTap: AppConfig.isGitHubRelease
                      ? () => _checkForUpdates(manual: true)
                      : null,
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
              icon: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
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
              onPressed: () {
                TutorialService.instance.markSettingsTutorialShown();
                Scaffold.of(context).openEndDrawer();
              },
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
                  if (kDebugMode)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: nfcService.isScanning
                              ? Colors.green
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (!nfcService.isNfcAvailable) ...[
                            Text(AppLocalizations.of(context)!.nfcNotAvailable),
                          ] else ...[
                            Text(
                              AppLocalizations.of(context)!.readyToScanNfc,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  nfcService.isScanning
                                      ? Icons.radio
                                      : Icons.radio_button_off,
                                  color: nfcService.isScanning
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nfcService.isScanning
                                      ? AppLocalizations.of(
                                          context,
                                        )!.scanningForNfc
                                      : AppLocalizations.of(
                                          context,
                                        )!.scanningPaused,
                                  style: TextStyle(
                                    color: nfcService.isScanning
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (nfcService.currentNfcUuid != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.lastDetected(nfcService.currentNfcUuid!),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: nfcService.isScanning
                                      ? null
                                      : () {
                                          nfcService.startNfcSession();
                                        },
                                  child: Text(
                                    AppLocalizations.of(context)!.startScanning,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: nfcService.isScanning
                                      ? () {
                                          nfcService.stopNfcSession();
                                        }
                                      : null,
                                  child: Text(
                                    AppLocalizations.of(context)!.stopScanning,
                                  ),
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
                          if (folderProvider.rootFolders.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppLocalizations.of(context)!.noFoldersYet,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            // Add button when no folders exist
                            _buildAddFolderButton(context, folderProvider),
                          ] else ...[
                            ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: folderProvider.rootFolders.length,
                              itemBuilder: (context, index) {
                                final folder =
                                    folderProvider.rootFolders[index];
                                return _buildDraggableFolderWidget(
                                  context,
                                  folder,
                                  folderProvider,
                                  songProvider,
                                  musicPlayer,
                                  index,
                                );
                              },
                              onReorder: (oldIndex, newIndex) {
                                folderProvider.reorderFolders(
                                  oldIndex,
                                  newIndex,
                                );
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
          if (!nfcService.isInEditMode) const PlayerWidget(),
        ],
      ),
    );
  }

  Widget _buildAddFolderButton(
    BuildContext context,
    FolderProvider folderProvider,
  ) {
    return Column(
      children: [
        Container(
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
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ElevatedButton.icon(
            onPressed: () {
              final nfcService = Provider.of<NFCService>(
                context,
                listen: false,
              );
              setState(() {
                _quickConnectMode = !_quickConnectMode;
                if (!_quickConnectMode) {
                  _quickConnectSelectedSongId = null;
                  _quickConnectSelectedFolderId = null;
                }
              });
              nfcService.setEditMode(_quickConnectMode);
            },
            icon: Icon(_quickConnectMode ? Icons.nfc : Icons.nfc_outlined),
            label: Text(AppLocalizations.of(context)!.quickConnectTagMode),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _quickConnectMode
                  ? Theme.of(context).colorScheme.primary
                  : null,
              foregroundColor: _quickConnectMode
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSongGridTile(
    BuildContext context,
    SongProvider songProvider,
    String folderId,
  ) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final isFirstFolder =
        folderProvider.folders.isNotEmpty &&
        folderProvider.folders.first.id == folderId;

    return Container(
      key: isFirstFolder ? _addSongButtonKey : null,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (folderProvider.isSongLimitReached(folderId)) {
            folderProvider.showSongLimitDialog(context);
          } else {
            _showSongDialog(context, songProvider, folderId: folderId);
          }
        },
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.add, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.addAudioFile,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMultipleGridTile(
    BuildContext context,
    SongProvider songProvider,
    String folderId,
  ) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (folderProvider.isSongLimitReached(folderId)) {
            folderProvider.showSongLimitDialog(context);
            return;
          }
          _pickMultipleAudioFiles(
            context,
            songProvider,
            folderProvider,
            folderId,
          );
        },
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.playlist_add, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.addMultipleAudioFiles,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMultipleAudioFiles(
    BuildContext context,
    SongProvider songProvider,
    FolderProvider folderProvider,
    String folderId,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final files = await AudioIntentService().pickAudioFromApp(
      filterAudioOnly: settings.filterAudioOnly,
    );

    if (!context.mounted) return;

    int addedCount = 0;
    for (final audioFile in files) {
      final path = audioFile.sourceUri.isScheme('file')
          ? audioFile.sourceUri.toFilePath()
          : audioFile.sourceUri.toString();

      final isValid = await _isValidAudioFile(path);
      if (!isValid) continue;

      final title = (audioFile.displayName ?? path.split('/').last).replaceAll(
        RegExp(r'\.[^.]+$'),
        '',
      );

      final newSong = Song(id: const Uuid().v4(), title: title, filePath: path);

      songProvider.addSong(newSong);
      folderProvider.addSongToFolder(folderId, newSong.id);
      addedCount++;
      debugPrint(
        '📥 Multi-import: Added "$title" to folder $folderId ($addedCount files so far)',
      );
    }

    if (addedCount > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.filesAdded(addedCount)),
        ),
      );
    }
  }

  void _showAddFolderDialog(
    BuildContext context,
    FolderProvider folderProvider,
  ) {
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.folderName,
              ),
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

  void _showSongDialog(
    BuildContext context,
    SongProvider songProvider, {
    Song? song,
    String? folderId,
  }) {
    final bool isEditing = song != null;
    final TextEditingController titleController = TextEditingController(
      text: song?.title ?? '',
    );
    final TextEditingController filePathController = TextEditingController(
      text: song?.filePath ?? '',
    );
    final String? originalFilePath = song?.filePath;
    String? dialogNfcUuid = song?.connectedNfcUuid;
    bool isConnecting = false; // Prevent double-click issues

    final nfcService = Provider.of<NFCService>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);

    // Identify the current folder
    String? currentFolderId = folderId;
    if (currentFolderId == null && song != null) {
      try {
        currentFolderId = folderProvider.folders
            .firstWhere((f) => f.songIds.contains(song.id))
            .id;
      } catch (_) {}
    }
    if (currentFolderId == null) {
      // Fallback to expanded folder or first folder
      try {
        currentFolderId = folderProvider.folders
            .firstWhere((f) => f.isExpanded)
            .id;
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

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Show tutorial if needed (Step 1: Attach File)
          if (!tutorialTriggered &&
              TutorialService.instance.shouldShowSongDialogTutorial) {
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

            // Skip if already in the middle of connecting (prevents duplicate triggers)
            if (isConnecting) {
              return;
            }

            final currentNfcUuid = nfcService.currentNfcUuid;
            if (currentNfcUuid != null && currentNfcUuid != dialogNfcUuid) {
              // Check if this NFC is already linked in the same folder
              Song? existingSong;
              try {
                if (currentFolderId != null) {
                  final currentFolder = folderProvider.folders.firstWhere(
                    (f) => f.id == currentFolderId,
                  );
                  existingSong = songProvider.songs.firstWhere(
                    (s) =>
                        s.connectedNfcUuid == currentNfcUuid &&
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
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        dialogContext,
                      )!.nfcLinkedAutomatically,
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                // Just trigger rebuild to show the "Use This NFC" button for manual resolution
                // But don't trigger if we're already processing a connection
                setState(() {});
              }
            }
          };

          nfcService.addListener(updateNfcUuid);

          return AlertDialog(
            title: Text(
              isEditing
                  ? AppLocalizations.of(dialogContext)!.editSong
                  : AppLocalizations.of(dialogContext)!.addNewSong,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: filePathController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              dialogContext,
                            )!.audioSource,
                          ),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        key: _attachFileButtonKey,
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final settings = Provider.of<SettingsProvider>(
                            dialogContext,
                            listen: false,
                          );
                          final files = await AudioIntentService()
                              .pickAudioFromApp(
                                filterAudioOnly: settings.filterAudioOnly,
                              );
                          if (!dialogContext.mounted) return;
                          if (files.isEmpty) return;
                          final audioFile = files.first;
                          final path = audioFile.sourceUri.isScheme('file')
                              ? audioFile.sourceUri.toFilePath()
                              : audioFile.sourceUri.toString();
                          final isValid = await _isValidAudioFile(path);
                          if (!dialogContext.mounted) return;
                          if (!isValid) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    dialogContext,
                                  )!.rejectedInvalidAudio,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            filePathController.text = path;
                            if (titleController.text.isEmpty &&
                                audioFile.displayName != null) {
                              titleController.text = audioFile.displayName!
                                  .replaceAll(RegExp(r'\.[^.]+$'), '');
                            }
                          });
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  dialogContext,
                                )!.audioSelected(
                                  audioFile.displayName ?? 'Unknown',
                                ),
                              ),
                            ),
                          );
                          // Show tutorial Step 2: NFC Connection
                          if (TutorialService
                              .instance
                              .shouldShowNfcConnectionTutorial) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final targets = createTutorialTargets(
                                context: dialogContext,
                                nfcAreaKey: _nfcAreaKey,
                              );
                              if (targets.isNotEmpty) {
                                showTutorial(
                                  context: dialogContext,
                                  targets: targets,
                                  onFinish: () => TutorialService.instance
                                      .markNfcConnectionTutorialShown(),
                                  onSkip: () => TutorialService.instance
                                      .markNfcConnectionTutorialShown(),
                                );
                              }
                            });
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(dialogContext)!.title,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(dialogContext)!.playbackOptions,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(dialogContext)!.loopPlayback),
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
                      Text(
                        AppLocalizations.of(dialogContext)!.rememberPosition,
                      ),
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
                    Text(AppLocalizations.of(dialogContext)!.nfcConfiguration),
                    const SizedBox(height: 8),
                    Container(
                      key: _nfcAreaKey,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dialogNfcUuid != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dialogNfcUuid != null) ...[
                            Text(
                              AppLocalizations.of(
                                dialogContext,
                              )!.assignedNfc(dialogNfcUuid!.substring(0, 8)),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

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
                                    AppLocalizations.of(
                                      dialogContext,
                                    )!.newNfcDetected(
                                      nfcService.currentNfcUuid!.substring(
                                        0,
                                        8,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: isConnecting
                                        ? null
                                        : () async {
                                            setState(() => isConnecting = true);
                                            final currentNfcUuid =
                                                nfcService.currentNfcUuid;
                                            if (currentNfcUuid == null) {
                                              setState(
                                                () => isConnecting = false,
                                              );
                                              return;
                                            }

                                            // Check if this NFC is already connected to another folder
                                            // (conflicts with folders are OK to show, songs within same folder handled later)
                                            Folder? conflictingFolder;
                                            try {
                                              conflictingFolder = folderProvider
                                                  .folders
                                                  .firstWhere(
                                                    (f) =>
                                                        f.connectedNfcUuid ==
                                                            currentNfcUuid &&
                                                        f.id != currentFolderId,
                                                  );
                                            } catch (_) {
                                              conflictingFolder = null;
                                            }

                                            // If conflict with folder, show dialog first
                                            if (conflictingFolder != null &&
                                                dialogContext.mounted) {
                                              final shouldReplace = await showDialog<bool>(
                                                context: dialogContext,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    AppLocalizations.of(
                                                      dialogContext,
                                                    )!.nfcTagAlreadyConnected,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.nfcAlreadyConnectedToFolder,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '"${conflictingFolder!.name}"',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnectionQuestion,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(false),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.keepExisting,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(true),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnection,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (shouldReplace == false) {
                                                setState(
                                                  () => isConnecting = false,
                                                );
                                                return;
                                              }

                                              // Disconnect the conflicting folder
                                              folderProvider
                                                  .disconnectFolderFromNfc(
                                                    conflictingFolder.id,
                                                  );
                                            }

                                            // Original conflict check for songs in same folder continues here...

                                            Song? existingSong;
                                            try {
                                              // Only check for existing connection within the same folder
                                              if (currentFolderId != null) {
                                                final currentFolder =
                                                    folderProvider.folders
                                                        .firstWhere(
                                                          (f) =>
                                                              f.id ==
                                                              currentFolderId,
                                                        );
                                                existingSong = songProvider
                                                    .songs
                                                    .firstWhere(
                                                      (s) =>
                                                          s.connectedNfcUuid ==
                                                              currentNfcUuid &&
                                                          currentFolder.songIds
                                                              .contains(s.id) &&
                                                          (song == null ||
                                                              s.id != song.id),
                                                    );
                                              }
                                            } catch (_) {
                                              existingSong = null;
                                            }

                                            bool shouldUseNewNfc = true;
                                            if (existingSong != null) {
                                              if (!dialogContext.mounted) {
                                                setState(
                                                  () => isConnecting = false,
                                                );
                                                return;
                                              }
                                              shouldUseNewNfc =
                                                  await showDialog<bool>(
                                                    context: dialogContext,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          AppLocalizations.of(
                                                            dialogContext,
                                                          )!.nfcTagAlreadyConnected,
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              AppLocalizations.of(
                                                                dialogContext,
                                                              )!.nfcAlreadyConnectedTo,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              '"${existingSong!.title}"',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                dialogContext,
                                                              )!.replaceConnectionQuestion,
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop(false),
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                dialogContext,
                                                              )!.keepExisting,
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop(true),
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                dialogContext,
                                                              )!.replaceConnection,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ) ??
                                                  false;

                                              // Roll back folder disconnect if user declined song conflict
                                              if (!shouldUseNewNfc &&
                                                  conflictingFolder != null) {
                                                folderProvider.connectFolderToNfc(
                                                  conflictingFolder.id,
                                                  currentNfcUuid,
                                                );
                                              }
                                            }

                                            if (shouldUseNewNfc) {
                                              // Only remove mapping from songs in the same folder
                                              if (currentFolderId != null) {
                                                final currentFolder =
                                                    folderProvider.folders
                                                        .firstWhere(
                                                          (f) =>
                                                              f.id ==
                                                              currentFolderId,
                                                        );
                                                final songsWithThisNfcInFolder =
                                                    songProvider.songs
                                                        .where(
                                                          (s) =>
                                                              s.connectedNfcUuid ==
                                                                  currentNfcUuid &&
                                                              currentFolder
                                                                  .songIds
                                                                  .contains(
                                                                    s.id,
                                                                  ) &&
                                                              (song == null ||
                                                                  s.id !=
                                                                      song.id),
                                                        )
                                                        .toList();
                                                for (final s
                                                    in songsWithThisNfcInFolder) {
                                                  songProvider.updateSong(
                                                    Song(
                                                      id: s.id,
                                                      title: s.title,
                                                      filePath: s.filePath,
                                                      connectedNfcUuid: null,
                                                      isLoopEnabled:
                                                          s.isLoopEnabled,
                                                      rememberPosition:
                                                          s.rememberPosition,
                                                      savedPositionMs:
                                                          s.savedPositionMs,
                                                    ),
                                                  );
                                                  mappingProvider.removeMapping(
                                                    s.id,
                                                  );
                                                }
                                              }
                                              setState(() {
                                                dialogNfcUuid = currentNfcUuid;
                                              });
                                            }
                                            if (dialogContext.mounted) {
                                              setState(
                                                () => isConnecting = false,
                                              );
                                            }
                                          },
                                    child: Text(
                                      AppLocalizations.of(
                                        dialogContext,
                                      )!.useThisNfc,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          if (nfcService.currentNfcUuid == null ||
                              nfcService.currentNfcUuid == dialogNfcUuid)
                            dialogNfcUuid != null
                                ? Text(
                                    AppLocalizations.of(
                                      dialogContext,
                                    )!.nfcAssignedReady,
                                  )
                                : nfcService.isScanning
                                ? Text(
                                    AppLocalizations.of(
                                      dialogContext,
                                    )!.scanningForNfc,
                                    style: const TextStyle(color: Colors.blue),
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      dialogContext,
                                    )!.waitingForNfc,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
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
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  if (filePathController.text.isNotEmpty) {
                    if (!dialogContext.mounted) return;
                    final isValid = await _isValidAudioFile(
                      filePathController.text,
                    );
                    if (!isValid) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              dialogContext,
                            )!.cannotSaveInvalidAudio,
                          ),
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
                      // Delete old audio file if it was replaced with a different one
                      if (originalFilePath != null &&
                          originalFilePath != filePathController.text &&
                          !originalFilePath.startsWith('content://')) {
                        final otherSongsUseFile = songProvider.songs.any(
                          (s) =>
                              s.id != song.id && s.filePath == originalFilePath,
                        );
                        if (!otherSongsUseFile) {
                          try {
                            final oldFile = File(originalFilePath);
                            if (await oldFile.exists()) {
                              await oldFile.delete();
                              debugPrint(
                                '🗑️ Deleted old audio file: $originalFilePath',
                              );
                            }
                          } catch (e) {
                            debugPrint(
                              '⚠️ Failed to delete old audio file: $e',
                            );
                          }
                        }
                      }
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
                        mappingProvider.addMapping(
                          NFCMusicMapping(
                            nfcUuid: dialogNfcUuid!,
                            songId: newSong.id,
                          ),
                        );
                      }
                    }

                    dialogState.isOpen = false;
                    nfcService.removeListener(updateNfcUuid);
                    nfcService.setEditMode(false);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    // Show settings tutorial if a new song was added and it's the first time
                    if (!isEditing &&
                        TutorialService.instance.shouldShowSettingsTutorial) {
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
                            onFinish: () => TutorialService.instance
                                .markSettingsTutorialShown(),
                            onSkip: () => TutorialService.instance
                                .markSettingsTutorialShown(),
                          );
                        }
                      });
                    }
                  }
                },
                child: Text(
                  isEditing
                      ? AppLocalizations.of(dialogContext)!.save
                      : AppLocalizations.of(dialogContext)!.create,
                ),
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
    final List<Folder> children = folderProvider.getChildFolders(folder.id);
    final bool isGroupFolder = children.isNotEmpty;

    // Get songs in this folder (only used for leaf folders)
    final folderSongs =
        songProvider.songs
            .where((song) => folder.songIds.contains(song.id))
            .toList()
          ..sort(
            (a, b) => folder.songIds
                .indexOf(a.id)
                .compareTo(folder.songIds.indexOf(b.id)),
          );

    final bool isFolderNfcConnected = folder.connectedNfcUuid != null;
    // For group folders: playlist is active if ANY child subfolder is playing
    final String? activeFolderId = musicPlayer.isPlaylistMode
        ? musicPlayer.currentPlaylistFolderId
        : null;
    final bool isFolderPlaylistActive =
        activeFolderId == folder.id ||
        (isGroupFolder && children.any((c) => c.id == activeFolderId));

    final bool isQCSelectedFolder = _quickConnectSelectedFolderId == folder.id;
    final bool isQCFlashFolder = _quickConnectFlashSuccessIds.contains(
      folder.id,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isQCFlashFolder
            ? Colors.green.withValues(alpha: 0.15)
            : Provider.of<ThemeProvider>(context).footerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isQCFlashFolder
              ? Colors.green
              : isQCSelectedFolder
              ? Theme.of(context).colorScheme.primary
              : isFolderPlaylistActive
              ? Colors.green
              : Provider.of<ThemeProvider>(
                  context,
                ).bannerColor.withValues(alpha: 0.3),
          width: isQCFlashFolder || isQCSelectedFolder || isFolderPlaylistActive
              ? 2
              : 1,
        ),
      ),
      child: Column(
        children: [
          // Folder header
          InkWell(
            onTap: _quickConnectMode
                ? () {
                    setState(() {
                      if (_quickConnectSelectedFolderId == folder.id) {
                        _quickConnectSelectedFolderId = null;
                      } else {
                        _quickConnectSelectedFolderId = folder.id;
                        _quickConnectSelectedSongId = null;
                      }
                    });
                  }
                : () => folderProvider.toggleFolderExpansion(folder.id),
            onLongPress: () => _showFolderActionsDialog(
              context,
              folder,
              folderProvider,
              musicPlayer,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: folder.isExpanded
                    ? Provider.of<ThemeProvider>(
                        context,
                      ).bannerColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isGroupFolder
                        ? Icons.topic
                        : (folder.isExpanded
                              ? Icons.folder_open
                              : Icons.folder),
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
                  if (isFolderNfcConnected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.nfc,
                        size: 16,
                        color: Provider.of<ThemeProvider>(
                          context,
                        ).bannerColor.withValues(alpha: 0.6),
                      ),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        folderProvider.toggleFolderExpansion(folder.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        folder.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Provider.of<ThemeProvider>(context).bannerColor,
                      ),
                    ),
                  ),
                  if (!_quickConnectMode)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isFolderPlaylistActive) {
                          if (musicPlayer.isPlaying) {
                            musicPlayer.pauseMusic();
                          } else {
                            musicPlayer.resumeMusic();
                          }
                        } else if (isGroupFolder) {
                          // Group folder: play a random subfolder's playlist
                          final withSongs = children
                              .where((c) => c.songIds.isNotEmpty)
                              .toList();
                          if (withSongs.isNotEmpty) {
                            final target =
                                withSongs[Random().nextInt(withSongs.length)];
                            final songs = target.songIds
                                .map(
                                  (id) => songProvider.songs.firstWhereOrNull(
                                    (s) => s.id == id,
                                  ),
                                )
                                .nonNulls
                                .toList();
                            if (songs.isNotEmpty) {
                              musicPlayer.startPlaylist(
                                songs: songs,
                                folderId: target.id,
                                shuffle: target.isShuffleEnabled,
                                loopPlaylist: target.isLoopPlaylistEnabled,
                                startIndex: target.lastPlayedSongIndex,
                                startPositionMs:
                                    target.lastPlayedPositionMs ?? 0,
                              );
                            }
                          }
                        } else if (folderSongs.isNotEmpty) {
                          musicPlayer.startPlaylist(
                            songs: folderSongs,
                            folderId: folder.id,
                            shuffle: folder.isShuffleEnabled,
                            loopPlaylist: folder.isLoopPlaylistEnabled,
                            startIndex: folder.lastPlayedSongIndex,
                            startPositionMs: folder.lastPlayedPositionMs ?? 0,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          isFolderPlaylistActive && musicPlayer.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: isFolderPlaylistActive
                              ? Colors.green
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
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

          // Folder content
          if (folder.isExpanded) ...[
            if (isGroupFolder)
              _buildGroupFolderContent(
                context,
                folder,
                children,
                folderProvider,
                songProvider,
                musicPlayer,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const double maxTileExtent = 250;
                  const double spacing = 8;
                  final int columns = (constraints.maxWidth / maxTileExtent)
                      .ceil()
                      .clamp(1, 100);
                  final double tileWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  final double tileHeight = tileWidth / 2.8;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (folderSongs.isNotEmpty)
                        GridView.extent(
                          maxCrossAxisExtent: maxTileExtent,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 2.8,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: spacing,
                          ),
                          children: folderSongs.map((song) {
                            final bool isQCSelected =
                                _quickConnectSelectedSongId == song.id;
                            final bool isQCFlash = _quickConnectFlashSuccessIds
                                .contains(song.id);
                            return GestureDetector(
                              onTap: _quickConnectMode
                                  ? () {
                                      setState(() {
                                        if (_quickConnectSelectedSongId ==
                                            song.id) {
                                          _quickConnectSelectedSongId = null;
                                        } else {
                                          _quickConnectSelectedSongId = song.id;
                                          _quickConnectSelectedFolderId = null;
                                        }
                                      });
                                    }
                                  : null,
                              onLongPress: _quickConnectMode
                                  ? null
                                  : () {
                                      _showSongActionsDialog(
                                        context,
                                        song,
                                        folder.id,
                                        folderProvider,
                                        songProvider,
                                      );
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isQCFlash
                                      ? Colors.green.withValues(alpha: 0.25)
                                      : isQCSelected
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.15)
                                      : Provider.of<ThemeProvider>(
                                          context,
                                        ).bannerColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isQCFlash
                                      ? Border.all(
                                          color: Colors.green,
                                          width: 3,
                                        )
                                      : isQCSelected
                                      ? Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          width: 2,
                                        )
                                      : song.connectedNfcUuid != null
                                      ? Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Icon(
                                      song.connectedNfcUuid != null
                                          ? Icons.music_note
                                          : Icons.music_off,
                                      size: 18,
                                      color: song.connectedNfcUuid != null
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        song.title,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!_quickConnectMode)
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: Icon(
                                          musicPlayer.isSongPlaying(
                                                song.filePath,
                                              )
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          size: 20,
                                          color:
                                              musicPlayer.isSongPlaying(
                                                song.filePath,
                                              )
                                              ? Colors.red
                                              : musicPlayer.isSongPaused(
                                                  song.filePath,
                                                )
                                              ? Colors.orange
                                              : Colors.blue,
                                        ),
                                        onPressed: () async {
                                          if (musicPlayer.isSongPlaying(
                                                song.filePath,
                                              ) ||
                                              musicPlayer.isSongPaused(
                                                song.filePath,
                                              )) {
                                            await musicPlayer.togglePlayPause();
                                          } else {
                                            await musicPlayer.playMusic(song);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: tileWidth,
                              height: tileHeight,
                              child: _buildAddSongGridTile(
                                context,
                                songProvider,
                                folder.id,
                              ),
                            ),
                            const SizedBox(width: spacing),
                            SizedBox(
                              width: tileWidth,
                              height: tileHeight,
                              child: _buildAddMultipleGridTile(
                                context,
                                songProvider,
                                folder.id,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
      child: _buildFolderWidget(
        context,
        folder,
        folderProvider,
        songProvider,
        musicPlayer,
        index,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Group folder helpers
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildGroupFolderContent(
    BuildContext context,
    Folder parentFolder,
    List<Folder> children,
    FolderProvider folderProvider,
    SongProvider songProvider,
    MusicPlayer musicPlayer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppLocalizations.of(context)!.noSubfoldersYet,
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        ...children.map(
          (child) => _buildSubFolderWidget(
            context,
            child,
            folderProvider,
            songProvider,
            musicPlayer,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.create_new_folder_outlined, size: 16),
            label: Text(AppLocalizations.of(context)!.addSubfolder),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: () =>
                _showAddSubFolderDialog(context, parentFolder, folderProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSubFolderWidget(
    BuildContext context,
    Folder subfolder,
    FolderProvider folderProvider,
    SongProvider songProvider,
    MusicPlayer musicPlayer,
  ) {
    final folderSongs =
        songProvider.songs
            .where((song) => subfolder.songIds.contains(song.id))
            .toList()
          ..sort(
            (a, b) => subfolder.songIds
                .indexOf(a.id)
                .compareTo(subfolder.songIds.indexOf(b.id)),
          );

    final bool isFolderNfcConnected = subfolder.connectedNfcUuid != null;
    final bool isFolderPlaylistActive =
        musicPlayer.isPlaylistMode &&
        musicPlayer.currentPlaylistFolderId == subfolder.id;
    final bool isQCSelected = _quickConnectSelectedFolderId == subfolder.id;
    final bool isQCFlash = _quickConnectFlashSuccessIds.contains(subfolder.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: isQCFlash
            ? Colors.green.withValues(alpha: 0.15)
            : Provider.of<ThemeProvider>(context).footerColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isQCFlash
              ? Colors.green
              : isQCSelected
              ? Theme.of(context).colorScheme.primary
              : isFolderPlaylistActive
              ? Colors.green
              : Provider.of<ThemeProvider>(
                  context,
                ).bannerColor.withValues(alpha: 0.2),
          width: isQCFlash || isQCSelected || isFolderPlaylistActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Subfolder header
          InkWell(
            onTap: _quickConnectMode
                ? () {
                    setState(() {
                      if (_quickConnectSelectedFolderId == subfolder.id) {
                        _quickConnectSelectedFolderId = null;
                      } else {
                        _quickConnectSelectedFolderId = subfolder.id;
                        _quickConnectSelectedSongId = null;
                      }
                    });
                  }
                : () => folderProvider.toggleFolderExpansion(subfolder.id),
            onLongPress: () => _showFolderActionsDialog(
              context,
              subfolder,
              folderProvider,
              musicPlayer,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: subfolder.isExpanded
                    ? Provider.of<ThemeProvider>(
                        context,
                      ).bannerColor.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    subfolder.isExpanded ? Icons.folder_open : Icons.folder,
                    color: Provider.of<ThemeProvider>(context).bannerColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subfolder.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Provider.of<ThemeProvider>(context).bannerColor,
                      ),
                    ),
                  ),
                  if (isFolderNfcConnected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.nfc,
                        size: 14,
                        color: Provider.of<ThemeProvider>(
                          context,
                        ).bannerColor.withValues(alpha: 0.6),
                      ),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        folderProvider.toggleFolderExpansion(subfolder.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        subfolder.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Provider.of<ThemeProvider>(context).bannerColor,
                        size: 20,
                      ),
                    ),
                  ),
                  if (!_quickConnectMode)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isFolderPlaylistActive) {
                          if (musicPlayer.isPlaying) {
                            musicPlayer.pauseMusic();
                          } else {
                            musicPlayer.resumeMusic();
                          }
                        } else if (folderSongs.isNotEmpty) {
                          musicPlayer.startPlaylist(
                            songs: folderSongs,
                            folderId: subfolder.id,
                            shuffle: subfolder.isShuffleEnabled,
                            loopPlaylist: subfolder.isLoopPlaylistEnabled,
                            startIndex: subfolder.lastPlayedSongIndex,
                            startPositionMs:
                                subfolder.lastPlayedPositionMs ?? 0,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          isFolderPlaylistActive && musicPlayer.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: isFolderPlaylistActive
                              ? Colors.green
                              : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Subfolder content (songs)
          if (subfolder.isExpanded)
            LayoutBuilder(
              builder: (context, constraints) {
                const double maxTileExtent = 250;
                const double spacing = 8;
                final int columns = (constraints.maxWidth / maxTileExtent)
                    .ceil()
                    .clamp(1, 100);
                final double tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final double tileHeight = tileWidth / 2.8;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (folderSongs.isNotEmpty)
                      GridView.extent(
                        maxCrossAxisExtent: maxTileExtent,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 2.8,
                        padding: const EdgeInsets.only(top: 8, bottom: spacing),
                        children: folderSongs.map((song) {
                          final bool isQCSongSelected =
                              _quickConnectSelectedSongId == song.id;
                          final bool isQCSongFlash =
                              _quickConnectFlashSuccessIds.contains(song.id);
                          return GestureDetector(
                            onTap: _quickConnectMode
                                ? () {
                                    setState(() {
                                      if (_quickConnectSelectedSongId ==
                                          song.id) {
                                        _quickConnectSelectedSongId = null;
                                      } else {
                                        _quickConnectSelectedSongId = song.id;
                                        _quickConnectSelectedFolderId = null;
                                      }
                                    });
                                  }
                                : null,
                            onLongPress: _quickConnectMode
                                ? null
                                : () {
                                    _showSongActionsDialog(
                                      context,
                                      song,
                                      subfolder.id,
                                      folderProvider,
                                      songProvider,
                                    );
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isQCSongFlash
                                    ? Colors.green.withValues(alpha: 0.25)
                                    : isQCSongSelected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : Provider.of<ThemeProvider>(
                                        context,
                                      ).bannerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: isQCSongFlash
                                    ? Border.all(color: Colors.green, width: 3)
                                    : isQCSongSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      )
                                    : song.connectedNfcUuid != null
                                    ? Border.all(color: Colors.green, width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(
                                    song.connectedNfcUuid != null
                                        ? Icons.music_note
                                        : Icons.music_off,
                                    size: 18,
                                    color: song.connectedNfcUuid != null
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      song.title,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!_quickConnectMode)
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      icon: Icon(
                                        musicPlayer.isSongPlaying(song.filePath)
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 20,
                                        color:
                                            musicPlayer.isSongPlaying(
                                              song.filePath,
                                            )
                                            ? Colors.red
                                            : musicPlayer.isSongPaused(
                                                song.filePath,
                                              )
                                            ? Colors.orange
                                            : Colors.blue,
                                      ),
                                      onPressed: () async {
                                        if (musicPlayer.isSongPlaying(
                                              song.filePath,
                                            ) ||
                                            musicPlayer.isSongPaused(
                                              song.filePath,
                                            )) {
                                          await musicPlayer.togglePlayPause();
                                        } else {
                                          await musicPlayer.playMusic(song);
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: tileWidth,
                            height: tileHeight,
                            child: _buildAddSongGridTile(
                              context,
                              songProvider,
                              subfolder.id,
                            ),
                          ),
                          const SizedBox(width: spacing),
                          SizedBox(
                            width: tileWidth,
                            height: tileHeight,
                            child: _buildAddMultipleGridTile(
                              context,
                              songProvider,
                              subfolder.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddSubFolderDialog(
    BuildContext context,
    Folder parentFolder,
    FolderProvider folderProvider,
  ) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.addSubfolder),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(dialogContext)!.folderName,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                folderProvider.addSubFolder(
                  parentFolder.id,
                  Folder(id: const Uuid().v4(), name: name),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: Text(AppLocalizations.of(dialogContext)!.create),
          ),
        ],
      ),
    );
  }

  /// Converts an existing leaf folder (with songs) into a group by wrapping its
  /// songs inside a new subfolder. The user chooses the subfolder name.
  void _showConvertToGroupDialog(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
  ) {
    // Pre-fill with the folder's own name as a sensible default
    final nameController = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.convertToGroup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(dialogContext)!.convertToGroupDescription),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(dialogContext)!.subfolderName,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              // 1. Create the new subfolder with the same song list
              final newSubfolder = Folder(
                id: const Uuid().v4(),
                name: name,
                songIds: List<String>.from(folder.songIds),
                isShuffleEnabled: folder.isShuffleEnabled,
                isLoopPlaylistEnabled: folder.isLoopPlaylistEnabled,
                nfcSkipsToNext: folder.nfcSkipsToNext,
                connectedNfcUuid: folder.connectedNfcUuid,
                parentFolderId: folder.id,
              );
              folderProvider.addSubFolder(folder.id, newSubfolder);

              // 2. Remove all songs from the parent folder and clear its NFC
              //    (songs now live in the subfolder)
              final clearedFolder = folder.copyWith(
                songIds: [],
                connectedNfcUuid: () => null,
              );
              folderProvider.updateFolder(clearedFolder);

              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(dialogContext)!.convert),
          ),
        ],
      ),
    );
  }

  void _showFolderActionsDialog(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
    MusicPlayer musicPlayer,
  ) {
    final nfcService = Provider.of<NFCService>(context, listen: false);
    // A folder is a group if it already has children OR if it is a root folder
    // with no songs yet (candidate to become a group).
    final bool isGroup = folderProvider.isGroupFolder(folder.id);
    // Root folders with no songs can still get a subfolder added.
    final bool canAddSubfolder =
        folder.parentFolderId == null && folder.songIds.isEmpty;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  folder.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(AppLocalizations.of(context)!.edit),
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      _showEditFolderDialog(context, folder, folderProvider);
                    }
                  },
                ),
                // "Add Subfolder" – visible for empty root folders or existing groups
                if (isGroup || canAddSubfolder)
                  ListTile(
                    leading: const Icon(Icons.create_new_folder_outlined),
                    title: Text(AppLocalizations.of(context)!.addSubfolder),
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (context.mounted) {
                        _showAddSubFolderDialog(
                          context,
                          folder,
                          folderProvider,
                        );
                      }
                    },
                  ),
                // "Convert to Group" – visible for root leaf folders that already
                // have songs (lets the user wrap existing songs in a subfolder)
                if (!isGroup &&
                    folder.parentFolderId == null &&
                    folder.songIds.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: Text(AppLocalizations.of(context)!.convertToGroup),
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (context.mounted) {
                        _showConvertToGroupDialog(
                          context,
                          folder,
                          folderProvider,
                        );
                      }
                    },
                  ),
                if (nfcService.isNfcAvailable)
                  ListTile(
                    leading: Icon(
                      Icons.nfc,
                      color: folder.connectedNfcUuid != null
                          ? Colors.green
                          : null,
                    ),
                    title: Text(
                      folder.connectedNfcUuid != null
                          ? AppLocalizations.of(context)!.disconnectNfc
                          : AppLocalizations.of(context)!.connectNfc,
                    ),
                    subtitle: folder.connectedNfcUuid != null
                        ? Text(
                            AppLocalizations.of(context)!.assignedNfc(
                              folder.connectedNfcUuid!.substring(
                                0,
                                folder.connectedNfcUuid!.length.clamp(0, 8),
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (context.mounted) {
                        if (folder.connectedNfcUuid != null) {
                          folderProvider.disconnectFolderFromNfc(folder.id);
                        } else {
                          _showFolderNfcDialog(context, folder, folderProvider);
                        }
                      }
                    },
                  ),
                // Playback toggles: only for leaf folders (not group folders)
                if (!isGroup) ...[
                  ListTile(
                    leading: const Icon(Icons.shuffle),
                    title: Text(AppLocalizations.of(context)!.shufflePlayback),
                    trailing: Switch(
                      value: folder.isShuffleEnabled,
                      onChanged: (value) {
                        folderProvider.updateFolderShuffle(folder.id, value);
                        if (musicPlayer.isPlaylistMode &&
                            musicPlayer.currentPlaylistFolderId == folder.id) {
                          musicPlayer.setShuffleEnabled(value);
                        }
                        final updatedFolder = folderProvider.folders.firstWhere(
                          (f) => f.id == folder.id,
                        );
                        setModalState(() {
                          folder = updatedFolder;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: Text(AppLocalizations.of(context)!.loopPlaylist),
                    trailing: Switch(
                      value: folder.isLoopPlaylistEnabled,
                      onChanged: (value) {
                        folderProvider.updateFolderLoop(folder.id, value);
                        if (musicPlayer.isPlaylistMode &&
                            musicPlayer.currentPlaylistFolderId == folder.id) {
                          musicPlayer.setLoopPlaylistEnabled(value);
                        }
                        final updatedFolder = folderProvider.folders.firstWhere(
                          (f) => f.id == folder.id,
                        );
                        setModalState(() {
                          folder = updatedFolder;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.skip_next),
                    title: Text(AppLocalizations.of(context)!.nfcSkipsToNext),
                    trailing: Switch(
                      value: folder.nfcSkipsToNext,
                      onChanged: (value) {
                        folderProvider.updateFolderNfcSkipsToNext(
                          folder.id,
                          value,
                        );
                        final updatedFolder = folderProvider.folders.firstWhere(
                          (f) => f.id == folder.id,
                        );
                        setModalState(() {
                          folder = updatedFolder;
                        });
                      },
                    ),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      _showDeleteFolderDialog(context, folder, folderProvider);
                    }
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFolderNfcDialog(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
  ) {
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );

    nfcService.setEditMode(true);

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? detectedUuid;
        bool isConnecting = false; // Prevent double-click issues
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            // Listen for NFC changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (nfcService.currentNfcUuid != null &&
                  nfcService.currentNfcUuid != detectedUuid) {
                setState(() {
                  detectedUuid = nfcService.currentNfcUuid;
                });
              }
            });

            return ListenableBuilder(
              listenable: nfcService,
              builder: (context, _) {
                final currentUuid = nfcService.currentNfcUuid;

                return AlertDialog(
                  title: Text(
                    AppLocalizations.of(dialogContext)!.scanNfcForFolder,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          dialogContext,
                        )!.holdNfcTagNearDevice,
                      ),
                      const SizedBox(height: 16),
                      if (currentUuid != null) ...[
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
                                AppLocalizations.of(
                                  dialogContext,
                                )!.newNfcDetected(
                                  currentUuid.substring(
                                    0,
                                    currentUuid.length.clamp(0, 8),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: isConnecting
                                    ? null
                                    : () async {
                                        setState(() => isConnecting = true);
                                        // Check conflicts: song in same folder with this UUID
                                        Song? conflictingSong;
                                        try {
                                          conflictingSong = songProvider.songs
                                              .firstWhere(
                                                (s) =>
                                                    s.connectedNfcUuid ==
                                                        currentUuid &&
                                                    folder.songIds.contains(
                                                      s.id,
                                                    ),
                                              );
                                        } catch (_) {
                                          conflictingSong = null;
                                        }

                                        // Check conflicts: another folder with this UUID
                                        Folder? conflictingFolder;
                                        try {
                                          conflictingFolder = folderProvider
                                              .folders
                                              .firstWhere(
                                                (f) =>
                                                    f.connectedNfcUuid ==
                                                        currentUuid &&
                                                    f.id != folder.id,
                                              );
                                        } catch (_) {
                                          conflictingFolder = null;
                                        }

                                        bool shouldConnect = true;

                                        if (conflictingSong != null &&
                                            dialogContext.mounted) {
                                          shouldConnect =
                                              await showDialog<bool>(
                                                context: dialogContext,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    AppLocalizations.of(
                                                      dialogContext,
                                                    )!.nfcTagAlreadyConnected,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.nfcAlreadyConnectedToSongInFolder,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '"${conflictingSong!.title}"',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnectionQuestion,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(false),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.keepExisting,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(true),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnection,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;

                                          if (shouldConnect) {
                                            songProvider.disconnectSongFromNfc(
                                              conflictingSong.id,
                                            );
                                            mappingProvider.removeMapping(
                                              conflictingSong.id,
                                            );
                                          }
                                        }

                                        if (conflictingFolder != null &&
                                            shouldConnect &&
                                            dialogContext.mounted) {
                                          shouldConnect =
                                              await showDialog<bool>(
                                                context: dialogContext,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    AppLocalizations.of(
                                                      dialogContext,
                                                    )!.nfcTagAlreadyConnected,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.nfcAlreadyConnectedToFolder,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '"${conflictingFolder!.name}"',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnectionQuestion,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(false),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.keepExisting,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(true),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          dialogContext,
                                                        )!.replaceConnection,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;

                                          if (shouldConnect) {
                                            folderProvider
                                                .disconnectFolderFromNfc(
                                                  conflictingFolder.id,
                                                );
                                          }
                                        }

                                        if (shouldConnect) {
                                          folderProvider.connectFolderToNfc(
                                            folder.id,
                                            currentUuid,
                                          );
                                          // Clear UUID to prevent duplicate conflict dialogs
                                          // from NFC service notifications during edit mode
                                          nfcService.clearCurrentNfcUuid();
                                          nfcService.setEditMode(false);
                                          if (dialogContext.mounted) {
                                            Navigator.of(dialogContext).pop();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.folderNfcConnected,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                        if (dialogContext.mounted) {
                                          setState(() => isConnecting = false);
                                        }
                                      },
                                child: Text(
                                  AppLocalizations.of(
                                    dialogContext,
                                  )!.useThisNfc,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          nfcService.isScanning
                              ? AppLocalizations.of(
                                  dialogContext,
                                )!.scanningForNfc
                              : AppLocalizations.of(
                                  dialogContext,
                                )!.waitingForNfc,
                          style: TextStyle(
                            color: nfcService.isScanning
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        nfcService.clearCurrentNfcUuid();
                        nfcService.setEditMode(false);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(AppLocalizations.of(dialogContext)!.cancel),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditFolderDialog(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: folder.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.folderName,
              ),
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
                final updatedFolder = folder.copyWith(
                  name: nameController.text,
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

  void _showDeleteFolderDialog(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
  ) {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );

    final bool isGroup = folderProvider.isGroupFolder(folder.id);
    final List<Folder> children = isGroup
        ? folderProvider.getChildFolders(folder.id)
        : [];
    // Collect all song IDs across all children (for group) or this folder (for leaf)
    final List<String> allSongIds = isGroup
        ? children.expand((c) => c.songIds).toList()
        : folder.songIds;

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
            Text(
              '${AppLocalizations.of(context)!.folderName}: ${folder.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isGroup) ...[
              Text(
                AppLocalizations.of(
                  context,
                )!.deleteGroupWarning(children.length, allSongIds.length),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(
                  context,
                )!.songsInFolder(folder.songIds.length),
              ),
            ],
            if (allSongIds.isNotEmpty) ...[
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
              // Delete all songs (from children for group, or from folder for leaf)
              for (final songId in allSongIds) {
                try {
                  final song = songProvider.songs.firstWhere(
                    (s) => s.id == songId,
                  );
                  mappingProvider.removeMapping(song.id);
                  if (song.filePath.isNotEmpty) {
                    final file = File(song.filePath);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  }
                  songProvider.removeSong(song.id);
                } catch (e) {
                  debugPrint(
                    '⚠️ Error deleting song $songId during folder deletion: $e',
                  );
                }
              }

              // Remove folder (and its children if group) from provider
              await folderProvider.removeFolder(folder.id);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context)!.deleteAll,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSongActionsDialog(
    BuildContext context,
    Song song,
    String currentFolderId,
    FolderProvider folderProvider,
    SongProvider songProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.songActions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.move_to_inbox),
                title: Text(AppLocalizations.of(context)!.moveToFolder),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _showMoveCopySongDialog(
                      context,
                      song,
                      currentFolderId,
                      folderProvider,
                      songProvider,
                      isCopy: false,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(AppLocalizations.of(context)!.copyToFolder),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _showMoveCopySongDialog(
                      context,
                      song,
                      currentFolderId,
                      folderProvider,
                      songProvider,
                      isCopy: true,
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.editSong),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _showSongDialog(context, songProvider, song: song);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.deleteSong,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _showDeleteSongDialog(context, song, songProvider);
                  }
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveCopySongDialog(
    BuildContext context,
    Song song,
    String currentFolderId,
    FolderProvider folderProvider,
    SongProvider songProvider, {
    required bool isCopy,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCopy
                    ? AppLocalizations.of(context)!.copySongToFolder
                    : AppLocalizations.of(context)!.moveSongToFolder,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...folderProvider.folders
                  // Only show leaf folders (no children) as move/copy targets
                  .where((folder) => !folderProvider.isGroupFolder(folder.id))
                  .map((folder) {
                    if (folder.id == currentFolderId)
                      return const SizedBox.shrink();
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      subtitle: folder.parentFolderId != null
                          ? Text(
                              folderProvider.folders
                                      .firstWhereOrNull(
                                        (f) => f.id == folder.parentFolderId,
                                      )
                                      ?.name ??
                                  '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                      onTap: () async {
                        final result = isCopy
                            ? await folderProvider.copySongToFolder(
                                song.id,
                                folder.id,
                                songProvider.songs,
                              )
                            : await folderProvider.moveSongToFolder(
                                song.id,
                                currentFolderId,
                                folder.id,
                                songProvider.songs,
                              );

                        if (!context.mounted) return;

                        if (result.success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isCopy
                                    ? AppLocalizations.of(
                                        context,
                                      )!.songCopiedToFolder(folder.name)
                                    : AppLocalizations.of(
                                        context,
                                      )!.songMovedToFolder(folder.name),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (result.reason ==
                            MoveFailureReason.songLimit) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.songLimitReached,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (result.reason ==
                            MoveFailureReason.duplicate) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Song already exists in "${folder.name}"',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else if (result.reason ==
                            MoveFailureReason.nfcConflict) {
                          Navigator.pop(context);
                          _showNfcConflictDialog(
                            context,
                            song,
                            folder.id,
                            result.conflictingSongId!,
                            currentFolderId,
                            folderProvider,
                            songProvider,
                            isCopy: isCopy,
                          );
                        }
                      },
                    );
                  }),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNfcConflictDialog(
    BuildContext context,
    Song song,
    String targetFolderId,
    String conflictingSongId,
    String currentFolderId,
    FolderProvider folderProvider,
    SongProvider songProvider, {
    bool isCopy = false,
  }) {
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );
    final conflictingSong = songProvider.songs.firstWhereOrNull(
      (s) => s.id == conflictingSongId,
    );
    final targetFolder = folderProvider.folders.firstWhereOrNull(
      (f) => f.id == targetFolderId,
    );

    // Safety check - should never happen but prevents crashes
    if (conflictingSong == null || targetFolder == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.nfcConflictDetected),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.nfcConflictDescription),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(
                context,
              )!.nfcTagId(song.connectedNfcUuid!.substring(0, 8)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.existingSongInFolder),
            const SizedBox(height: 4),
            Text(
              '"${conflictingSong.title}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.whatWouldYouLikeToDo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Move/Copy without NFC - remove NFC from the moved/copied song
              songProvider.disconnectSongFromNfc(song.id);
              mappingProvider.removeMapping(song.id);

              final result = isCopy
                  ? await folderProvider.copySongToFolder(
                      song.id,
                      targetFolderId,
                      songProvider.songs,
                    )
                  : await folderProvider.moveSongToFolder(
                      song.id,
                      currentFolderId,
                      targetFolderId,
                      songProvider.songs,
                    );

              if (!context.mounted) return;

              if (result.success) {
                // Close dialogs safely
                final navigator = Navigator.of(context);
                navigator.pop(); // Close conflict dialog
                if (context.mounted) {
                  navigator.pop(); // Close folder selection dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isCopy
                            ? AppLocalizations.of(
                                context,
                              )!.songCopiedToFolder(targetFolder.name)
                            : AppLocalizations.of(
                                context,
                              )!.songMovedToFolder(targetFolder.name),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.moveWithoutNfc),
          ),
          ElevatedButton(
            onPressed: () async {
              // Replace NFC - remove NFC from existing song and keep on moved/copied song
              songProvider.disconnectSongFromNfc(conflictingSongId);
              mappingProvider.removeMapping(conflictingSongId);

              final result = isCopy
                  ? await folderProvider.copySongToFolder(
                      song.id,
                      targetFolderId,
                      songProvider.songs,
                    )
                  : await folderProvider.moveSongToFolder(
                      song.id,
                      currentFolderId,
                      targetFolderId,
                      songProvider.songs,
                    );

              if (!context.mounted) return;

              if (result.success) {
                // Close dialogs safely
                final navigator = Navigator.of(context);
                navigator.pop(); // Close conflict dialog
                if (context.mounted) {
                  navigator.pop(); // Close folder selection dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isCopy
                            ? AppLocalizations.of(
                                context,
                              )!.songCopiedToFolder(targetFolder.name)
                            : AppLocalizations.of(
                                context,
                              )!.songMovedToFolder(targetFolder.name),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.replaceNfcConnection),
          ),
        ],
      ),
    );
  }

  void _showDeleteSongDialog(
    BuildContext context,
    Song song,
    SongProvider songProvider,
  ) {
    final mappingProvider = Provider.of<NFCMusicMappingProvider>(
      context,
      listen: false,
    );
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);

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
            Text(
              '${AppLocalizations.of(context)!.title}: ${song.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (song.connectedNfcUuid != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                  context,
                )!.nfcMappingRemoved(song.connectedNfcUuid!),
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

              // Remove song from folder's songIds list
              try {
                final folder = folderProvider.folders.firstWhere(
                  (f) => f.songIds.contains(song.id),
                );
                folderProvider.removeSongFromFolder(folder.id, song.id);
                debugPrint(
                  '🗑️ Removed song ${song.id} from folder ${folder.id}',
                );
              } catch (_) {
                debugPrint('⚠️ Song ${song.id} not found in any folder');
              }

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
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
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
              Text(
                AppLocalizations.of(context)!.storageServiceStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• ${AppLocalizations.of(context)!.initialized(storageService.isInitialized)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.platform(Platform.operatingSystem)}',
              ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.storageStatistics,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...storageService.getStorageStats().entries.map(
                (entry) => Text('• ${entry.key}: ${entry.value}'),
              ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.iapPremiumStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (AppConfig.isGooglePlayRelease) ...[
                Text(
                  '• ${AppLocalizations.of(context)!.premiumStatus(IAPService.instance.isPremium)}',
                ),
              ] else ...[
                Text('• ${AppLocalizations.of(context)!.premiumNotAvailable}'),
              ],
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.actions,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      storageService.debugStorageStatus();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.storageDebugInfoLogged,
                          ),
                        ),
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
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.storageReinitialized,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.reinitializationFailed(e),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.forceReinitialize,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await storageService.clearAllData();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.allStorageDataCleared,
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.clearFailed(e),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.clearAllData),
                  ),
                  if (AppConfig.isGooglePlayRelease) ...[
                    ElevatedButton(
                      onPressed: () {
                        debugPrint(
                          '💾 IAP Premium Status: ${IAPService.instance.isPremium}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.premiumStatus(IAPService.instance.isPremium),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.logPremiumStatus,
                      ),
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
                            SnackBar(
                              content: Text(localizations.clearPremiumStatus),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(localizations.clearFailed(e)),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clearPremiumStatus,
                      ),
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
              Text(
                AppLocalizations.of(context)!.nfcServiceStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• ${AppLocalizations.of(context)!.nfcAvailable(nfcService.isNfcAvailable)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.nfcScanning(nfcService.isScanning)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.currentUuid(nfcService.currentNfcUuid ?? "None")}',
              ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.musicPlayerStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• ${AppLocalizations.of(context)!.currentState(musicPlayer.currentState)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.isPlaying(musicPlayer.isPlaying)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.isPaused(musicPlayer.isPaused)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.currentFile(musicPlayer.currentMusicFilePath ?? "None")}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.position(musicPlayer.savedPosition)}',
              ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.songsMappings,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• ${AppLocalizations.of(context)!.totalSongs(songProvider.songs.length)}',
              ),
              for (int i = 0; i < songProvider.songs.length; i++)
                Text(
                  '• ${AppLocalizations.of(context)!.songWithUuid(i, songProvider.songs[i].title, songProvider.songs[i].connectedNfcUuid ?? "None")}',
                ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.flavorInformation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• ${AppLocalizations.of(context)!.githubRelease(AppConfig.isGitHubRelease)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.fdroidRelease(AppConfig.isFdroidRelease)}',
              ),
              Text(
                '• ${AppLocalizations.of(context)!.googlePlayRelease(AppConfig.isGooglePlayRelease)}',
              ),
              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.actions,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final debugInfo = nfcService.getDebugInfo();
                      debugPrint('📊 NFC Debug Info: $debugInfo');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.debugInfoLogged,
                          ),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.logDebugInfo),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      musicPlayer.simulateStateTest();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.stateTestLogged,
                          ),
                        ),
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
                          SnackBar(
                            content: Text(
                              nfcService.isScanning
                                  ? AppLocalizations.of(
                                      context,
                                    )!.nfcScanningStarted
                                  : AppLocalizations.of(
                                      context,
                                    )!.nfcScanningStopped,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.nfcOperationFailed(e),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      nfcService.isScanning
                          ? AppLocalizations.of(context)!.stopNfc
                          : AppLocalizations.of(context)!.startNfc,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      nfcService.forceProcessCurrentUuid();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.forceProcessedUuid,
                          ),
                        ),
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
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.tutorialReset,
                              ),
                            ),
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

        final folderProvider = Provider.of<FolderProvider>(
          context,
          listen: false,
        );
        final targets = createTutorialTargets(
          context: context,
          addFolderButtonKey: folderProvider.folders.isEmpty
              ? _addFolderButtonKey
              : null,
          addSongButtonKey: folderProvider.folders.isNotEmpty
              ? _addSongButtonKey
              : null,
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToOpenLink(e.toString()),
            ),
          ),
        );
      }
    }
  }
}

class _DialogState {
  bool isOpen = true;
}
