import 'dart:typed_data';
import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'nfc_music_mapping.dart';
import 'song.dart';
import 'folder.dart';
import 'music_player.dart';

class NFCService with ChangeNotifier {
  bool _isNfcAvailable = false;
  String? _currentNfcUuid;
  bool _isScanning = false;
  bool _isProcessingTag = false;
  String? _lastScannedUuid;
  DateTime? _lastScannedTimestamp;
  Timer? _debounceTimer;
  final _messageController = StreamController<String>.broadcast();
  bool _isInEditMode = false; // Flag to pause player triggering during edit operations
  NFCMusicMappingProvider? _mappingProvider;
  SongProvider? _songProvider;
  FolderProvider? _folderProvider;
  MusicPlayer? _musicPlayer;

  bool get isNfcAvailable => _isNfcAvailable;
  String? get currentNfcUuid => _currentNfcUuid;
  bool get isScanning => _isScanning;
  bool get isInEditMode => _isInEditMode;
  Stream<String> get messages => _messageController.stream;

  // Set edit mode to pause player triggering during edit operations
  void setEditMode(bool enabled) {
    _isInEditMode = enabled;
    debugPrint('🔧 Edit mode ${enabled ? 'enabled' : 'disabled'} - player triggering ${enabled ? 'paused' : 'active'}');
    // Don't call notifyListeners() here to avoid potential circular dependencies
  }


  // Set providers for music integration
  void setProviders({
    required NFCMusicMappingProvider mappingProvider,
    required SongProvider songProvider,
    required FolderProvider folderProvider,
    required MusicPlayer musicPlayer,
  }) {
    debugPrint('=== SETTING PROVIDERS ===');
    debugPrint('Setting MusicPlayer: ${musicPlayer.runtimeType}');
    debugPrint('Setting SongProvider: ${songProvider.runtimeType} (${songProvider.songs.length} songs)');
    debugPrint('Setting FolderProvider: ${folderProvider.runtimeType} (${folderProvider.folders.length} folders)');
    debugPrint('Setting MappingProvider: ${mappingProvider.runtimeType} (${mappingProvider.mappings.length} mappings)');

    _mappingProvider = mappingProvider;
    _songProvider = songProvider;
    _folderProvider = folderProvider;
    _musicPlayer = musicPlayer;

    // Verify the assignment worked
    debugPrint('=== PROVIDER ASSIGNMENT VERIFICATION ===');
    debugPrint('_musicPlayer after assignment: ${_musicPlayer != null}');
    debugPrint('_songProvider after assignment: ${_songProvider != null}');
    debugPrint('_folderProvider after assignment: ${_folderProvider != null}');
    debugPrint('_mappingProvider after assignment: ${_mappingProvider != null}');
    debugPrint('Are all providers initialized: ${_areProvidersInitialized()}');
    debugPrint('=== PROVIDERS SET COMPLETE ===');

    // Auto-start NFC scanning if NFC is available and not already scanning
    if (_isNfcAvailable && !_isScanning) {
      debugPrint('🚀 Auto-starting NFC scanning after providers are set');
      startNfcSession();
    }
  }



  NFCService() {
    _checkNfcAvailability();
  }

  // Find song by NFC UUID
  Song? _findSongByUuid(String uuid) {
    if (_songProvider == null) {
      debugPrint('SongProvider is null');
      return null;
    }
    
    debugPrint('Searching for UUID: $uuid');
    debugPrint('Available songs: ${_songProvider!.songs.length}');
    
    // First check if song is directly connected to this UUID
    for (Song song in _songProvider!.songs) {
      debugPrint('Checking song: ${song.title}, connectedNfcUuid: ${song.connectedNfcUuid}');
      if (song.connectedNfcUuid != null && song.connectedNfcUuid == uuid) {
        debugPrint('Found song by direct connection: ${song.title}');
        return song;
      }
    }
    
    // If not found directly, check mappings
    if (_mappingProvider != null) {
      debugPrint('Checking mappings...');
      final songId = _mappingProvider!.getSongId(uuid);
      debugPrint('SongId from mapping: $songId');
      if (songId != null) {
        final foundSong = _songProvider!.songs.firstWhere(
          (song) => song.id == songId,
          orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
        );
        if (foundSong.filePath.isNotEmpty) {
          debugPrint('Found song by mapping: ${foundSong.title}');
          return foundSong;
        }
      }
    }
    
    debugPrint('No song found for UUID: $uuid');
    return null;
  }

