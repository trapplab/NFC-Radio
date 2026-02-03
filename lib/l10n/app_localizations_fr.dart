// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'NFC Radio';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get audioPacksTitle => 'Packs audio';

  @override
  String get audioStarterPacks => 'Packs de démarrage audio';

  @override
  String get browseAudioOnly => 'Parcourir uniquement les fichiers audio';

  @override
  String get filterAudio => 'Filtre: audio/*';

  @override
  String get filterAll => 'Filtre: */*';

  @override
  String get useKioskMode => 'Utiliser le mode kiosque';

  @override
  String get requiresSystemAlertPermission => 'Nécessite la permission SYSTEM_ALERT_WINDOW';

  @override
  String get nfcNotAvailable => 'Le NFC n\'est pas disponible sur cet appareil.';

  @override
  String get readyToScanNfc => 'Prêt à scanner les tags NFC';

  @override
  String get scanningForNfc => 'Recherche de tags NFC...';

  @override
  String get scanningPaused => 'Scan en pause';

  @override
  String get startScanning => 'Démarrer le scan';

  @override
  String get stopScanning => 'Arrêter le scan';

  @override
  String get noFoldersYet => 'Aucun dossier pour l\'instant. Créez un dossier pour organiser vos chansons!';

  @override
  String get addNewFolder => 'Ajouter un nouveau dossier';

  @override
  String get addAudioFile => 'Ajouter un fichier audio';

  @override
  String get addNewSong => 'Ajouter une nouvelle chanson';

  @override
  String get editSong => 'Modifier la chanson';

  @override
  String get playbackOptions => 'Options de lecture';

  @override
  String get loopPlayback => 'Lecture en boucle';

  @override
  String get rememberPosition => 'Mémoriser la position';

  @override
  String get nfcConfiguration => 'Configuration NFC';

  @override
  String get nfcAssignedReady => 'NFC est assigné et prêt';

  @override
  String get waitingForNfc => 'En attente de tag NFC...';

  @override
  String newNfcDetected(Object nfcId) {
    return 'Nouveau NFC détecté: $nfcId...';
  }

  @override
  String get useThisNfc => 'Utiliser ce NFC';

  @override
  String get nfcTagAlreadyConnected => 'Tag NFC déjà connecté';

  @override
  String get nfcAlreadyConnectedTo => 'Ce tag NFC est déjà connecté à:';

  @override
  String get replaceConnectionQuestion => 'Voulez-vous remplacer la connexion?';

  @override
  String get keepExisting => 'Conserver l\'existant';

  @override
  String get replaceConnection => 'Remplacer la connexion';

  @override
  String get cancel => 'Annuler';

  @override
  String get create => 'Créer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get editFolder => 'Modifier le dossier';

  @override
  String get deleteFolder => 'Supprimer le dossier';

  @override
  String get deleteSong => 'Supprimer la chanson';

  @override
  String get folderName => 'Nom du dossier';

  @override
  String get audioSource => 'Source audio';

  @override
  String get title => 'Titre';

  @override
  String get areYouSureDeleteFolder => 'Êtes-vous sûr de vouloir supprimer ce dossier?';

  @override
  String songsInFolder(Object count) {
    return 'Chansons dans le dossier: $count';
  }

  @override
  String get noteDeleteSongs => 'Note: Toutes les chansons dans ce dossier et leurs fichiers audio seront également supprimés.';

  @override
  String get areYouSureDeleteSong => 'Êtes-vous sûr de vouloir supprimer cette chanson?';

  @override
  String nfcMappingRemoved(Object nfcId) {
    return 'Cela supprimera également le mappage NFC pour: $nfcId';
  }

  @override
  String get audioFileDeleted => 'Le fichier audio sera également supprimé du stockage de l\'application.';

  @override
  String get upgradeToPremium => 'Passer à Premium';

  @override
  String get freeVersionLimit => 'Dans la version gratuite, vous pouvez ajouter jusqu\'à 2 dossiers avec 6 fichiers audio chacun.';

  @override
  String get upgradeToUnlock => 'Passez à Premium pour débloquer des dossiers et fichiers audio illimités, et soutenir les développeurs!';

  @override
  String get later => 'Plus tard';

  @override
  String get upgrade => 'Mettre à niveau';

  @override
  String get storageDebug => '🗄️ Débogage du stockage';

  @override
  String get storageServiceStatus => 'État du service de stockage:';

  @override
  String initialized(Object status) {
    return 'Initialisé: $status';
  }

  @override
  String platform(Object platform) {
    return 'Plateforme: $platform';
  }

  @override
  String get storageStatistics => 'Statistiques de stockage:';

  @override
  String get iapPremiumStatus => 'État IAP/Premium:';

  @override
  String premiumStatus(Object status) {
    return 'Premium: $status';
  }

  @override
  String get premiumNotAvailable => 'Premium: Non disponible (version non GP)';

  @override
  String get actions => 'Actions:';

  @override
  String get logDebugInfo => 'Journaliser les informations de débogage';

  @override
  String get forceReinitialize => 'Forcer la réinitialisation';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get logPremiumStatus => 'Journaliser l\'état premium';

  @override
  String get clearPremiumStatus => 'Effacer l\'état premium';

  @override
  String get close => 'Fermer';

  @override
  String get debugInformation => '🔍 Informations de débogage';

  @override
  String get nfcServiceStatus => 'État du service NFC:';

  @override
  String nfcAvailable(Object status) {
    return 'NFC disponible: $status';
  }

  @override
  String nfcScanning(Object status) {
    return 'Scan NFC: $status';
  }

  @override
  String currentUuid(Object uuid) {
    return 'UUID actuel: $uuid';
  }

  @override
  String get musicPlayerStatus => 'État du lecteur de musique:';

  @override
  String currentState(Object state) {
    return 'État actuel: $state';
  }

  @override
  String isPlaying(Object status) {
    return 'En lecture: $status';
  }

  @override
  String isPaused(Object status) {
    return 'En pause: $status';
  }

  @override
  String currentFile(Object file) {
    return 'Fichier actuel: $file';
  }

  @override
  String position(Object position) {
    return 'Position: $position';
  }

  @override
  String get songsMappings => 'Chansons et mappages:';

  @override
  String totalSongs(Object count) {
    return 'Total de chansons: $count';
  }

  @override
  String songWithUuid(Object index, Object title, Object uuid) {
    return 'Chanson $index: $title (UUID: $uuid)';
  }

  @override
  String get flavorInformation => 'Informations sur la version:';

  @override
  String githubRelease(Object status) {
    return 'Version GitHub: $status';
  }

  @override
  String fdroidRelease(Object status) {
    return 'Version F-Droid: $status';
  }

  @override
  String googlePlayRelease(Object status) {
    return 'Version Google Play: $status';
  }

  @override
  String get testPlayerState => 'Tester l\'état du lecteur';

  @override
  String get forceProcessUuid => 'Forcer le traitement de l\'UUID';

  @override
  String get resetTutorial => 'Réinitialiser le didacticiel';

  @override
  String importQuestion(Object name) {
    return 'Importer \"$name\"?';
  }

  @override
  String importDescription(Object count) {
    return 'Cela téléchargera $count fichiers audio et créera un nouveau dossier.';
  }

  @override
  String get importButton => 'Importer';

  @override
  String get downloadingAudioFiles => 'Téléchargement des fichiers audio...';

  @override
  String importSuccess(Object name) {
    return '\"$name\" importé avec succès';
  }

  @override
  String importFailed(Object name) {
    return 'Échec de l\'importation de fichiers depuis \"$name\"';
  }

  @override
  String get partialImport => 'Importation partielle';

  @override
  String importedFiles(Object failed, Object success) {
    return 'Fichiers importés: $success, mais $failed fichiers n\'ont pas pu être téléchargés:';
  }

  @override
  String get ok => 'OK';

  @override
  String failedToImport(Object error) {
    return 'Échec de l\'importation du dossier: $error';
  }

  @override
  String updateAvailable(Object version) {
    return 'Mise à jour v$version disponible';
  }

  @override
  String get newVersionAvailable => 'Une nouvelle version est disponible sur GitHub.';

  @override
  String get changelog => 'Journal des modifications:';

  @override
  String get noChangelog => 'Aucun journal des modifications fourni.';

  @override
  String get downloadUpdate => 'Télécharger';

  @override
  String get latestVersion => 'Vous avez la dernière version.';

  @override
  String updateCheckFailed(Object error) {
    return 'Erreur lors de la vérification des mises à jour: $error';
  }

  @override
  String get loadedData => '🎵 Vos chansons, dossiers et mappages NFC enregistrés ont été chargés!';

  @override
  String get failedToLoadData => '⚠️ Échec du chargement des données enregistrées. L\'application fonctionnera avec des données vides.';

  @override
  String get couldNotLoadTemplates => 'Impossible de charger les modèles.';

  @override
  String get retry => 'Réessayer';

  @override
  String get nfcLinkedAutomatically => '🔗 Tag NFC lié automatiquement';

  @override
  String audioSelected(Object name) {
    return '📥 Audio sélectionné: $name';
  }

  @override
  String get rejectedInvalidAudio => '❌ Rejeté: Le fichier sélectionné n\'est pas un fichier audio valide.';

  @override
  String get cannotSaveInvalidAudio => '❌ Impossible d\'enregistrer: Le fichier n\'est pas un fichier audio valide.';

  @override
  String get failedToLaunchAudioPicker => '❌ Échec du lancement du sélecteur audio';

  @override
  String get nfcTagLinked => '🔗 Tag NFC lié automatiquement';

  @override
  String get storageReinitialized => 'Stockage réinitialisé';

  @override
  String reinitializationFailed(Object error) {
    return 'Échec de la réinitialisation: $error';
  }

  @override
  String get allStorageDataCleared => 'Toutes les données de stockage effacées';

  @override
  String clearFailed(Object error) {
    return 'Échec de l\'effacement: $error';
  }

  @override
  String get storageDebugInfoLogged => 'Informations de débogage du stockage journalisées dans la console';

  @override
  String get debugInfoLogged => 'Informations de débogage journalisées dans la console';

  @override
  String get stateTestLogged => 'Test d\'état journalisé dans la console';

  @override
  String nfcOperationFailed(Object error) {
    return 'Opération NFC échouée: $error';
  }

  @override
  String get forceProcessedUuid => 'UUID actuel traité de force';

  @override
  String get tutorialReset => 'Didacticiel réinitialisé - s\'affichera au prochain redémarrage';

  @override
  String failedToOpenLink(Object error) {
    return '❌ Échec de l\'ouverture du lien: $error';
  }

  @override
  String get slideToLock => 'Faire glisser pour verrouiller';

  @override
  String get screenLocked => 'Écran verrouillé';

  @override
  String get swipeUpToUnlock => 'Faites glisser 3 doigts vers le haut pour déverrouiller';

  @override
  String get tutorialAddFolderTitle => 'Créer des collections musicales';

  @override
  String get tutorialAddFolderDesc => 'Appuyez sur \"Ajouter un nouveau dossier\" pour créer des dossiers et organiser votre collection de fichiers audio.';

  @override
  String get tutorialAddSongTitle => 'Ajoutez vos chansons';

  @override
  String get tutorialAddSongDesc => 'Une fois qu\'un dossier est créé, appuyez sur \"Ajouter un fichier audio\" pour sélectionner des fichiers audio sur votre appareil.';

  @override
  String get tutorialAttachFileTitle => 'Sélectionner un fichier audio';

  @override
  String get tutorialAttachFileDesc => 'Appuyez sur l\'icône du trombone pour sélectionner un fichier audio sur votre appareil.';

  @override
  String get tutorialConnectNfcTitle => 'Connecter un tag NFC';

  @override
  String get tutorialConnectNfcDesc => 'Approchez n\'importe quel tag NFC de l\'arrière de votre téléphone jusqu\'à ce qu\'il vibre pour connecter le tag au fichier audio pour la lecture.';

  @override
  String get tutorialSettingsTitle => 'Paramètres et packs de démarrage';

  @override
  String get tutorialSettingsDesc => 'Ouvrez le menu des paramètres pour trouver des packs de démarrage audio et d\'autres options.';

  @override
  String get limitReached => 'Limite atteinte';

  @override
  String get folderLimitReached => 'Vous avez atteint la limite de 2 dossiers. Pour en ajouter plus, veuillez passer à la version premium.';

  @override
  String get songLimitReached => 'Vous avez atteint la limite de 6 chansons par dossier. Pour en ajouter plus, veuillez passer à la version premium.';

  @override
  String get themeColor => 'Couleur du thème';

  @override
  String lastDetected(Object uuid) {
    return 'Dernier détecté : $uuid';
  }

  @override
  String nowPlaying(Object title) {
    return 'Lecture en cours : $title';
  }

  @override
  String positionWithTotal(Object current, Object total) {
    return 'Position : $current / $total';
  }

  @override
  String assignedNfc(Object id) {
    return 'NFC assigné : $id...';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get connected => 'Connecté';

  @override
  String get nfcScanningStarted => 'Scan NFC démarré';

  @override
  String get nfcScanningStopped => 'Scan NFC arrêté';

  @override
  String get stopNfc => 'Arrêter le NFC';

  @override
  String get startNfc => 'Démarrer le NFC';

  @override
  String storageError(Object error, Object operation) {
    return 'Erreur de stockage : Échec de $operation. Erreur : $error';
  }

  @override
  String get white => 'Blanc';

  @override
  String get cappuccino => 'Cappuccino';

  @override
  String get black => 'Noir';

  @override
  String get needNfcTagsTitle => 'Envie d\'un petit extra?';
}
