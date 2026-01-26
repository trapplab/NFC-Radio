import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC Radio'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @audioPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Packs'**
  String get audioPacksTitle;

  /// No description provided for @audioStarterPacks.
  ///
  /// In en, this message translates to:
  /// **'Audio Starter Packs'**
  String get audioStarterPacks;

  /// No description provided for @browseAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Browse audio files only'**
  String get browseAudioOnly;

  /// No description provided for @filterAudio.
  ///
  /// In en, this message translates to:
  /// **'Filter: audio/*'**
  String get filterAudio;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'Filter: */*'**
  String get filterAll;

  /// No description provided for @useKioskMode.
  ///
  /// In en, this message translates to:
  /// **'Use kiosk mode'**
  String get useKioskMode;

  /// No description provided for @requiresSystemAlertPermission.
  ///
  /// In en, this message translates to:
  /// **'Requires SYSTEM_ALERT_WINDOW permission'**
  String get requiresSystemAlertPermission;

  /// No description provided for @nfcNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device.'**
  String get nfcNotAvailable;

  /// No description provided for @readyToScanNfc.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan NFC tags'**
  String get readyToScanNfc;

  /// No description provided for @scanningForNfc.
  ///
  /// In en, this message translates to:
  /// **'Scanning for NFC tags...'**
  String get scanningForNfc;

  /// No description provided for @scanningPaused.
  ///
  /// In en, this message translates to:
  /// **'Scanning paused'**
  String get scanningPaused;

  /// No description provided for @startScanning.
  ///
  /// In en, this message translates to:
  /// **'Start Scanning'**
  String get startScanning;

  /// No description provided for @stopScanning.
  ///
  /// In en, this message translates to:
  /// **'Stop Scanning'**
  String get stopScanning;

  /// No description provided for @noFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet. Create a folder to organize your songs!'**
  String get noFoldersYet;

  /// No description provided for @addNewFolder.
  ///
  /// In en, this message translates to:
  /// **'Add New Folder'**
  String get addNewFolder;

  /// No description provided for @addAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Add Audio File'**
  String get addAudioFile;

  /// No description provided for @addNewSong.
  ///
  /// In en, this message translates to:
  /// **'Add New Song'**
  String get addNewSong;

  /// No description provided for @editSong.
  ///
  /// In en, this message translates to:
  /// **'Edit Song'**
  String get editSong;

  /// No description provided for @playbackOptions.
  ///
  /// In en, this message translates to:
  /// **'Playback Options'**
  String get playbackOptions;

  /// No description provided for @loopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Loop playback'**
  String get loopPlayback;

  /// No description provided for @rememberPosition.
  ///
  /// In en, this message translates to:
  /// **'Remember position'**
  String get rememberPosition;

  /// No description provided for @nfcConfiguration.
  ///
  /// In en, this message translates to:
  /// **'NFC Configuration'**
  String get nfcConfiguration;

  /// No description provided for @nfcAssignedReady.
  ///
  /// In en, this message translates to:
  /// **'NFC is assigned and ready'**
  String get nfcAssignedReady;

  /// No description provided for @waitingForNfc.
  ///
  /// In en, this message translates to:
  /// **'Waiting for NFC tag...'**
  String get waitingForNfc;

  /// No description provided for @newNfcDetected.
  ///
  /// In en, this message translates to:
  /// **'New NFC detected: {nfcId}...'**
  String newNfcDetected(Object nfcId);

  /// No description provided for @useThisNfc.
  ///
  /// In en, this message translates to:
  /// **'Use This NFC'**
  String get useThisNfc;

  /// No description provided for @nfcTagAlreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'NFC Tag Already Connected'**
  String get nfcTagAlreadyConnected;

  /// No description provided for @nfcAlreadyConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'This NFC tag is already connected to:'**
  String get nfcAlreadyConnectedTo;

  /// No description provided for @replaceConnectionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to replace the connection?'**
  String get replaceConnectionQuestion;

  /// No description provided for @keepExisting.
  ///
  /// In en, this message translates to:
  /// **'Keep Existing'**
  String get keepExisting;

  /// No description provided for @replaceConnection.
  ///
  /// In en, this message translates to:
  /// **'Replace Connection'**
  String get replaceConnection;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @editFolder.
  ///
  /// In en, this message translates to:
  /// **'Edit Folder'**
  String get editFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// No description provided for @deleteSong.
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSong;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @audioSource.
  ///
  /// In en, this message translates to:
  /// **'Audio Source'**
  String get audioSource;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @areYouSureDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this folder?'**
  String get areYouSureDeleteFolder;

  /// No description provided for @songsInFolder.
  ///
  /// In en, this message translates to:
  /// **'Songs in folder: {count}'**
  String songsInFolder(Object count);

  /// No description provided for @noteDeleteSongs.
  ///
  /// In en, this message translates to:
  /// **'Note: All songs in this folder and their audio files will also be deleted.'**
  String get noteDeleteSongs;

  /// No description provided for @areYouSureDeleteSong.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this song?'**
  String get areYouSureDeleteSong;

  /// No description provided for @nfcMappingRemoved.
  ///
  /// In en, this message translates to:
  /// **'This will also remove the NFC mapping for: {nfcId}'**
  String nfcMappingRemoved(Object nfcId);

  /// No description provided for @audioFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'The audio file will also be deleted from the app storage.'**
  String get audioFileDeleted;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @freeVersionLimit.
  ///
  /// In en, this message translates to:
  /// **'In the free version you can add up to 2 folders with 6 audio files each.'**
  String get freeVersionLimit;

  /// No description provided for @upgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to unlock unlimited folders and audio files, and support the developers!'**
  String get upgradeToUnlock;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @storageDebug.
  ///
  /// In en, this message translates to:
  /// **'🗄️ Storage Debug'**
  String get storageDebug;

  /// No description provided for @storageServiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Storage Service Status:'**
  String get storageServiceStatus;

  /// No description provided for @initialized.
  ///
  /// In en, this message translates to:
  /// **'Initialized: {status}'**
  String initialized(Object status);

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform: {platform}'**
  String platform(Object platform);

  /// No description provided for @storageStatistics.
  ///
  /// In en, this message translates to:
  /// **'Storage Statistics:'**
  String get storageStatistics;

  /// No description provided for @iapPremiumStatus.
  ///
  /// In en, this message translates to:
  /// **'IAP/Premium Status:'**
  String get iapPremiumStatus;

  /// No description provided for @premiumStatus.
  ///
  /// In en, this message translates to:
  /// **'Premium: {status}'**
  String premiumStatus(Object status);

  /// No description provided for @premiumNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Premium: N/A (non-GP flavor)'**
  String get premiumNotAvailable;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions:'**
  String get actions;

  /// No description provided for @logDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'Log Debug Info'**
  String get logDebugInfo;

  /// No description provided for @forceReinitialize.
  ///
  /// In en, this message translates to:
  /// **'Force Reinitialize'**
  String get forceReinitialize;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @logPremiumStatus.
  ///
  /// In en, this message translates to:
  /// **'Log Premium Status'**
  String get logPremiumStatus;

  /// No description provided for @clearPremiumStatus.
  ///
  /// In en, this message translates to:
  /// **'Clear Premium Status'**
  String get clearPremiumStatus;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @debugInformation.
  ///
  /// In en, this message translates to:
  /// **'🔍 Debug Information'**
  String get debugInformation;

  /// No description provided for @nfcServiceStatus.
  ///
  /// In en, this message translates to:
  /// **'NFC Service Status:'**
  String get nfcServiceStatus;

  /// No description provided for @nfcAvailable.
  ///
  /// In en, this message translates to:
  /// **'NFC Available: {status}'**
  String nfcAvailable(Object status);

  /// No description provided for @nfcScanning.
  ///
  /// In en, this message translates to:
  /// **'NFC Scanning: {status}'**
  String nfcScanning(Object status);

  /// No description provided for @currentUuid.
  ///
  /// In en, this message translates to:
  /// **'Current UUID: {uuid}'**
  String currentUuid(Object uuid);

  /// No description provided for @musicPlayerStatus.
  ///
  /// In en, this message translates to:
  /// **'Music Player Status:'**
  String get musicPlayerStatus;

  /// No description provided for @currentState.
  ///
  /// In en, this message translates to:
  /// **'Current State: {state}'**
  String currentState(Object state);

  /// No description provided for @isPlaying.
  ///
  /// In en, this message translates to:
  /// **'Is Playing: {status}'**
  String isPlaying(Object status);

  /// No description provided for @isPaused.
  ///
  /// In en, this message translates to:
  /// **'Is Paused: {status}'**
  String isPaused(Object status);

  /// No description provided for @currentFile.
  ///
  /// In en, this message translates to:
  /// **'Current File: {file}'**
  String currentFile(Object file);

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position: {position}'**
  String position(Object position);

  /// No description provided for @songsMappings.
  ///
  /// In en, this message translates to:
  /// **'Songs & Mappings:'**
  String get songsMappings;

  /// No description provided for @totalSongs.
  ///
  /// In en, this message translates to:
  /// **'Total Songs: {count}'**
  String totalSongs(Object count);

  /// No description provided for @songWithUuid.
  ///
  /// In en, this message translates to:
  /// **'Song {index}: {title} (UUID: {uuid})'**
  String songWithUuid(Object index, Object title, Object uuid);

  /// No description provided for @flavorInformation.
  ///
  /// In en, this message translates to:
  /// **'Flavor Information:'**
  String get flavorInformation;

  /// No description provided for @githubRelease.
  ///
  /// In en, this message translates to:
  /// **'GitHub Release: {status}'**
  String githubRelease(Object status);

  /// No description provided for @fdroidRelease.
  ///
  /// In en, this message translates to:
  /// **'F-Droid Release: {status}'**
  String fdroidRelease(Object status);

  /// No description provided for @googlePlayRelease.
  ///
  /// In en, this message translates to:
  /// **'Google Play Release: {status}'**
  String googlePlayRelease(Object status);

  /// No description provided for @testPlayerState.
  ///
  /// In en, this message translates to:
  /// **'Test Player State'**
  String get testPlayerState;

  /// No description provided for @forceProcessUuid.
  ///
  /// In en, this message translates to:
  /// **'Force Process UUID'**
  String get forceProcessUuid;

  /// No description provided for @resetTutorial.
  ///
  /// In en, this message translates to:
  /// **'Reset Tutorial'**
  String get resetTutorial;

  /// No description provided for @importQuestion.
  ///
  /// In en, this message translates to:
  /// **'Import \"{name}\"?'**
  String importQuestion(Object name);

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'This will download {count} audio files and create a new folder.'**
  String importDescription(Object count);

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @downloadingAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'Downloading audio files...'**
  String get downloadingAudioFiles;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported \"{name}\"'**
  String importSuccess(Object name);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import any files from \"{name}\"'**
  String importFailed(Object name);

  /// No description provided for @partialImport.
  ///
  /// In en, this message translates to:
  /// **'Partial Import'**
  String get partialImport;

  /// No description provided for @importedFiles.
  ///
  /// In en, this message translates to:
  /// **'Imported {success} files, but {failed} files failed to download:'**
  String importedFiles(Object failed, Object success);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @failedToImport.
  ///
  /// In en, this message translates to:
  /// **'Failed to import folder: {error}'**
  String failedToImport(Object error);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update v{version} available'**
  String updateAvailable(Object version);

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available on GitHub.'**
  String get newVersionAvailable;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog:'**
  String get changelog;

  /// No description provided for @noChangelog.
  ///
  /// In en, this message translates to:
  /// **'No changelog provided.'**
  String get noChangelog;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadUpdate;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version.'**
  String get latestVersion;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Error checking for updates: {error}'**
  String updateCheckFailed(Object error);

  /// No description provided for @loadedData.
  ///
  /// In en, this message translates to:
  /// **'🎵 Loaded your saved songs, folders, and NFC mappings!'**
  String get loadedData;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Failed to load saved data. App will work with empty data.'**
  String get failedToLoadData;

  /// No description provided for @couldNotLoadTemplates.
  ///
  /// In en, this message translates to:
  /// **'Could not load templates.'**
  String get couldNotLoadTemplates;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @nfcLinkedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'🔗 NFC tag linked automatically'**
  String get nfcLinkedAutomatically;

  /// No description provided for @audioSelected.
  ///
  /// In en, this message translates to:
  /// **'📥 Audio selected: {name}'**
  String audioSelected(Object name);

  /// No description provided for @rejectedInvalidAudio.
  ///
  /// In en, this message translates to:
  /// **'❌ Rejected: Selected file is not a valid audio file.'**
  String get rejectedInvalidAudio;

  /// No description provided for @cannotSaveInvalidAudio.
  ///
  /// In en, this message translates to:
  /// **'❌ Cannot save: File is not a valid audio file.'**
  String get cannotSaveInvalidAudio;

  /// No description provided for @failedToLaunchAudioPicker.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to launch audio picker'**
  String get failedToLaunchAudioPicker;

  /// No description provided for @nfcTagLinked.
  ///
  /// In en, this message translates to:
  /// **'🔗 NFC tag linked automatically'**
  String get nfcTagLinked;

  /// No description provided for @storageReinitialized.
  ///
  /// In en, this message translates to:
  /// **'Storage reinitialized'**
  String get storageReinitialized;

  /// No description provided for @reinitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Reinitialization failed: {error}'**
  String reinitializationFailed(Object error);

  /// No description provided for @allStorageDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All storage data cleared'**
  String get allStorageDataCleared;

  /// No description provided for @clearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed: {error}'**
  String clearFailed(Object error);

  /// No description provided for @storageDebugInfoLogged.
  ///
  /// In en, this message translates to:
  /// **'Storage debug info logged to console'**
  String get storageDebugInfoLogged;

  /// No description provided for @debugInfoLogged.
  ///
  /// In en, this message translates to:
  /// **'Debug info logged to console'**
  String get debugInfoLogged;

  /// No description provided for @stateTestLogged.
  ///
  /// In en, this message translates to:
  /// **'State test logged to console'**
  String get stateTestLogged;

  /// No description provided for @nfcOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'NFC operation failed: {error}'**
  String nfcOperationFailed(Object error);

  /// No description provided for @forceProcessedUuid.
  ///
  /// In en, this message translates to:
  /// **'Force processed current UUID'**
  String get forceProcessedUuid;

  /// No description provided for @tutorialReset.
  ///
  /// In en, this message translates to:
  /// **'Tutorial reset - will show on next restart'**
  String get tutorialReset;

  /// No description provided for @failedToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to open link: {error}'**
  String failedToOpenLink(Object error);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
