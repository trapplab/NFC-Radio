// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NFC Radio';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get audioPacksTitle => 'Paquetes de audio';

  @override
  String get audioStarterPacks => 'Paquetes de inicio de audio';

  @override
  String get browseAudioOnly => 'Examinar solo archivos de audio';

  @override
  String get filterAudio => 'Filtro: audio/*';

  @override
  String get filterAll => 'Filtro: */*';

  @override
  String get useKioskMode => 'Usar modo quiosco';

  @override
  String get requiresSystemAlertPermission => 'Requiere permiso SYSTEM_ALERT_WINDOW';

  @override
  String get nfcNotAvailable => 'NFC no está disponible en este dispositivo.';

  @override
  String get readyToScanNfc => 'Listo para escanear etiquetas NFC';

  @override
  String get scanningForNfc => 'Escaneando etiquetas NFC...';

  @override
  String get scanningPaused => 'Escaneo pausado';

  @override
  String get startScanning => 'Iniciar escaneo';

  @override
  String get stopScanning => 'Detener escaneo';

  @override
  String get noFoldersYet => 'Todavía no hay carpetas. ¡Cree una carpeta para organizar sus canciones!';

  @override
  String get addNewFolder => 'Agregar nueva carpeta';

  @override
  String get addAudioFile => 'Agregar archivo de audio';

  @override
  String get addNewSong => 'Agregar nueva canción';

  @override
  String get editSong => 'Editar canción';

  @override
  String get playbackOptions => 'Opciones de reproducción';

  @override
  String get loopPlayback => 'Reproducción en bucle';

  @override
  String get rememberPosition => 'Recordar posición';

  @override
  String get nfcConfiguration => 'Configuración NFC';

  @override
  String get nfcAssignedReady => 'NFC está asignado y listo';

  @override
  String get waitingForNfc => 'Esperando etiqueta NFC...';

  @override
  String newNfcDetected(Object nfcId) {
    return 'Nuevo NFC detectado: $nfcId...';
  }

  @override
  String get useThisNfc => 'Usar este NFC';

  @override
  String get nfcTagAlreadyConnected => 'Etiqueta NFC ya conectada';

  @override
  String get nfcAlreadyConnectedTo => 'Esta etiqueta NFC ya está conectada a:';

  @override
  String get replaceConnectionQuestion => '¿Desea reemplazar la conexión?';

  @override
  String get keepExisting => 'Mantener existente';

  @override
  String get replaceConnection => 'Reemplazar conexión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get create => 'Crear';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get editFolder => 'Editar carpeta';

  @override
  String get deleteFolder => 'Eliminar carpeta';

  @override
  String get deleteSong => 'Eliminar canción';

  @override
  String get folderName => 'Nombre de la carpeta';

  @override
  String get audioSource => 'Fuente de audio';

  @override
  String get title => 'Título';

  @override
  String get areYouSureDeleteFolder => '¿Está seguro de que desea eliminar esta carpeta?';

  @override
  String songsInFolder(Object count) {
    return 'Canciones en la carpeta: $count';
  }

  @override
  String get noteDeleteSongs => 'Nota: Todas las canciones en esta carpeta y sus archivos de audio también se eliminarán.';

  @override
  String get areYouSureDeleteSong => '¿Está seguro de que desea eliminar esta canción?';

  @override
  String nfcMappingRemoved(Object nfcId) {
    return 'Esto también eliminará el mapeo NFC para: $nfcId';
  }

  @override
  String get audioFileDeleted => 'El archivo de audio también se eliminará del almacenamiento de la aplicación.';

  @override
  String get upgradeToPremium => 'Actualizar a Premium';

  @override
  String get freeVersionLimit => 'En la versión gratuita, puede agregar hasta 2 carpetas con 6 archivos de audio cada una.';

  @override
  String get upgradeToUnlock => 'Actualice a Premium para desbloquear carpetas y archivos de audio ilimitados, ¡y apoye a los desarrolladores!';

  @override
  String get later => 'Más tarde';

  @override
  String get upgrade => 'Actualizar';

  @override
  String get storageDebug => '🗄️ Depuración de almacenamiento';

  @override
  String get storageServiceStatus => 'Estado del servicio de almacenamiento:';

  @override
  String initialized(Object status) {
    return 'Inicializado: $status';
  }

  @override
  String platform(Object platform) {
    return 'Plataforma: $platform';
  }

  @override
  String get storageStatistics => 'Estadísticas de almacenamiento:';

  @override
  String get iapPremiumStatus => 'Estado de IAP/Premium:';

  @override
  String premiumStatus(Object status) {
    return 'Premium: $status';
  }

  @override
  String get premiumNotAvailable => 'Premium: No disponible (versión no GP)';

  @override
  String get actions => 'Acciones:';

  @override
  String get logDebugInfo => 'Registrar información de depuración';

  @override
  String get forceReinitialize => 'Forzar reinicialización';

  @override
  String get clearAllData => 'Borrar todos los datos';

  @override
  String get logPremiumStatus => 'Registrar estado premium';

  @override
  String get clearPremiumStatus => 'Borrar estado premium';

  @override
  String get close => 'Cerrar';

  @override
  String get debugInformation => '🔍 Información de depuración';

  @override
  String get nfcServiceStatus => 'Estado del servicio NFC:';

  @override
  String nfcAvailable(Object status) {
    return 'NFC disponible: $status';
  }

  @override
  String nfcScanning(Object status) {
    return 'Escaneo NFC: $status';
  }

  @override
  String currentUuid(Object uuid) {
    return 'UUID actual: $uuid';
  }

  @override
  String get musicPlayerStatus => 'Estado del reproductor de música:';

  @override
  String currentState(Object state) {
    return 'Estado actual: $state';
  }

  @override
  String isPlaying(Object status) {
    return 'Se está reproduciendo: $status';
  }

  @override
  String isPaused(Object status) {
    return 'Está pausado: $status';
  }

  @override
  String currentFile(Object file) {
    return 'Archivo actual: $file';
  }

  @override
  String position(Object position) {
    return 'Posición: $position';
  }

  @override
  String get songsMappings => 'Canciones y mapeos:';

  @override
  String totalSongs(Object count) {
    return 'Total de canciones: $count';
  }

  @override
  String songWithUuid(Object index, Object title, Object uuid) {
    return 'Canción $index: $title (UUID: $uuid)';
  }

  @override
  String get flavorInformation => 'Información de sabor:';

  @override
  String githubRelease(Object status) {
    return 'Versión de GitHub: $status';
  }

  @override
  String fdroidRelease(Object status) {
    return 'Versión de F-Droid: $status';
  }

  @override
  String googlePlayRelease(Object status) {
    return 'Versión de Google Play: $status';
  }

  @override
  String get testPlayerState => 'Probar estado del reproductor';

  @override
  String get forceProcessUuid => 'Forzar procesamiento de UUID';

  @override
  String get resetTutorial => 'Restablecer tutorial';

  @override
  String importQuestion(Object name) {
    return '¿Importar \"$name\"?';
  }

  @override
  String importDescription(Object count) {
    return 'Esto descargará $count archivos de audio y creará una nueva carpeta.';
  }

  @override
  String get importButton => 'Importar';

  @override
  String get downloadingAudioFiles => 'Descargando archivos de audio...';

  @override
  String importSuccess(Object name) {
    return '\"$name\" importado correctamente';
  }

  @override
  String importFailed(Object name) {
    return 'No se pudieron importar archivos de \"$name\"';
  }

  @override
  String get partialImport => 'Importación parcial';

  @override
  String importedFiles(Object failed, Object success) {
    return 'Se importaron $success archivos, pero $failed archivos no se pudieron descargar:';
  }

  @override
  String get ok => 'OK';

  @override
  String failedToImport(Object error) {
    return 'Error al importar la carpeta: $error';
  }

  @override
  String updateAvailable(Object version) {
    return 'Actualización v$version disponible';
  }

  @override
  String get newVersionAvailable => 'Una nueva versión está disponible en GitHub.';

  @override
  String get changelog => 'Registro de cambios:';

  @override
  String get noChangelog => 'No se proporcionó registro de cambios.';

  @override
  String get downloadUpdate => 'Descargar';

  @override
  String get latestVersion => 'Tienes la última versión.';

  @override
  String updateCheckFailed(Object error) {
    return 'Error al verificar actualizaciones: $error';
  }

  @override
  String get loadedData => '🎵 ¡Se cargaron tus canciones, carpetas y mapeos NFC guardados!';

  @override
  String get failedToLoadData => '⚠️ Error al cargar los datos guardados. La aplicación funcionará con datos vacíos.';

  @override
  String get couldNotLoadTemplates => 'No se pudieron cargar las plantillas.';

  @override
  String get retry => 'Reintentar';

  @override
  String get nfcLinkedAutomatically => '🔗 Etiqueta NFC vinculada automáticamente';

  @override
  String audioSelected(Object name) {
    return '📥 Audio seleccionado: $name';
  }

  @override
  String get rejectedInvalidAudio => '❌ Rechazado: El archivo seleccionado no es un archivo de audio válido.';

  @override
  String get cannotSaveInvalidAudio => '❌ No se puede guardar: El archivo no es un archivo de audio válido.';

  @override
  String get failedToLaunchAudioPicker => '❌ Error al iniciar el selector de audio';

  @override
  String get nfcTagLinked => '🔗 Etiqueta NFC vinculada automáticamente';

  @override
  String get storageReinitialized => 'Almacenamiento reinicializado';

  @override
  String reinitializationFailed(Object error) {
    return 'Error en la reinicialización: $error';
  }

  @override
  String get allStorageDataCleared => 'Todos los datos de almacenamiento borrados';

  @override
  String clearFailed(Object error) {
    return 'Error al borrar: $error';
  }

  @override
  String get storageDebugInfoLogged => 'Información de depuración de almacenamiento registrada en la consola';

  @override
  String get debugInfoLogged => 'Información de depuración registrada en la consola';

  @override
  String get stateTestLogged => 'Prueba de estado registrada en la consola';

  @override
  String nfcOperationFailed(Object error) {
    return 'Operación NFC fallida: $error';
  }

  @override
  String get forceProcessedUuid => 'UUID actual procesado forzadamente';

  @override
  String get tutorialReset => 'Tutorial reiniciado: se mostrará en el próximo reinicio';

  @override
  String failedToOpenLink(Object error) {
    return '❌ Error al abrir el enlace: $error';
  }
}