  // Handle NFC tag discovery with music integration
  void _onNfcDiscovered(NfcTag tag) async {
    debugPrint('📡 NFC Tag Discovered! isScanning=$_isScanning, isProcessingTag=$_isProcessingTag');
    
    if (!_isScanning || _isProcessingTag) {
      debugPrint('⏳ Skipping scan: isScanning=$_isScanning, isProcessingTag=$_isProcessingTag');
      return;
    }

    try {
      final uuid = _extractNfcIdentifier(tag);
      if (uuid == null) {
        debugPrint('⚠️ Could not extract UUID from tag');
        return;
      }

      final now = DateTime.now();
      
      // Global cooldown to prevent rapid-fire scans of any tag (1000ms)
      if (_lastScannedTimestamp != null &&
          now.difference(_lastScannedTimestamp!).inMilliseconds < 1000) {
        debugPrint('⏳ Global cooldown active, ignoring scan');
        return;
      }

      _currentNfcUuid = uuid;
      debugPrint('📡 NFC UUID detected: $uuid');
      
      _lastScannedUuid = uuid;
      _lastScannedTimestamp = now;
      _isProcessingTag = true;
      
      // Notify listeners immediately so the UI shows the detected UUID
      notifyListeners();
      
      // DO NOT stop the session here. Keeping the session active is CRITICAL
      // to prevent the Android system from showing the "Which app" menu.
      // As long as the session is active, the app maintains foreground priority.
      
      // Clear any existing timer
      _debounceTimer?.cancel();
      
      // Process the tag
      debugPrint('⚡ Executing NFC processing for: $uuid');
      try {
        await _processNfcTag(uuid);
      } finally {
        // Add a small delay before allowing next scan to ensure physical removal
        // and prevent immediate re-triggering
        await Future.delayed(const Duration(milliseconds: 500));
        _isProcessingTag = false;
        debugPrint('✅ Tag processing flag cleared');
        notifyListeners(); // Notify again after clearing processing flag
      }
    } catch (e, s) {
      debugPrint('❌ Error processing NFC tag: $e');
      debugPrint('❌ Stack trace: $s');
      _isProcessingTag = false;
      notifyListeners();
    }
  }

