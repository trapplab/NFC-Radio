// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NFC Radio';

  @override
  String get appVersion => 'App Version';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get audioPacksTitle => 'Audio Packs';

  @override
  String get audioStarterPacks => 'Audio Starter Packs';

  @override
  String get browseAudioOnly => 'Browse audio files only';

  @override
  String get filterAudio => 'Filter: audio/*';

  @override
  String get filterAll => 'Filter: */*';

  @override
  String get useKioskMode => 'Use kiosk mode';

  @override
  String get requiresSystemAlertPermission => 'Requires SYSTEM_ALERT_WINDOW permission';

  @override
  String get nfcNotAvailable => 'NFC is not available on this device.';

  @override
  String get readyToScanNfc => 'Ready to scan NFC tags';

  @override
  String get scanningForNfc => 'Scanning for NFC tags...';

  @override
  String get scanningPaused => 'Scanning paused';

  @override
  String get startScanning => 'Start Scanning';

  @override
  String get stopScanning => 'Stop Scanning';

  @override
  String get noFoldersYet => 'No folders yet. Create a folder to organize your songs!';

  @override
  String get addNewFolder => 'Add New Folder';

  @override
  String get addAudioFile => 'Add Audio File';

  @override
  String get addNewSong => 'Add New Song';

  @override
  String get editSong => 'Edit Song';

  @override
  String get playbackOptions => 'Playback Options';

  @override
  String get loopPlayback => 'Loop playback';

  @override
  String get rememberPosition => 'Remember position';

  @override
  String get nfcConfiguration => 'NFC Configuration';

  @override
  String get nfcAssignedReady => 'NFC is assigned and ready';

  @override
  String get waitingForNfc => 'Waiting for NFC tag...';

  @override
  String newNfcDetected(Object nfcId) {
    return 'New NFC detected: $nfcId...';
  }

  @override
  String get useThisNfc => 'Use This NFC';

  @override
  String get nfcTagAlreadyConnected => 'NFC Tag Already Connected';

  @override
  String get nfcAlreadyConnectedTo => 'This NFC tag is already connected to:';

  @override
  String get replaceConnectionQuestion => 'Do you want to replace the connection?';

  @override
  String get keepExisting => 'Keep Existing';

  @override
  String get replaceConnection => 'Replace Connection';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get editFolder => 'Edit Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get deleteSong => 'Delete Song';

  @override
  String get folderName => 'Folder Name';

  @override
  String get audioSource => 'Audio Source';

  @override
  String get title => 'Title';

  @override
  String get areYouSureDeleteFolder => 'Are you sure you want to delete this folder?';

  @override
  String songsInFolder(Object count) {
    return 'Songs in folder: $count';
  }

  @override
  String get noteDeleteSongs => 'Note: All songs in this folder and their audio files will also be deleted.';

  @override
  String get areYouSureDeleteSong => 'Are you sure you want to delete this song?';

  @override
  String nfcMappingRemoved(Object nfcId) {
    return 'This will also remove the NFC mapping for: $nfcId';
  }

  @override
  String get audioFileDeleted => 'The audio file will also be deleted from the app storage.';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get freeVersionLimit => 'In the free version you can add up to 2 folders with 6 audio files each.';

  @override
  String get upgradeToUnlock => 'Upgrade to Premium to unlock unlimited folders and audio files, and support the developers!';

  @override
  String get later => 'Later';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get storageDebug => '🗄️ Storage Debug';

  @override
  String get storageServiceStatus => 'Storage Service Status:';

  @override
  String initialized(Object status) {
    return 'Initialized: $status';
  }

  @override
  String platform(Object platform) {
    return 'Platform: $platform';
  }

  @override
  String get storageStatistics => 'Storage Statistics:';

  @override
  String get iapPremiumStatus => 'IAP/Premium Status:';

  @override
  String premiumStatus(Object status) {
    return 'Premium: $status';
  }

  @override
  String get premiumNotAvailable => 'Premium: N/A (non-GP flavor)';

  @override
  String get actions => 'Actions:';

  @override
  String get logDebugInfo => 'Log Debug Info';

  @override
  String get forceReinitialize => 'Force Reinitialize';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get logPremiumStatus => 'Log Premium Status';

  @override
  String get clearPremiumStatus => 'Clear Premium Status';

  @override
  String get close => 'Close';

  @override
  String get debugInformation => '🔍 Debug Information';

  @override
  String get nfcServiceStatus => 'NFC Service Status:';

  @override
  String nfcAvailable(Object status) {
    return 'NFC Available: $status';
  }

  @override
  String nfcScanning(Object status) {
    return 'NFC Scanning: $status';
  }

  @override
  String currentUuid(Object uuid) {
    return 'Current UUID: $uuid';
  }

  @override
  String get musicPlayerStatus => 'Music Player Status:';

  @override
  String currentState(Object state) {
    return 'Current State: $state';
  }

  @override
  String isPlaying(Object status) {
    return 'Is Playing: $status';
  }

  @override
  String isPaused(Object status) {
    return 'Is Paused: $status';
  }

  @override
  String currentFile(Object file) {
    return 'Current File: $file';
  }

  @override
  String position(Object position) {
    return 'Position: $position';
  }

  @override
  String get songsMappings => 'Songs & Mappings:';

  @override
  String totalSongs(Object count) {
    return 'Total Songs: $count';
  }

  @override
  String songWithUuid(Object index, Object title, Object uuid) {
    return 'Song $index: $title (UUID: $uuid)';
  }

  @override
  String get flavorInformation => 'Flavor Information:';

  @override
  String githubRelease(Object status) {
    return 'GitHub Release: $status';
  }

  @override
  String fdroidRelease(Object status) {
    return 'F-Droid Release: $status';
  }

  @override
  String googlePlayRelease(Object status) {
    return 'Google Play Release: $status';
  }

  @override
  String get testPlayerState => 'Test Player State';

  @override
  String get forceProcessUuid => 'Force Process UUID';

  @override
  String get resetTutorial => 'Reset Tutorial';

  @override
  String importQuestion(Object name) {
    return 'Import \"$name\"?';
  }

  @override
  String importDescription(Object count) {
    return 'This will download $count audio files and create a new folder.';
  }

  @override
  String get importButton => 'Import';

  @override
  String get downloadingAudioFiles => 'Downloading audio files...';

  @override
  String importSuccess(Object name) {
    return 'Successfully imported \"$name\"';
  }

  @override
  String importFailed(Object name) {
    return 'Failed to import any files from \"$name\"';
  }

  @override
  String get partialImport => 'Partial Import';

  @override
  String importedFiles(Object failed, Object success) {
    return 'Imported $success files, but $failed files failed to download:';
  }

  @override
  String get ok => 'OK';

  @override
  String failedToImport(Object error) {
    return 'Failed to import folder: $error';
  }

  @override
  String updateAvailable(Object version) {
    return 'Update v$version available';
  }

  @override
  String get newVersionAvailable => 'A new version is available on GitHub.';

  @override
  String get changelog => 'Changelog:';

  @override
  String get noChangelog => 'No changelog provided.';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get latestVersion => 'You are on the latest version.';

  @override
  String updateCheckFailed(Object error) {
    return 'Error checking for updates: $error';
  }

  @override
  String get loadedData => '🎵 Loaded your saved songs, folders, and NFC mappings!';

  @override
  String get failedToLoadData => '⚠️ Failed to load saved data. App will work with empty data.';

  @override
  String get couldNotLoadTemplates => 'Could not load templates.';

  @override
  String get retry => 'Retry';

  @override
  String get nfcLinkedAutomatically => '🔗 NFC tag linked automatically';

  @override
  String audioSelected(Object name) {
    return '📥 Audio selected: $name';
  }

  @override
  String get rejectedInvalidAudio => '❌ Rejected: Selected file is not a valid audio file.';

  @override
  String get cannotSaveInvalidAudio => '❌ Cannot save: File is not a valid audio file.';

  @override
  String get failedToLaunchAudioPicker => '❌ Failed to launch audio picker';

  @override
  String get nfcTagLinked => '🔗 NFC tag linked automatically';

  @override
  String get storageReinitialized => 'Storage reinitialized';

  @override
  String reinitializationFailed(Object error) {
    return 'Reinitialization failed: $error';
  }

  @override
  String get allStorageDataCleared => 'All storage data cleared';

  @override
  String clearFailed(Object error) {
    return 'Clear failed: $error';
  }

  @override
  String get storageDebugInfoLogged => 'Storage debug info logged to console';

  @override
  String get debugInfoLogged => 'Debug info logged to console';

  @override
  String get stateTestLogged => 'State test logged to console';

  @override
  String nfcOperationFailed(Object error) {
    return 'NFC operation failed: $error';
  }

  @override
  String get forceProcessedUuid => 'Force processed current UUID';

  @override
  String get tutorialReset => 'Tutorial reset - will show on next restart';

  @override
  String failedToOpenLink(Object error) {
    return '❌ Failed to open link: $error';
  }
}
