import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'song.dart';
import 'nfc_music_mapping.dart';

/// Service class to handle all persistence operations using Hive storage
class StorageService {
  static const String _songsBoxName = 'songs';
  static const String _mappingsBoxName = 'mappings';
  
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  Box<Song>? _songsBox;
  Box<NFCMusicMapping>? _mappingsBox;
  bool _isInitialized = false;
  
  /// Initialize Hive storage and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔧 ===== HIVE STORAGE INITIALIZATION STARTED =====');
      debugPrint('🔧 Platform: ${Platform.operatingSystem}');
      debugPrint('🔧 Current working directory: ${Directory.current.path}');
      
      // Initialize Hive Flutter with specific directory for Android
      debugPrint('🔧 Initializing Hive Flutter...');
      await Hive.initFlutter('nfc_jukebox_data');
      debugPrint('✅ Hive Flutter initialized');
      
      // Register adapters
      debugPrint('🔧 Registering adapters...');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SongAdapter());
        debugPrint('✅ SongAdapter registered');
      } else {
        debugPrint('ℹ️ SongAdapter already registered');
      }
      
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NFCMusicMappingAdapter());
        debugPrint('✅ NFCMusicMappingAdapter registered');
      } else {
        debugPrint('ℹ️ NFCMusicMappingAdapter already registered');
      }
      
      // Open boxes with error handling
      debugPrint('🔧 Opening songs box: $_songsBoxName');
      _songsBox = await Hive.openBox<Song>(_songsBoxName);
      debugPrint('✅ Songs box opened successfully');
      debugPrint('📊 Songs box path: ${_songsBox?.path}');
      debugPrint('📊 Songs box length: ${_songsBox?.length ?? 0}');
      
      debugPrint('🔧 Opening mappings box: $_mappingsBoxName');
      _mappingsBox = await Hive.openBox<NFCMusicMapping>(_mappingsBoxName);
      debugPrint('✅ Mappings box opened successfully');
      debugPrint('📊 Mappings box path: ${_mappingsBox?.path}');
      debugPrint('📊 Mappings box length: ${_mappingsBox?.length ?? 0}');
      
      _isInitialized = true;
      debugPrint('✅ ===== HIVE STORAGE INITIALIZATION COMPLETED =====');
      debugPrint('📊 Final stats - Songs: ${_songsBox?.length ?? 0}, Mappings: ${_mappingsBox?.length ?? 0}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ ===== HIVE STORAGE INITIALIZATION FAILED =====');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Platform: ${Platform.operatingSystem}');
      
      // Print additional context for debugging
      try {
        debugPrint('❌ Available directories:');
        Directory.current.listSync().forEach((entity) {
          debugPrint('❌ - ${entity.path}');
        });
      } catch (dirError) {
        debugPrint('❌ Could not list directories: $dirError');
      }
      
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Check if storage is initialized and ready
  bool get isInitialized => _isInitialized && _songsBox != null && _mappingsBox != null;
  
  /// Check if this is the first run (no existing data)
  bool get isFirstRun => !(_songsBox?.isNotEmpty ?? false) && !(_mappingsBox?.isNotEmpty ?? false);
  
  // ========== SONGS OPERATIONS ==========
  
  /// Save a song to storage
  Future<void> saveSong(Song song) async {
    _checkInitialization();
    
    try {
      await _songsBox!.put(song.id, song);
      debugPrint('💾 Saved song: ${song.title} (${song.id})');
    } catch (e) {
      debugPrint('❌ Failed to save song: $e');
      rethrow;
    }
  }
  
  /// Save multiple songs to storage
  Future<void> saveSongs(List<Song> songs) async {
    _checkInitialization();
    
    try {
      final Map<String, Song> songsMap = {for (var song in songs) song.id: song};
      await _songsBox!.putAll(songsMap);
      debugPrint('💾 Saved ${songs.length} songs to storage');
    } catch (e) {
      debugPrint('❌ Failed to save songs: $e');
      rethrow;
    }
  }
  
  /// Get all songs from storage
  List<Song> getAllSongs() {
    _checkInitialization();
    
    try {
      final songs = _songsBox!.values.toList();
      debugPrint('📖 Loaded ${songs.length} songs from storage');
      return songs;
    } catch (e) {
      debugPrint('❌ Failed to load songs: $e');
      return [];
    }
  }
  
  /// Get a song by ID
  Song? getSong(String songId) {
    _checkInitialization();
    
    try {
      return _songsBox!.get(songId);
    } catch (e) {
      debugPrint('❌ Failed to get song $songId: $e');
      return null;
    }
  }
  
  /// Delete a song from storage
  Future<void> deleteSong(String songId) async {
    _checkInitialization();
    
    try {
      await _songsBox!.delete(songId);
      debugPrint('🗑️ Deleted song: $songId');
    } catch (e) {
      debugPrint('❌ Failed to delete song $songId: $e');
      rethrow;
    }
  }
  
  /// Clear all songs from storage
  Future<void> clearSongs() async {
    _checkInitialization();
    
    try {
      await _songsBox!.clear();
      debugPrint('🧹 Cleared all songs from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear songs: $e');
      rethrow;
    }
  }
  
  // ========== MAPPINGS OPERATIONS ==========
  
  /// Save a mapping to storage
  Future<void> saveMapping(NFCMusicMapping mapping) async {
    _checkInitialization();
    
    try {
      await _mappingsBox!.put(mapping.nfcUuid, mapping);
      debugPrint('💾 Saved mapping: ${mapping.nfcUuid} -> ${mapping.songId}');
    } catch (e) {
      debugPrint('❌ Failed to save mapping: $e');
      rethrow;
    }
  }
  
  /// Save multiple mappings to storage
  Future<void> saveMappings(List<NFCMusicMapping> mappings) async {
    _checkInitialization();
    
    try {
      final Map<String, NFCMusicMapping> mappingsMap = {for (var mapping in mappings) mapping.nfcUuid: mapping};
      await _mappingsBox!.putAll(mappingsMap);
      debugPrint('💾 Saved ${mappings.length} mappings to storage');
    } catch (e) {
      debugPrint('❌ Failed to save mappings: $e');
      rethrow;
    }
  }
  
  /// Get all mappings from storage
  List<NFCMusicMapping> getAllMappings() {
    _checkInitialization();
    
    try {
      final mappings = _mappingsBox!.values.toList();
      debugPrint('📖 Loaded ${mappings.length} mappings from storage');
      return mappings;
    } catch (e) {
      debugPrint('❌ Failed to load mappings: $e');
      return [];
    }
  }
  
  /// Get a mapping by NFC UUID
  NFCMusicMapping? getMapping(String nfcUuid) {
    _checkInitialization();
    
    try {
      return _mappingsBox!.get(nfcUuid);
    } catch (e) {
      debugPrint('❌ Failed to get mapping for $nfcUuid: $e');
      return null;
    }
  }
  
  /// Get song ID by NFC UUID
  String? getSongIdByNfcUuid(String nfcUuid) {
    final mapping = getMapping(nfcUuid);
    return mapping?.songId;
  }
  
  /// Delete a mapping from storage
  Future<void> deleteMapping(String nfcUuid) async {
    _checkInitialization();
    
    try {
      await _mappingsBox!.delete(nfcUuid);
      debugPrint('🗑️ Deleted mapping for NFC: $nfcUuid');
    } catch (e) {
      debugPrint('❌ Failed to delete mapping for $nfcUuid: $e');
      rethrow;
    }
  }
  
  /// Clear all mappings from storage
  Future<void> clearMappings() async {
    _checkInitialization();
    
    try {
      await _mappingsBox!.clear();
      debugPrint('🧹 Cleared all mappings from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear mappings: $e');
      rethrow;
    }
  }
  
  // ========== UTILITY METHODS ==========
  
  /// Clear all data from storage
  Future<void> clearAllData() async {
    _checkInitialization();
    
    try {
      await Future.wait([
        clearSongs(),
        clearMappings(),
      ]);
      debugPrint('🧹 Cleared all data from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear all data: $e');
      rethrow;
    }
  }
  
  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    if (!isInitialized) {
      return {
        'initialized': false,
        'error': 'Storage not initialized'
      };
    }
    
    return {
      'initialized': _isInitialized,
      'songsCount': _songsBox?.length ?? 0,
      'mappingsCount': _mappingsBox?.length ?? 0,
      'songsBoxPath': _songsBox?.path,
      'mappingsBoxPath': _mappingsBox?.path,
      'platform': Platform.operatingSystem,
      'boxIsOpen': _songsBox?.isOpen ?? false,
      'boxIsEmpty': _songsBox?.isEmpty ?? false,
    };
  }

  /// Manual debug method to check storage status
  void debugStorageStatus() {
    debugPrint('🔍 ===== STORAGE DEBUG STATUS =====');
    debugPrint('🔍 Is Initialized: $_isInitialized');
    debugPrint('🔍 Platform: ${Platform.operatingSystem}');
    
    if (_songsBox != null) {
      debugPrint('🔍 Songs Box:');
      debugPrint('🔍 - Is Open: ${_songsBox!.isOpen}');
      debugPrint('🔍 - Path: ${_songsBox!.path}');
      debugPrint('🔍 - Length: ${_songsBox!.length}');
      debugPrint('🔍 - Is Empty: ${_songsBox!.isEmpty}');
      
      if (_songsBox!.isNotEmpty) {
        debugPrint('🔍 - Songs in box:');
        for (int i = 0; i < _songsBox!.length && i < 5; i++) {
          final song = _songsBox!.getAt(i);
          debugPrint('🔍   $i: ${song?.title ?? 'null'} (${song?.id ?? 'null'})');
        }
      }
    } else {
      debugPrint('🔍 Songs Box: NULL');
    }
    
    if (_mappingsBox != null) {
      debugPrint('🔍 Mappings Box:');
      debugPrint('🔍 - Is Open: ${_mappingsBox!.isOpen}');
      debugPrint('🔍 - Path: ${_mappingsBox!.path}');
      debugPrint('🔍 - Length: ${_mappingsBox!.length}');
      debugPrint('🔍 - Is Empty: ${_mappingsBox!.isEmpty}');
    } else {
      debugPrint('🔍 Mappings Box: NULL');
    }
    
    debugPrint('🔍 ===== END STORAGE DEBUG =====');
  }

  /// Force reinitialize storage (for debugging)
  Future<void> forceReinitialize() async {
    debugPrint('🔄 Forcing storage reinitialization...');
    _isInitialized = false;
    await initialize();
  }
  
  /// Check if storage is initialized, throw exception if not
  void _checkInitialization() {
    if (!isInitialized) {
      throw StateError('StorageService is not initialized. Call initialize() first.');
    }
  }
  
  /// Show storage error to user
  void showStorageError(BuildContext context, String operation, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Storage Error: Failed to $operation. Error: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Show success message to user
  void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}