  // Process NFC tag for music playback with retry mechanism
  Future<void> _processNfcTag(String uuid) async {
    debugPrint('🔄 ===== NFC TAG PROCESSING STARTED =====');
    debugPrint('🔄 Processing NFC tag: $uuid');
    debugPrint('🔄 Timestamp: ${DateTime.now()}');
    
    // Step 0: Check if providers are initialized (early exit if not ready)
    if (!_areProvidersInitialized()) {
      debugPrint('⚠️ Providers not initialized yet - postponing NFC processing');
      debugPrint('⚠️ This is normal during app startup, will retry automatically');
      
      // Schedule a retry after a short delay
      Timer(const Duration(milliseconds: 500), () {
        debugPrint('🔄 Retrying NFC processing for: $uuid');
        _processNfcTag(uuid);
      });
      return;
    }
    
    // Step 1: Validate providers with retry mechanism
    int validationAttempts = 0;
    while (validationAttempts < 3) {
      validationAttempts++;
      debugPrint('🔍 Provider validation attempt $validationAttempts/3...');
      
      if (_validateProviders()) {
        debugPrint('✅ Provider validation successful on attempt $validationAttempts');
        break;
      } else {
        debugPrint('❌ Provider validation failed on attempt $validationAttempts');
        if (validationAttempts < 3) {
          debugPrint('⏳ Retrying provider validation in 100ms...');
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
    
    if (!_validateProviders()) {
      debugPrint('❌ Provider validation failed after 3 attempts - aborting NFC processing');
      debugPrint('❌ This suggests a critical initialization issue');
      debugPrint('❌ Please check app initialization and provider setup');
      return;
    }

    // Step 2: Find the song
    final song = _findSongByUuid(uuid);
    if (song == null || song.filePath.isEmpty) {
      debugPrint('❌ No song found for UUID: $uuid');
      debugPrint('❌ Available songs: ${_songProvider!.songs.length}');
      for (int i = 0; i < _songProvider!.songs.length; i++) {
        final s = _songProvider!.songs[i];
        debugPrint('❌ Song $i: ${s.title} (UUID: ${s.connectedNfcUuid})');
      }
      
      // We keep scanning active to maintain foreground priority and suppress system menu
      return;
    }

    // Step 2.5: Check if we're in edit mode (skip music triggering)
    if (_isInEditMode) {
      debugPrint('🔧 Edit mode active - skipping music triggering for tag: $uuid');
      debugPrint('🔧 Tag detected but not playing - use this UUID to assign to song');
      // Still notify listeners to update UI with the detected UUID
      notifyListeners();
      return;
    }

    debugPrint('✅ Found song: ${song.title} at ${song.filePath}');
    debugPrint('🔍 Current music player state: ${_musicPlayer!.currentState}');
    debugPrint('🔍 Current music path: ${_musicPlayer!.currentMusicFilePath}');
    debugPrint('🔍 Is playing: ${_musicPlayer!.isPlaying}');
    debugPrint('🔍 Is paused: ${_musicPlayer!.isPaused}');

    // Step 3: Determine action based on current state
    final bool isCurrentlyPlayingThisSong = _musicPlayer!.isSongPlaying(song.filePath);
    final bool isCurrentlyPausedOnThisSong = _musicPlayer!.isSongPaused(song.filePath);
    final bool isCurrentlyStoppedOnThisSong = _musicPlayer!.isSongStopped(song.filePath);
    
    debugPrint('🎵 Analysis:');
    debugPrint('🎵 - Currently playing this song: $isCurrentlyPlayingThisSong');
    debugPrint('🎵 - Currently paused on this song: $isCurrentlyPausedOnThisSong');
    debugPrint('🎵 - Currently stopped on this song: $isCurrentlyStoppedOnThisSong');
    
    // Step 4: Execute action with retry mechanism
    try {
      if (isCurrentlyPlayingThisSong) {
        debugPrint('⏸️ Action: PAUSE current song');
        await _executeWithRetry('pause', () => _musicPlayer!.pauseMusic(), 2);
        _notifyUser('Paused: ${song.title}');
      } else if (isCurrentlyPausedOnThisSong) {
        debugPrint('▶️ Action: RESUME paused song');
        await _executeWithRetry('resume', () => _musicPlayer!.resumeMusic(), 2);
        _notifyUser('Resumed: ${song.title}');
      } else {
        debugPrint('🎵 Action: START NEW SONG');
        await _executeWithRetry('play', () => _musicPlayer!.playMusic(song.filePath), 3);
        _notifyUser('Playing: ${song.title}');
      }
    } catch (e, s) {
      debugPrint('❌ CRITICAL ERROR in music execution: $e');
      debugPrint('❌ Stack trace: $s');
      
      // Show error to user through a callback or notification
      _showErrorToUser('Failed to control music playback: $e');
    }

    // Step 5: Post-action status
    debugPrint('📊 Final state after action:');
    debugPrint('📊 - Player state: ${_musicPlayer!.currentState}');
    debugPrint('📊 - Current path: ${_musicPlayer!.currentMusicFilePath}');
    debugPrint('📊 - Is playing: ${_musicPlayer!.isPlaying}');

    // Step 6: Handle auto-pause (now handled at the start of _onNfcDiscovered for better responsiveness)

    debugPrint('✅ ===== NFC TAG PROCESSING COMPLETED =====');
    notifyListeners();
  }

  // Check if all providers are initialized (quick check without detailed validation)
  bool _areProvidersInitialized() {
    return _musicPlayer != null && _songProvider != null && _folderProvider != null && _mappingProvider != null;
  }

  // Validate that all required providers are available
  bool _validateProviders() {
    debugPrint('🔍 Validating providers...');

    if (_musicPlayer == null) {
      debugPrint('❌ MusicPlayer is null');
      return false;
    }
    debugPrint('✅ MusicPlayer: OK');

    if (_songProvider == null) {
      debugPrint('❌ SongProvider is null');
      return false;
    }
    debugPrint('✅ SongProvider: OK (${_songProvider!.songs.length} songs)');

    if (_folderProvider == null) {
      debugPrint('❌ FolderProvider is null');
      return false;
    }
    debugPrint('✅ FolderProvider: OK (${_folderProvider!.folders.length} folders)');

    if (_mappingProvider == null) {
      debugPrint('❌ NFCMusicMappingProvider is null');
      return false;
    }
    debugPrint('✅ NFCMusicMappingProvider: OK (${_mappingProvider!.mappings.length} mappings)');

    debugPrint('✅ All providers validated successfully');
    return true;
  }

  // Execute function with retry mechanism
  Future<void> _executeWithRetry(String operationName, Future<void> Function() operation, int maxRetries) async {
    int attempt = 0;
    Exception? lastError;
    
    while (attempt < maxRetries) {
      attempt++;
      debugPrint('🔄 $operationName attempt $attempt/$maxRetries');
      
      try {
        await operation();
        debugPrint('✅ $operationName succeeded on attempt $attempt');
        return; // Success, exit retry loop
      } catch (e) {
        lastError = e as Exception;
        debugPrint('❌ $operationName failed on attempt $attempt: $e');
        
        if (attempt < maxRetries) {
          final delay = Duration(milliseconds: 200 * attempt); // Exponential backoff
          debugPrint('⏳ Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
    }
    
    // All retries failed
    debugPrint('❌ $operationName failed after $maxRetries attempts');
    debugPrint('❌ Last error: $lastError');
    throw lastError ?? Exception('$operationName failed after $maxRetries attempts');
  }

  // Show error to user
  void _showErrorToUser(String errorMessage) {
    debugPrint('🚨 USER ERROR NOTIFICATION: $errorMessage');
    _messageController.add('⚠️ $errorMessage');
  }

  // Notify user of general events
  void _notifyUser(String message) {
    debugPrint('📢 USER NOTIFICATION: $message');
    _messageController.add(message);
  }



  // Clear the last scanned UUID (useful for testing)
  void clearLastScannedUuid() {
    _lastScannedUuid = null;
    notifyListeners();
  }

  // Get detailed debug information about current state
  Map<String, dynamic> getDebugInfo() {
    final song = _currentNfcUuid != null ? _findSongByUuid(_currentNfcUuid!) : null;
    return {
      'isNfcAvailable': _isNfcAvailable,
      'isScanning': _isScanning,
      'currentNfcUuid': _currentNfcUuid,
      'lastScannedUuid': _lastScannedUuid,

      'musicPlayerState': _musicPlayer?.currentState.toString(),
      'currentMusicPath': _musicPlayer?.currentMusicFilePath,
      'mappedSong': song != null ? {
        'title': song.title,
        'filePath': song.filePath,
        'connectedNfcUuid': song.connectedNfcUuid,
      } : null,
      'totalSongs': _songProvider?.songs.length ?? 0,
      'totalFolders': _folderProvider?.folders.length ?? 0,
      'totalMappings': _mappingProvider?.mappings.length ?? 0,
    };
  }

  // Test method to simulate NFC detection for debugging
  void testNfcProcessing(String uuid) {
    debugPrint('🧪 ===== TEST NFC PROCESSING =====');
    debugPrint('🧪 Testing UUID: $uuid');
    final debugInfo = getDebugInfo();
    debugPrint('🧪 Current state: $debugInfo');
    
    // Simulate the exact flow as _onNfcDiscovered
    debugPrint('🧪 Simulating NFC detection...');
    _currentNfcUuid = uuid;
    debugPrint('🧪 Current UUID set to: $_currentNfcUuid');
    
    debugPrint('🧪 Calling _processNfcTag directly...');
    _processNfcTag(uuid);
    
    debugPrint('🧪 ===== END TEST =====');
  }

  // Force immediate NFC processing for testing
  void forceProcessCurrentUuid() {
    if (_currentNfcUuid != null) {
      debugPrint('🔄 FORCING immediate processing of current UUID: $_currentNfcUuid');
      _processNfcTag(_currentNfcUuid!);
    } else {
      debugPrint('❌ No current UUID to process');
    }
  }

  Future<void> _checkNfcAvailability() async {
    _isNfcAvailable = await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;
    
    // Request permission on Android 13+ (API 33+)
    if (_isNfcAvailable) {
      await _requestNfcPermission();
    }
    
    notifyListeners();
  }

  Future<bool> _requestNfcPermission() async {
    try {
      // For Android 13+ (API 33+), we need to request NEARBY_WIFI_DEVICES permission
      final status = await Permission.nearbyWifiDevices.status;
      if (!status.isGranted) {
        final result = await Permission.nearbyWifiDevices.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting NFC permission: $e');
      return false;
    }
  }

  String? _extractNfcIdentifier(NfcTag tag) {
    try {
      // ignore: invalid_use_of_protected_member
      final tagData = tag.data;
      debugPrint('Tag data type: ${tagData.runtimeType}');
      
      // 1. Try direct Map access if it's a Map
      if (tagData is Map) {
        // Check common keys for UID
        for (final key in ['id', 'identifier', 'tagId']) {
          final value = tagData[key];
          if (value is Uint8List) {
            return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          }
        }
        
        // Check tech-specific keys
        for (final tech in ['nfca', 'mifare', 'iso7816', 'isodep', 'nfcv', 'nfcf']) {
          if (tagData[tech] != null && tagData[tech] is Map) {
            final techData = tagData[tech] as Map;
            for (final key in ['identifier', 'id']) {
              final value = techData[key];
              if (value is Uint8List) {
                return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
              }
            }
          }
        }
      }
      
      // 2. Try dynamic property access (for TagPigeon or other objects)
      final dynamic dTagData = tagData;
      
      // Try to find identifier in common Pigeon properties
      for (final prop in ['identifier', 'id', 'tagId']) {
        try {
          final value = dTagData.toJson()[prop];
          if (value is Uint8List) return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        } catch (_) {}
        try {
          final value = dTagData.toMap()[prop];
          if (value is Uint8List) return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        } catch (_) {}
        try {
          final value = dTagData.identifier;
          if (value is Uint8List) return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        } catch (_) {}
        try {
          final value = dTagData.id;
          if (value is Uint8List) return value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        } catch (_) {}
      }

      // Try tech-specific properties on the object
      for (final tech in ['nfca', 'mifare', 'iso7816', 'isodep', 'nfcv', 'nfcf']) {
        try {
          final techObj = dTagData.toJson()[tech];
          if (techObj != null) {
            final id = techObj['identifier'] ?? techObj['id'];
            if (id is Uint8List) return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          }
        } catch (_) {}
      }

      // 3. Last resort: search the entire map recursively for anything that looks like a UID
      if (tagData is Map) {
        return _findUidInMap(tagData);
      }
      
    } catch (e) {
      debugPrint('Error extracting NFC identifier: $e');
    }
    return null;
  }

  String? _findUidInMap(Map map) {
    for (final entry in map.entries) {
      if (entry.value is Uint8List) {
        final list = entry.value as Uint8List;
        if (list.length >= 4 && list.length <= 10) { // Typical NFC UID lengths
          return list.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        }
      } else if (entry.value is Map) {
        final result = _findUidInMap(entry.value as Map);
        if (result != null) return result;
      }
    }
    return null;
  }

  Future<void> startNfcSession() async {
    if (!_isNfcAvailable) {
      debugPrint('NFC is not available on this device.');
      return;
    }

    // Request permission before starting session
    await _requestNfcPermission();

    _isScanning = true;
    notifyListeners();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092, // Added for broader tag support
        },
        onDiscovered: _onNfcDiscovered,
      );
      debugPrint('NFC session started - continuous scanning active');
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopNfcSession() async {
    _isScanning = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    notifyListeners();
    await NfcManager.instance.stopSession();
    debugPrint('NFC session stopped');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _messageController.close();
    super.dispose();
  }
}
