import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import 'song.dart';
import '../nfc/nfc_music_mapping.dart';
import 'folder.dart';

/// Service class to handle all persistence operations using Hive storage
class StorageService {
  static const String _songsBoxName = 'songs';
  static const String _mappingsBoxName = 'mappings';
  static const String _foldersBoxName = 'folders';
  static const String _settingsBoxName = 'settings';
  
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  Box<Song>? _songsBox;
  Box<NFCMusicMapping>? _mappingsBox;
  Box<Folder>? _foldersBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;
  
  /// Initialize Hive storage and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔧 ===== HIVE STORAGE INITIALIZATION STARTED =====');
      debugPrint('🔧 Platform: ${Platform.operatingSystem}');
      debugPrint('🔧 Current working directory: ${Directory.current.path}');
      
      // Initialize Hive Flutter
      debugPrint('🔧 Initializing Hive Flutter...');
      if (Platform.isLinux) {
        final dir = await getApplicationSupportDirectory();
        Hive.init(dir.path);
      } else {
        await Hive.initFlutter();
      }
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

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FolderAdapter());
        debugPrint('✅ FolderAdapter registered');
      } else {
        debugPrint('ℹ️ FolderAdapter already registered');
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

      debugPrint('🔧 Opening folders box: $_foldersBoxName');
      _foldersBox = await Hive.openBox<Folder>(_foldersBoxName);
      debugPrint('✅ Folders box opened successfully');
      
      debugPrint('🔧 Opening settings box: $_settingsBoxName');
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
      debugPrint('✅ Settings box opened successfully');
      
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
  bool get isInitialized => _isInitialized && _songsBox != null && _mappingsBox != null && _foldersBox != null;
  
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
      // Use songId as key to allow multiple songs to use the same NFC UUID
      await _mappingsBox!.put(mapping.songId, mapping);
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
      final Map<String, NFCMusicMapping> mappingsMap = {for (var mapping in mappings) mapping.songId: mapping};
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
  
  /// Get a mapping by song ID
  NFCMusicMapping? getMapping(String songId) {
    _checkInitialization();
    
    try {
      return _mappingsBox!.get(songId);
    } catch (e) {
      debugPrint('❌ Failed to get mapping for song $songId: $e');
      return null;
    }
  }
  
  /// Delete a mapping from storage
  Future<void> deleteMapping(String songId) async {
    _checkInitialization();
    
    try {
      await _mappingsBox!.delete(songId);
      debugPrint('🗑️ Deleted mapping for song: $songId');
    } catch (e) {
      debugPrint('❌ Failed to delete mapping for song $songId: $e');
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
  
  // ========== FOLDERS OPERATIONS ==========

  /// Save a folder to storage
  Future<void> saveFolder(Folder folder) async {
    _checkInitialization();

    try {
      await _foldersBox!.put(folder.id, folder);
      debugPrint('💾 Saved folder: ${folder.name} (${folder.id})');
    } catch (e) {
      debugPrint('❌ Failed to save folder: $e');
      rethrow;
    }
  }

  /// Save multiple folders to storage
  Future<void> saveFolders(List<Folder> folders) async {
    _checkInitialization();

    try {
      final Map<String, Folder> foldersMap = {for (var folder in folders) folder.id: folder};
      await _foldersBox!.putAll(foldersMap);
      debugPrint('💾 Saved ${folders.length} folders to storage');
    } catch (e) {
      debugPrint('❌ Failed to save folders: $e');
      rethrow;
    }
  }

  /// Get all folders from storage
  List<Folder> getAllFolders() {
    _checkInitialization();

    try {
      final folders = _foldersBox!.values.toList();
      debugPrint('📖 Loaded ${folders.length} folders from storage');
      return folders;
    } catch (e) {
      debugPrint('❌ Failed to load folders: $e');
      return [];
    }
  }

  /// Get a folder by ID
  Folder? getFolder(String folderId) {
    _checkInitialization();

    try {
      return _foldersBox!.get(folderId);
    } catch (e) {
      debugPrint('❌ Failed to get folder $folderId: $e');
      return null;
    }
  }

  /// Delete a folder from storage
  Future<void> deleteFolder(String folderId) async {
    _checkInitialization();

    try {
      await _foldersBox!.delete(folderId);
      debugPrint('🗑️ Deleted folder: $folderId');
    } catch (e) {
      debugPrint('❌ Failed to delete folder $folderId: $e');
      rethrow;
    }
  }

  /// Clear all folders from storage
  Future<void> clearFolders() async {
    _checkInitialization();

    try {
      await _foldersBox!.clear();
      debugPrint('🧹 Cleared all folders from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear folders: $e');
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
        clearFolders(),
        _settingsBox?.clear() ?? Future.value(),
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
      'foldersCount': _foldersBox?.length ?? 0,
      'songsBoxPath': _songsBox?.path,
      'mappingsBoxPath': _mappingsBox?.path,
      'foldersBoxPath': _foldersBox?.path,
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

    if (_foldersBox != null) {
      debugPrint('🔍 Folders Box:');
      debugPrint('🔍 - Is Open: ${_foldersBox!.isOpen}');
      debugPrint('🔍 - Path: ${_foldersBox!.path}');
      debugPrint('🔍 - Length: ${_foldersBox!.length}');
      debugPrint('🔍 - Is Empty: ${_foldersBox!.isEmpty}');

      if (_foldersBox!.isNotEmpty) {
        debugPrint('🔍 - Folders in box:');
        for (int i = 0; i < _foldersBox!.length && i < 5; i++) {
          final folder = _foldersBox!.getAt(i);
          debugPrint('🔍   $i: ${folder?.name ?? 'null'} (${folder?.id ?? 'null'})');
        }
      }
    } else {
      debugPrint('🔍 Folders Box: NULL');
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
        content: Text(AppLocalizations.of(context)!.storageError(operation, error.toString())),
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

  // ========== SETTINGS OPERATIONS ==========
  
  Future<void> saveSetting(String key, dynamic value) async {
    _checkInitialization();
    await _settingsBox!.put(key, value);
  }
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    _checkInitialization();
    return _settingsBox!.get(key, defaultValue: defaultValue);
  }
}