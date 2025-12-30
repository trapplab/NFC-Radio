import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'storage_service.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String filePath;
  @HiveField(3)
  String? connectedNfcUuid;

  Song({
    required this.id,
    required this.title,
    required this.filePath,
    this.connectedNfcUuid,
  });

  // Convert the song to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'filePath': filePath,
    'connectedNfcUuid': connectedNfcUuid,
  };

  // Create a song from a JSON map
  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'],
    title: json['title'],
    filePath: json['filePath'],
    connectedNfcUuid: json['connectedNfcUuid'],
  );
}

class SongProvider with ChangeNotifier {
  final List<Song> _songs = [];
  final StorageService _storageService = StorageService.instance;
  bool _isInitialized = false;

  List<Song> get songs => _songs;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading songs from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🎵 ===== SONGPROVIDER INITIALIZATION STARTED =====');
      
      // Initialize storage service if not already done
      debugPrint('🎵 Initializing storage service...');
      await _storageService.initialize();
      debugPrint('🎵 Storage service initialized');
      
      // Load songs from storage
      debugPrint('🎵 Loading songs from storage...');
      final storedSongs = _storageService.getAllSongs();
      debugPrint('🎵 Loaded ${storedSongs.length} songs from storage');
      
      _songs.clear();
      _songs.addAll(storedSongs);
      
      // Log each song for debugging
      if (_songs.isNotEmpty) {
        debugPrint('🎵 Songs in provider:');
        for (int i = 0; i < _songs.length; i++) {
          final song = _songs[i];
          debugPrint('🎵   $i: "${song.title}" (ID: ${song.id}) - File: ${song.filePath} - NFC: ${song.connectedNfcUuid ?? 'None'}');
        }
      } else {
        debugPrint('🎵 No songs found in storage');
      }
      
      _isInitialized = true;
      debugPrint('✅ SongProvider initialized with ${_songs.length} songs');
      debugPrint('🎵 ===== SONGPROVIDER INITIALIZATION COMPLETED =====');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize SongProvider: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Continue with empty list if storage fails
      _isInitialized = true;
      notifyListeners();
    }
  }

  void addSong(Song song) {
    _songs.add(song);
    _saveSongToStorage(song);
    notifyListeners();
  }

  void removeSong(String songId) {
    _songs.removeWhere((song) => song.id == songId);
    _deleteSongFromStorage(songId);
    notifyListeners();
  }

  void updateSong(Song updatedSong) {
    final songIndex = _songs.indexWhere((song) => song.id == updatedSong.id);
    if (songIndex != -1) {
      _songs[songIndex] = updatedSong;
      _saveSongToStorage(updatedSong);
      notifyListeners();
    }
  }

  void connectSongToNfc(String songId, String nfcUuid) {
    final songIndex = _songs.indexWhere((song) => song.id == songId);
    if (songIndex != -1) {
      final updatedSong = Song(
        id: _songs[songIndex].id,
        title: _songs[songIndex].title,
        filePath: _songs[songIndex].filePath,
        connectedNfcUuid: nfcUuid,
      );
      _songs[songIndex] = updatedSong;
      _saveSongToStorage(updatedSong);
      notifyListeners();
    }
  }

  void disconnectSongFromNfc(String songId) {
    final songIndex = _songs.indexWhere((song) => song.id == songId);
    if (songIndex != -1) {
      final updatedSong = Song(
        id: _songs[songIndex].id,
        title: _songs[songIndex].title,
        filePath: _songs[songIndex].filePath,
        connectedNfcUuid: null,
      );
      _songs[songIndex] = updatedSong;
      _saveSongToStorage(updatedSong);
      notifyListeners();
    }
  }

  Song? getSongByNfcUuid(String nfcUuid) {
    return _songs.firstWhere(
      (song) => song.connectedNfcUuid == nfcUuid,
      orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
    );
  }

  // ========== STORAGE OPERATIONS ==========

  /// Save a song to storage (with fallback to in-memory on error)
  Future<void> _saveSongToStorage(Song song) async {
    if (!_isInitialized) return; // Skip if not initialized yet
    
    try {
      await _storageService.saveSong(song);
    } catch (e) {
      debugPrint('⚠️ Failed to save song to storage: $e');
      // Continue without storage - data will be lost on app restart
    }
  }

  /// Delete a song from storage (with fallback to in-memory on error)
  Future<void> _deleteSongFromStorage(String songId) async {
    if (!_isInitialized) return; // Skip if not initialized yet
    
    try {
      await _storageService.deleteSong(songId);
    } catch (e) {
      debugPrint('⚠️ Failed to delete song from storage: $e');
      // Continue without storage
    }
  }

  /// Clear all songs from storage
  Future<void> clearAllSongs() async {
    try {
      await _storageService.clearSongs();
      debugPrint('🧹 Cleared all songs from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear songs from storage: $e');
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getStorageStats();
  }
}