// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'NFC Radio';

  @override
  String get appVersion => 'App-Version';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get audioPacksTitle => 'Audio-Pakete';

  @override
  String get audioStarterPacks => 'Audio-Starterpakete';

  @override
  String get browseAudioOnly => 'Nur Audiodateien durchsuchen';

  @override
  String get filterAudio => 'Filter: audio/*';

  @override
  String get filterAll => 'Filter: */*';

  @override
  String get useKioskMode => 'Kiosk-Modus verwenden';

  @override
  String get requiresSystemAlertPermission => 'Benötigt SYSTEM_ALERT_WINDOW-Berechtigung';

  @override
  String get nfcNotAvailable => 'NFC ist auf diesem Gerät nicht verfügbar.';

  @override
  String get readyToScanNfc => 'Bereit zum Scannen von NFC-Tags';

  @override
  String get scanningForNfc => 'Scanne nach NFC-Tags...';

  @override
  String get scanningPaused => 'Scannen pausiert';

  @override
  String get startScanning => 'Scannen starten';

  @override
  String get stopScanning => 'Scannen stoppen';

  @override
  String get noFoldersYet => 'Noch keine Ordner. Erstellen Sie einen Ordner, um Ihre Lieder zu organisieren!';

  @override
  String get addNewFolder => 'Neuen Ordner hinzufügen';

  @override
  String get addAudioFile => 'Audiodatei hinzufügen';

  @override
  String get addNewSong => 'Neues Lied hinzufügen';

  @override
  String get editSong => 'Lied bearbeiten';

  @override
  String get playbackOptions => 'Wiedergabeoptionen';

  @override
  String get loopPlayback => 'Wiedergabe wiederholen';

  @override
  String get rememberPosition => 'Position merken';

  @override
  String get nfcConfiguration => 'NFC-Konfiguration';

  @override
  String get nfcAssignedReady => 'NFC ist zugewiesen und bereit';

  @override
  String get waitingForNfc => 'Warte auf NFC-Tag...';

  @override
  String newNfcDetected(Object nfcId) {
    return 'Neuer NFC erkannt: $nfcId...';
  }

  @override
  String get useThisNfc => 'Diesen NFC verwenden';

  @override
  String get nfcTagAlreadyConnected => 'NFC-Tag bereits verbunden';

  @override
  String get nfcAlreadyConnectedTo => 'Dieser NFC-Tag ist bereits verbunden mit:';

  @override
  String get replaceConnectionQuestion => 'Möchten Sie die Verbindung ersetzen?';

  @override
  String get keepExisting => 'Bestehende behalten';

  @override
  String get replaceConnection => 'Verbindung ersetzen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get create => 'Erstellen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAll => 'Alles löschen';

  @override
  String get editFolder => 'Ordner bearbeiten';

  @override
  String get deleteFolder => 'Ordner löschen';

  @override
  String get deleteSong => 'Lied löschen';

  @override
  String get folderName => 'Ordnername';

  @override
  String get audioSource => 'Audioquelle';

  @override
  String get title => 'Titel';

  @override
  String get areYouSureDeleteFolder => 'Sind Sie sicher, dass Sie diesen Ordner löschen möchten?';

  @override
  String songsInFolder(Object count) {
    return 'Lieder im Ordner: $count';
  }

  @override
  String get noteDeleteSongs => 'Hinweis: Alle Lieder in diesem Ordner und ihre Audiodateien werden ebenfalls gelöscht.';

  @override
  String get areYouSureDeleteSong => 'Sind Sie sicher, dass Sie dieses Lied löschen möchten?';

  @override
  String nfcMappingRemoved(Object nfcId) {
    return 'Dies entfernt auch die NFC-Zuordnung für: $nfcId';
  }

  @override
  String get audioFileDeleted => 'Die Audiodatei wird ebenfalls aus dem App-Speicher gelöscht.';

  @override
  String get upgradeToPremium => 'Auf Premium upgraden';

  @override
  String get freeVersionLimit => 'In der kostenlosen Version können Sie bis zu 2 Ordner mit jeweils 6 Audiodateien hinzufügen.';

  @override
  String get upgradeToUnlock => 'Upgraden Sie auf Premium, um unbegrenzte Ordner und Audiodateien freizuschalten und die Entwickler zu unterstützen!';

  @override
  String get later => 'Später';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get storageDebug => '🗄️ Speicher-Debug';

  @override
  String get storageServiceStatus => 'Speicherdienststatus:';

  @override
  String initialized(Object status) {
    return 'Initialisiert: $status';
  }

  @override
  String platform(Object platform) {
    return 'Plattform: $platform';
  }

  @override
  String get storageStatistics => 'Speicherstatistiken:';

  @override
  String get iapPremiumStatus => 'IAP/Premium-Status:';

  @override
  String premiumStatus(Object status) {
    return 'Premium: $status';
  }

  @override
  String get premiumNotAvailable => 'Premium: Nicht verfügbar (keine GP-Version)';

  @override
  String get actions => 'Aktionen:';

  @override
  String get logDebugInfo => 'Debug-Info protokollieren';

  @override
  String get forceReinitialize => 'Erneutes Initialisieren erzwingen';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get logPremiumStatus => 'Premium-Status protokollieren';

  @override
  String get clearPremiumStatus => 'Premium-Status löschen';

  @override
  String get close => 'Schließen';

  @override
  String get debugInformation => '🔍 Debug-Informationen';

  @override
  String get nfcServiceStatus => 'NFC-Dienststatus:';

  @override
  String nfcAvailable(Object status) {
    return 'NFC verfügbar: $status';
  }

  @override
  String nfcScanning(Object status) {
    return 'NFC-Scan: $status';
  }

  @override
  String currentUuid(Object uuid) {
    return 'Aktuelle UUID: $uuid';
  }

  @override
  String get musicPlayerStatus => 'Musikplayer-Status:';

  @override
  String currentState(Object state) {
    return 'Aktueller Status: $state';
  }

  @override
  String isPlaying(Object status) {
    return 'Wird abgespielt: $status';
  }

  @override
  String isPaused(Object status) {
    return 'Pausiert: $status';
  }

  @override
  String currentFile(Object file) {
    return 'Aktuelle Datei: $file';
  }

  @override
  String position(Object position) {
    return 'Position: $position';
  }

  @override
  String get songsMappings => 'Lieder & Zuordnungen:';

  @override
  String totalSongs(Object count) {
    return 'Gesamtlieder: $count';
  }

  @override
  String songWithUuid(Object index, Object title, Object uuid) {
    return 'Lied $index: $title (UUID: $uuid)';
  }

  @override
  String get flavorInformation => 'Flavor-Informationen:';

  @override
  String githubRelease(Object status) {
    return 'GitHub-Version: $status';
  }

  @override
  String fdroidRelease(Object status) {
    return 'F-Droid-Version: $status';
  }

  @override
  String googlePlayRelease(Object status) {
    return 'Google Play-Version: $status';
  }

  @override
  String get testPlayerState => 'Player-Status testen';

  @override
  String get forceProcessUuid => 'UUID-Verarbeitung erzwingen';

  @override
  String get resetTutorial => 'Tutorial zurücksetzen';

  @override
  String importQuestion(Object name) {
    return '\"$name\" importieren?';
  }

  @override
  String importDescription(Object count) {
    return 'Dies wird $count Audiodateien herunterladen und einen neuen Ordner erstellen.';
  }

  @override
  String get importButton => 'Importieren';

  @override
  String get downloadingAudioFiles => 'Audiodateien werden heruntergeladen...';

  @override
  String importSuccess(Object name) {
    return '\"$name\" erfolgreich importiert';
  }

  @override
  String importFailed(Object name) {
    return 'Konnte keine Dateien aus \"$name\" importieren';
  }

  @override
  String get partialImport => 'Teilweiser Import';

  @override
  String importedFiles(Object failed, Object success) {
    return '$success Dateien importiert, aber $failed Dateien konnten nicht heruntergeladen werden:';
  }

  @override
  String get ok => 'OK';

  @override
  String failedToImport(Object error) {
    return 'Fehler beim Importieren des Ordners: $error';
  }

  @override
  String updateAvailable(Object version) {
    return 'Update v$version verfügbar';
  }

  @override
  String get newVersionAvailable => 'Eine neue Version ist auf GitHub verfügbar.';

  @override
  String get changelog => 'Änderungsprotokoll:';

  @override
  String get noChangelog => 'Kein Änderungsprotokoll verfügbar.';

  @override
  String get downloadUpdate => 'Herunterladen';

  @override
  String get latestVersion => 'Sie haben die neueste Version.';

  @override
  String updateCheckFailed(Object error) {
    return 'Fehler beim Überprüfen auf Updates: $error';
  }

  @override
  String get loadedData => '🎵 Ihre gespeicherten Lieder, Ordner und NFC-Zuordnungen wurden geladen!';

  @override
  String get failedToLoadData => '⚠️ Fehler beim Laden der gespeicherten Daten. Die App wird mit leeren Daten funktionieren.';

  @override
  String get couldNotLoadTemplates => 'Konnte Vorlagen nicht laden.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get nfcLinkedAutomatically => '🔗 NFC-Tag automatisch verknüpft';

  @override
  String audioSelected(Object name) {
    return '📥 Audio ausgewählt: $name';
  }

  @override
  String get rejectedInvalidAudio => '❌ Abgelehnt: Die ausgewählte Datei ist keine gültige Audiodatei.';

  @override
  String get cannotSaveInvalidAudio => '❌ Kann nicht speichern: Datei ist keine gültige Audiodatei.';

  @override
  String get failedToLaunchAudioPicker => '❌ Fehler beim Starten des Audio-Auswahlprogramms';

  @override
  String get nfcTagLinked => '🔗 NFC-Tag automatisch verknüpft';

  @override
  String get storageReinitialized => 'Speicher neu initialisiert';

  @override
  String reinitializationFailed(Object error) {
    return 'Neuinitialisierung fehlgeschlagen: $error';
  }

  @override
  String get allStorageDataCleared => 'Alle Speicherdaten gelöscht';

  @override
  String clearFailed(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get storageDebugInfoLogged => 'Speicher-Debug-Info in der Konsole protokolliert';

  @override
  String get debugInfoLogged => 'Debug-Info in der Konsole protokolliert';

  @override
  String get stateTestLogged => 'Status-Test in der Konsole protokolliert';

  @override
  String nfcOperationFailed(Object error) {
    return 'NFC-Operation fehlgeschlagen: $error';
  }

  @override
  String get forceProcessedUuid => 'Aktuelle UUID erzwungen verarbeitet';

  @override
  String get tutorialReset => 'Tutorial zurückgesetzt - wird beim nächsten Neustart angezeigt';

  @override
  String failedToOpenLink(Object error) {
    return '❌ Fehler beim Öffnen des Links: $error';
  }

  @override
  String get slideToLock => 'Schieben zum Sperren';

  @override
  String get screenLocked => 'Bildschirm gesperrt';

  @override
  String get swipeUpToUnlock => 'Mit 3 Fingern nach oben wischen zum Entsperren';

  @override
  String get tutorialAddFolderTitle => 'Musiksammlungen erstellen';

  @override
  String get tutorialAddFolderDesc => 'Tippen Sie auf \"Neuen Ordner hinzufügen\", um Ordner zu erstellen und Ihre Audiodateisammlung zu organisieren.';

  @override
  String get tutorialAddSongTitle => 'Ihre Lieder hinzufügen';

  @override
  String get tutorialAddSongDesc => 'Sobald ein Ordner erstellt wurde, tippen Sie auf \"Audiodatei hinzufügen\", um Audiodateien von Ihrem Gerät auszuwählen.';

  @override
  String get tutorialAttachFileTitle => 'Audiodatei auswählen';

  @override
  String get tutorialAttachFileDesc => 'Tippen Sie auf das Büroklammer-Symbol, um eine Audiodatei von Ihrem Gerät auszuwählen.';

  @override
  String get tutorialConnectNfcTitle => 'NFC-Tag verbinden';

  @override
  String get tutorialConnectNfcDesc => 'Halten Sie einen beliebigen NFC-Tag an die Rückseite Ihres Telefons, bis es vibriert, um den Tag mit der Audiodatei für die Wiedergabe zu verbinden.';

  @override
  String get tutorialSettingsTitle => 'Einstellungen & Starter-Pakete';

  @override
  String get tutorialSettingsDesc => 'Öffnen Sie das Einstellungsmenü, um Audio-Starterpakete und andere Optionen zu finden.';

  @override
  String get limitReached => 'Limit erreicht';

  @override
  String get folderLimitReached => 'Sie haben das Limit von 2 Ordnern erreicht. Um mehr hinzuzufügen, aktualisieren Sie bitte auf die Premium-Version.';

  @override
  String get songLimitReached => 'Sie haben das Limit von 6 Liedern pro Ordner erreicht. Um mehr hinzuzufügen, aktualisieren Sie bitte auf die Premium-Version.';

  @override
  String get themeColor => 'Themenfarbe';

  @override
  String lastDetected(Object uuid) {
    return 'Zuletzt erkannt: $uuid';
  }

  @override
  String nowPlaying(Object title) {
    return 'Aktuelle Wiedergabe: $title';
  }

  @override
  String positionWithTotal(Object current, Object total) {
    return 'Position: $current / $total';
  }

  @override
  String assignedNfc(Object id) {
    return 'Zugewiesener NFC: $id...';
  }

  @override
  String get edit => 'Bearbeiten';

  @override
  String get connected => 'Verbunden';

  @override
  String get nfcScanningStarted => 'NFC-Scan gestartet';

  @override
  String get nfcScanningStopped => 'NFC-Scan gestoppt';

  @override
  String get stopNfc => 'NFC stoppen';

  @override
  String get startNfc => 'NFC starten';

  @override
  String storageError(Object error, Object operation) {
    return 'Speicherfehler: Fehler bei $operation. Fehler: $error';
  }

  @override
  String get white => 'Weiß';

  @override
  String get cappuccino => 'Cappuccino';

  @override
  String get black => 'Schwarz';

  @override
  String get needNfcTagsTitle => 'Ein paar Extras gefällig?';
  
  @override
  String get songActions => 'Lied-Aktionen';

  @override
  String get moveToFolder => 'In Ordner verschieben...';

  @override
  String get copyToFolder => 'In Ordner kopieren...';

  @override
  String get moveSongToFolder => 'Lied in Ordner verschieben';

  @override
  String get copySongToFolder => 'Lied in Ordner kopieren';

  @override
  String songMovedToFolder(Object folderName) {
    return 'Lied in \"$folderName\" verschoben';
  }

  @override
  String songCopiedToFolder(Object folderName) {
    return 'Lied in \"$folderName\" kopiert';
  }

  @override
  String get nfcConflictDetected => 'NFC-Konflikt erkannt';

  @override
  String get nfcConflictDescription => 'Der Zielordner enthält bereits ein Lied, das mit demselben NFC-Tag verbunden ist.';

  @override
  String nfcTagId(Object nfcId) {
    return 'NFC-Tag: $nfcId...';
  }

  @override
  String get existingSongInFolder => 'Vorhandenes Lied im Ordner:';

  @override
  String get whatWouldYouLikeToDo => 'Was möchten Sie tun?';

  @override
  String get moveWithoutNfc => 'Verschieben/Kopieren ohne NFC';

  @override
  String get replaceNfcConnection => 'NFC-Verbindung ersetzen';
}
