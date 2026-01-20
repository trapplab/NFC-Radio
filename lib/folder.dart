import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'storage_service.dart';
import 'config.dart';
import 'iap_service.dart';

part 'folder.g.dart';

@HiveType(typeId: 2)
class Folder extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  List<String> songIds;
  
  @HiveField(3)
  bool isExpanded;

  @HiveField(4)
  int position;

  Folder({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.isExpanded = false,
    this.position = 0,
  });

  // Convert the folder to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'isExpanded': isExpanded,
    'position': position,
  };

  // Create a folder from a JSON map
  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    songIds: List<String>.from(json['songIds'] ?? []),
    isExpanded: json['isExpanded'] ?? false,
    position: json['position'] ?? 0,
  );
}

class FolderProvider with ChangeNotifier {
  final List<Folder> _folders = [];
  final StorageService _storageService = StorageService.instance;
  bool _isInitialized = false;

  List<Folder> get folders => _folders;
  bool get isInitialized => _isInitialized;

  /// Check if premium is unlocked via IAP
  /// GitHub and F-Droid flavors are always unlimited
  bool get isPremiumUnlocked {
    // Only Google Play flavor uses IAP; GitHub/F-Droid are always unlocked
    if (!AppConfig.isGooglePlayRelease) return true;

    return IAPService.instance.isPremium;
  }

  /// Check if the folder limit is reached
  bool isFolderLimitReached() {
    // GitHub and F-Droid are always unrestricted
    if (AppConfig.isFdroidRelease || AppConfig.isGitHubRelease) return false;

    // Google Play: restricted unless premium unlocked
    return AppConfig.isGooglePlayRelease && !isPremiumUnlocked && _folders.length >= 2;
  }

  /// Check if the song limit is reached for a specific folder
  bool isSongLimitReached(String folderId) {
    // GitHub and F-Droid are always unrestricted
    if (AppConfig.isFdroidRelease || AppConfig.isGitHubRelease) return false;

    // Google Play: restricted unless premium unlocked
    if (AppConfig.isGooglePlayRelease && !isPremiumUnlocked) {
      final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
      if (folderIndex != -1) {
        return _folders[folderIndex].songIds.length >= 6;
      }
    }
    return false;
  }

