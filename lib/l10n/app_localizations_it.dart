// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'NFC Radio';

  @override
  String get appVersion => 'Versione dell\'applicazione';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get audioPacksTitle => 'Pacchetti audio';

  @override
  String get audioStarterPacks => 'Pacchetti audio di avvio';

  @override
  String get browseAudioOnly => 'Sfoglia solo file audio';

  @override
  String get filterAudio => 'Filtro: audio/*';

  @override
  String get filterAll => 'Filtro: */*';

  @override
  String get useKioskMode => 'Usa modalità chiosco';

  @override
  String get requiresSystemAlertPermission => 'Richiede il permesso SYSTEM_ALERT_WINDOW';

  @override
  String get nfcNotAvailable => 'NFC non è disponibile su questo dispositivo.';

  @override
  String get readyToScanNfc => 'Pronto per scansionare tag NFC';

  @override
  String get scanningForNfc => 'Scansione di tag NFC...';

  @override
  String get scanningPaused => 'Scansione in pausa';

  @override
  String get startScanning => 'Avvia scansione';

  @override
  String get stopScanning => 'Ferma scansione';

  @override
  String get noFoldersYet => 'Nessuna cartella ancora. Crea una cartella per organizzare le tue canzoni!';

  @override
  String get addNewFolder => 'Aggiungi nuova cartella';

  @override
  String get addAudioFile => 'Aggiungi file audio';

  @override
  String get addNewSong => 'Aggiungi nuova canzone';

  @override
  String get editSong => 'Modifica canzone';

  @override
  String get playbackOptions => 'Opzioni di riproduzione';

  @override
  String get loopPlayback => 'Riproduzione in loop';

  @override
  String get rememberPosition => 'Ricorda posizione';

  @override
  String get nfcConfiguration => 'Configurazione NFC';

  @override
  String get nfcAssignedReady => 'NFC è assegnato e pronto';

  @override
  String get waitingForNfc => 'In attesa di tag NFC...';

  @override
  String newNfcDetected(Object nfcId) {
    return 'Nuovo NFC rilevato: $nfcId...';
  }

  @override
  String get useThisNfc => 'Usa questo NFC';

  @override
  String get nfcTagAlreadyConnected => 'Tag NFC già connesso';

  @override
  String get nfcAlreadyConnectedTo => 'Questo tag NFC è già connesso a:';

  @override
  String get replaceConnectionQuestion => 'Vuoi sostituire la connessione?';

  @override
  String get keepExisting => 'Mantieni esistente';

  @override
  String get replaceConnection => 'Sostituisci connessione';

  @override
  String get cancel => 'Annulla';

  @override
  String get create => 'Crea';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAll => 'Elimina tutto';

  @override
  String get editFolder => 'Modifica cartella';

  @override
  String get deleteFolder => 'Elimina cartella';

  @override
  String get deleteSong => 'Elimina canzone';

  @override
  String get folderName => 'Nome cartella';

  @override
  String get audioSource => 'Sorgente audio';

  @override
  String get title => 'Titolo';

  @override
  String get areYouSureDeleteFolder => 'Sei sicuro di voler eliminare questa cartella?';

  @override
  String songsInFolder(Object count) {
    return 'Canzoni nella cartella: $count';
  }

  @override
  String get noteDeleteSongs => 'Nota: Tutte le canzoni in questa cartella e i loro file audio verranno eliminati.';

  @override
  String get areYouSureDeleteSong => 'Sei sicuro di voler eliminare questa canzone?';

  @override
  String nfcMappingRemoved(Object nfcId) {
    return 'Questo rimuoverà anche la mappatura NFC per: $nfcId';
  }

  @override
  String get audioFileDeleted => 'Il file audio verrà eliminato anche dallo storage dell\'app.';

  @override
  String get upgradeToPremium => 'Passa a Premium';

  @override
  String get freeVersionLimit => 'Nella versione gratuita puoi aggiungere fino a 2 cartelle con 6 file audio ciascuna.';

  @override
  String get upgradeToUnlock => 'Passa a Premium per sbloccare cartelle e file audio illimitati e supportare gli sviluppatori!';

  @override
  String get later => 'Più tardi';

  @override
  String get upgrade => 'Aggiorna';

  @override
  String get storageDebug => '🗄️ Debug storage';

  @override
  String get storageServiceStatus => 'Stato del servizio di storage:';

  @override
  String initialized(Object status) {
    return 'Inizializzato: $status';
  }

  @override
  String platform(Object platform) {
    return 'Piattaforma: $platform';
  }

  @override
  String get storageStatistics => 'Statistiche di storage:';

  @override
  String get iapPremiumStatus => 'Stato IAP/Premium:';

  @override
  String premiumStatus(Object status) {
    return 'Premium: $status';
  }

  @override
  String get premiumNotAvailable => 'Premium: Non disponibile (versione non GP)';

  @override
  String get actions => 'Azioni:';

  @override
  String get logDebugInfo => 'Registra info di debug';

  @override
  String get forceReinitialize => 'Forza reinizializzazione';

  @override
  String get clearAllData => 'Cancella tutti i dati';

  @override
  String get logPremiumStatus => 'Registra stato premium';

  @override
  String get clearPremiumStatus => 'Cancella stato premium';

  @override
  String get close => 'Chiudi';

  @override
  String get debugInformation => '🔍 Informazioni di debug';

  @override
  String get nfcServiceStatus => 'Stato del servizio NFC:';

  @override
  String nfcAvailable(Object status) {
    return 'NFC disponibile: $status';
  }

  @override
  String nfcScanning(Object status) {
    return 'Scansione NFC: $status';
  }

  @override
  String currentUuid(Object uuid) {
    return 'UUID corrente: $uuid';
  }

  @override
  String get musicPlayerStatus => 'Stato del lettore musicale:';

  @override
  String currentState(Object state) {
    return 'Stato corrente: $state';
  }

  @override
  String isPlaying(Object status) {
    return 'In riproduzione: $status';
  }

  @override
  String isPaused(Object status) {
    return 'In pausa: $status';
  }

  @override
  String currentFile(Object file) {
    return 'File corrente: $file';
  }

  @override
  String position(Object position) {
    return 'Posizione: $position';
  }

  @override
  String get songsMappings => 'Canzoni e mappature:';

  @override
  String totalSongs(Object count) {
    return 'Totale canzoni: $count';
  }

  @override
  String songWithUuid(Object index, Object title, Object uuid) {
    return 'Canzone $index: $title (UUID: $uuid)';
  }

  @override
  String get flavorInformation => 'Informazioni sulla versione:';

  @override
  String githubRelease(Object status) {
    return 'Versione GitHub: $status';
  }

  @override
  String fdroidRelease(Object status) {
    return 'Versione F-Droid: $status';
  }

  @override
  String googlePlayRelease(Object status) {
    return 'Versione Google Play: $status';
  }

  @override
  String get testPlayerState => 'Testa stato del lettore';

  @override
  String get forceProcessUuid => 'Forza elaborazione UUID';

  @override
  String get resetTutorial => 'Reimposta tutorial';

  @override
  String importQuestion(Object name) {
    return 'Importare \"$name\"?';
  }

  @override
  String importDescription(Object count) {
    return 'Questo scaricherà $count file audio e creerà una nuova cartella.';
  }

  @override
  String get importButton => 'Importa';

  @override
  String get downloadingAudioFiles => 'Scaricamento file audio...';

  @override
  String importSuccess(Object name) {
    return '\"$name\" importato con successo';
  }

  @override
  String importFailed(Object name) {
    return 'Impossibile importare file da \"$name\"';
  }

  @override
  String get partialImport => 'Importazione parziale';

  @override
  String importedFiles(Object failed, Object success) {
    return 'Importati $success file, ma $failed file non sono stati scaricati:';
  }

  @override
  String get ok => 'OK';

  @override
  String failedToImport(Object error) {
    return 'Impossibile importare la cartella: $error';
  }

  @override
  String updateAvailable(Object version) {
    return 'Aggiornamento v$version disponibile';
  }

  @override
  String get newVersionAvailable => 'Una nuova versione è disponibile su GitHub.';

  @override
  String get changelog => 'Changelog:';

  @override
  String get noChangelog => 'Nessun changelog fornito.';

  @override
  String get downloadUpdate => 'Scarica';

  @override
  String get latestVersion => 'Hai l\'ultima versione.';

  @override
  String updateCheckFailed(Object error) {
    return 'Errore nel controllo degli aggiornamenti: $error';
  }

  @override
  String get loadedData => '🎵 Caricate le tue canzoni, cartelle e mappature NFC salvate!';

  @override
  String get failedToLoadData => '⚠️ Impossibile caricare i dati salvati. L\'app funzionerà con dati vuoti.';

  @override
  String get couldNotLoadTemplates => 'Impossibile caricare i modelli.';

  @override
  String get retry => 'Riprova';

  @override
  String get nfcLinkedAutomatically => '🔗 Tag NFC collegato automaticamente';

  @override
  String audioSelected(Object name) {
    return '📥 Audio selezionato: $name';
  }

  @override
  String get rejectedInvalidAudio => '❌ Rifiutato: Il file selezionato non è un file audio valido.';

  @override
  String get cannotSaveInvalidAudio => '❌ Impossibile salvare: Il file non è un file audio valido.';

  @override
  String get failedToLaunchAudioPicker => '❌ Impossibile avviare il selettore audio';

  @override
  String get nfcTagLinked => '🔗 Tag NFC collegato automaticamente';

  @override
  String get storageReinitialized => 'Storage reinizializzato';

  @override
  String reinitializationFailed(Object error) {
    return 'Reinizializzazione fallita: $error';
  }

  @override
  String get allStorageDataCleared => 'Tutti i dati di storage cancellati';

  @override
  String clearFailed(Object error) {
    return 'Cancellazione fallita: $error';
  }

  @override
  String get storageDebugInfoLogged => 'Info di debug del storage registrate nella console';

  @override
  String get debugInfoLogged => 'Info di debug registrate nella console';

  @override
  String get stateTestLogged => 'Test di stato registrato nella console';

  @override
  String nfcOperationFailed(Object error) {
    return 'Operazione NFC fallita: $error';
  }

  @override
  String get forceProcessedUuid => 'UUID corrente elaborato forzatamente';

  @override
  String get tutorialReset => 'Tutorial reimpostato - verrà mostrato al prossimo riavvio';

  @override
  String failedToOpenLink(Object error) {
    return '❌ Impossibile aprire il link: $error';
  }

  @override
  String get slideToLock => 'Scorri per bloccare';

  @override
  String get screenLocked => 'Schermo bloccato';

  @override
  String get swipeUpToUnlock => 'Scorri con 3 dita verso l\'alto per sbloccare';

  @override
  String get tutorialAddFolderTitle => 'Crea collezioni musicali';

  @override
  String get tutorialAddFolderDesc => 'Tocca \"Aggiungi nuova cartella\" per creare cartelle e organizzare la tua collezione di file audio.';

  @override
  String get tutorialAddSongTitle => 'Aggiungi le tue canzoni';

  @override
  String get tutorialAddSongDesc => 'Una volta creata una cartella, tocca \"Aggiungi file audio\" per selezionare i file audio dal tuo dispositivo.';

  @override
  String get tutorialAttachFileTitle => 'Seleziona file audio';

  @override
  String get tutorialAttachFileDesc => 'Tocca l\'icona della graffetta per selezionare un file audio dal tuo dispositivo.';

  @override
  String get tutorialConnectNfcTitle => 'Collega tag NFC';

  @override
  String get tutorialConnectNfcDesc => 'Avvicina un qualsiasi tag NFC al retro del tuo telefono finché non vibra per collegare il tag al file audio per la riproduzione.';

  @override
  String get tutorialSettingsTitle => 'Impostazioni e pacchetti di avvio';

  @override
  String get tutorialSettingsDesc => 'Apri il menu delle impostazioni per trovare i pacchetti audio di avvio e altre opzioni.';

  @override
  String get limitReached => 'Limite raggiunto';

  @override
  String get folderLimitReached => 'Hai raggiunto il limite di 2 cartelle. Per aggiungerne altre, esegui l\'upgrade alla versione premium.';

  @override
  String get songLimitReached => 'Hai raggiunto il limite di 6 brani per cartella. Per aggiungerne altri, esegui l\'upgrade alla versione premium.';

  @override
  String get themeColor => 'Colore del tema';

  @override
  String lastDetected(Object uuid) {
    return 'Ultimo rilevato: $uuid';
  }

  @override
  String nowPlaying(Object title) {
    return 'In riproduzione: $title';
  }

  @override
  String positionWithTotal(Object current, Object total) {
    return 'Posizione: $current / $total';
  }

  @override
  String assignedNfc(Object id) {
    return 'NFC assegnato: $id...';
  }

  @override
  String get edit => 'Modifica';

  @override
  String get connected => 'Connesso';

  @override
  String get nfcScanningStarted => 'Scansione NFC avviata';

  @override
  String get nfcScanningStopped => 'Scansione NFC interrotta';

  @override
  String get stopNfc => 'Ferma NFC';

  @override
  String get startNfc => 'Avvia NFC';

  @override
  String storageError(Object error, Object operation) {
    return 'Errore di archiviazione: Impossibile $operation. Errore: $error';
  }

  @override
  String get white => 'Bianco';

  @override
  String get cappuccino => 'Cappuccino';

  @override
  String get black => 'Nero';
}