  /// Show the folder limit dialog
  void showFolderLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limit Reached'),
          content: const Text('You have reached the limit of 2 folders. To add more, please upgrade to the premium version.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            if (AppConfig.isGooglePlayRelease)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await IAPService.instance.buyPremium();
                },
                child: const Text('Upgrade'),
              ),
          ],
        );
      },
    );
  }

  /// Show the song limit dialog
  void showSongLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limit Reached'),
          content: const Text('You have reached the limit of 6 songs per folder. To add more, please upgrade to the premium version.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            if (AppConfig.isGooglePlayRelease)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await IAPService.instance.buyPremium();
                },
                child: const Text('Upgrade'),
              ),
          ],
        );
      },
    );
  }

  /// Initialize the provider by loading folders from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📁 ===== FOLDERPROVIDER INITIALIZATION STARTED =====');

      // Initialize storage service if not already done
      debugPrint('📁 Initializing storage service...');
      await _storageService.initialize();
      debugPrint('📁 Storage service initialized');

      // Listen to IAPService premium status changes
      if (AppConfig.isGooglePlayRelease) {
        IAPService.instance.addListener(_onPremiumChanged);
      }

      // Load folders from storage
      debugPrint('📁 Loading folders from storage...');
      final storedFolders = _storageService.getAllFolders();
      debugPrint('📁 Loaded ${storedFolders.length} folders from storage');

      // Sort folders by position
      storedFolders.sort((a, b) => a.position.compareTo(b.position));

      _folders.clear();
      _folders.addAll(storedFolders);

      // Log each folder for debugging
      if (_folders.isNotEmpty) {
        debugPrint('📁 Folders in provider:');
        for (int i = 0; i < _folders.length; i++) {
          final folder = _folders[i];
          debugPrint('📁   $i: "${folder.name}" (ID: ${folder.id}) - Songs: ${folder.songIds.length} - Expanded: ${folder.isExpanded} - Position: ${folder.position}');
        }
      } else {
        debugPrint('📁 No folders found in storage');
      }

      _isInitialized = true;

      // Collapse all folders by default on initialization
      if (_folders.isNotEmpty) {
        for (int i = 0; i < _folders.length; i++) {
          _folders[i] = Folder(
            id: _folders[i].id,
            name: _folders[i].name,
            songIds: _folders[i].songIds,
            isExpanded: false,
            position: _folders[i].position,
          );
        }
        debugPrint('📁 All folders collapsed by default');
      } else {
        debugPrint('📁 No folders found in storage');
      }

      debugPrint('✅ FolderProvider initialized with ${_folders.length} folders');
      debugPrint('📁 ===== FOLDERPROVIDER INITIALIZATION COMPLETED =====');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize FolderProvider: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Continue with empty list if storage fails
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Called when premium status changes
  void _onPremiumChanged() {
    notifyListeners();
  }

  void addFolder(Folder folder) {
    // Safeguard check (UI should handle this for instant feedback)
    if (isFolderLimitReached()) {
      return;
    }

    // Set position to the end of the list
    final newFolder = Folder(
      id: folder.id,
      name: folder.name,
      songIds: folder.songIds,
      isExpanded: folder.isExpanded,
      position: _folders.length,
    );
    
    _folders.add(newFolder);
    _saveFolderToStorage(newFolder);
    notifyListeners();
  }

  Future<void> removeFolder(String folderId) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      _folders.removeAt(index);
      await _deleteFolderFromStorage(folderId);
      
      // Update positions of remaining folders
      await _updateFolderPositions();
      
      notifyListeners();
    }
  }

  void updateFolder(Folder updatedFolder) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == updatedFolder.id);
    if (folderIndex != -1) {
      final updated = Folder(
        id: updatedFolder.id,
        name: updatedFolder.name,
        songIds: updatedFolder.songIds,
        isExpanded: updatedFolder.isExpanded,
        position: _folders[folderIndex].position, // Preserve position
      );
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  void addSongToFolder(String folderId, String songId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      // Safeguard check (UI should handle this for instant feedback)
      if (isSongLimitReached(folderId)) {
        return;
      }

      final updatedFolder = Folder(
        id: _folders[folderIndex].id,
        name: _folders[folderIndex].name,
        songIds: [..._folders[folderIndex].songIds, songId],
        isExpanded: _folders[folderIndex].isExpanded,
        position: _folders[folderIndex].position,
      );
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void removeSongFromFolder(String folderId, String songId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      final updatedFolder = Folder(
        id: _folders[folderIndex].id,
        name: _folders[folderIndex].name,
        songIds: _folders[folderIndex].songIds.where((id) => id != songId).toList(),
        isExpanded: _folders[folderIndex].isExpanded,
        position: _folders[folderIndex].position,
      );
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void toggleFolderExpansion(String folderId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      final bool wasExpanded = _folders[folderIndex].isExpanded;

      // Update all folders in memory only - no storage operations
      // Collapse all folders
      for (int i = 0; i < _folders.length; i++) {
        _folders[i] = Folder(
          id: _folders[i].id,
          name: _folders[i].name,
          songIds: _folders[i].songIds,
          isExpanded: false,
          position: _folders[i].position,
        );
      }

      // If the clicked folder was not expanded, expand it now
      // (If it was expanded, it stays collapsed, allowing all folders to be closed)
      if (!wasExpanded) {
        _folders[folderIndex] = Folder(
          id: _folders[folderIndex].id,
          name: _folders[folderIndex].name,
          songIds: _folders[folderIndex].songIds,
          isExpanded: true,
          position: _folders[folderIndex].position,
        );
      }
       
      // Notify listeners - expansion state is kept in memory only
      notifyListeners();
    }
  }

  // ========== STORAGE OPERATIONS ==========

  /// Save a folder to storage (with fallback to in-memory on error)
  Future<void> _saveFolderToStorage(Folder folder) async {
    if (!_isInitialized) return; // Skip if not initialized yet

    try {
      await _storageService.saveFolder(folder);
    } catch (e) {
      debugPrint('⚠️ Failed to save folder to storage: $e');
      // Continue without storage - data will be lost on app restart
    }
  }

  /// Update positions of all folders after reordering or removal
  Future<void> _updateFolderPositions() async {
    for (int i = 0; i < _folders.length; i++) {
      _folders[i] = Folder(
        id: _folders[i].id,
        name: _folders[i].name,
        songIds: _folders[i].songIds,
        isExpanded: _folders[i].isExpanded,
        position: i,
      );
      await _saveFolderToStorage(_folders[i]);
    }
  }


  /// Delete a folder from storage (with fallback to in-memory on error)
  Future<void> _deleteFolderFromStorage(String folderId) async {
    if (!_isInitialized) return; // Skip if not initialized yet

    try {
      await _storageService.deleteFolder(folderId);
    } catch (e) {
      debugPrint('⚠️ Failed to delete folder from storage: $e');
      // Continue without storage
    }
  }

  /// Clear all folders from storage
  Future<void> clearAllFolders() async {
    try {
      await _storageService.clearFolders();
      _folders.clear();
      debugPrint('🧹 Cleared all folders from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear folders from storage: $e');
    }
  }

  /// Reorder folders and update their positions
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);
    
    // Update positions
    await _updateFolderPositions();
    
    notifyListeners();
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getStorageStats();
  }
}