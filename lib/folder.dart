import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'storage_service.dart';

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

  Folder({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.isExpanded = false,
  });

  // Convert the folder to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'isExpanded': isExpanded,
  };

  // Create a folder from a JSON map
  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    songIds: List<String>.from(json['songIds'] ?? []),
    isExpanded: json['isExpanded'] ?? false,
  );
}

class FolderProvider with ChangeNotifier {
  final List<Folder> _folders = [];
  final StorageService _storageService = StorageService.instance;
  bool _isInitialized = false;

  List<Folder> get folders => _folders;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading folders from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📁 ===== FOLDERPROVIDER INITIALIZATION STARTED =====');

      // Initialize storage service if not already done
      debugPrint('📁 Initializing storage service...');
      await _storageService.initialize();
      debugPrint('📁 Storage service initialized');

      // Load folders from storage
      debugPrint('📁 Loading folders from storage...');
      final storedFolders = _storageService.getAllFolders();
      debugPrint('📁 Loaded ${storedFolders.length} folders from storage');

      _folders.clear();
      _folders.addAll(storedFolders);

      // Log each folder for debugging
      if (_folders.isNotEmpty) {
        debugPrint('📁 Folders in provider:');
        for (int i = 0; i < _folders.length; i++) {
          final folder = _folders[i];
          debugPrint('📁   $i: "${folder.name}" (ID: ${folder.id}) - Songs: ${folder.songIds.length} - Expanded: ${folder.isExpanded}');
        }
      } else {
        debugPrint('📁 No folders found in storage');
      }

      _isInitialized = true;
      
      // Ensure EXACTLY one folder is expanded by default (radio button behavior)
      if (_folders.isNotEmpty) {
        // First, collapse all folders to ensure a clean state
        for (int i = 0; i < _folders.length; i++) {
          _folders[i] = Folder(
            id: _folders[i].id,
            name: _folders[i].name,
            songIds: _folders[i].songIds,
            isExpanded: false,
          );
        }
        
        // Then expand only the first one
        _folders[0] = Folder(
          id: _folders[0].id,
          name: _folders[0].name,
          songIds: _folders[0].songIds,
          isExpanded: true,
        );
        debugPrint('📁 Defaulted first folder to expanded and collapsed all others');
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

  void addFolder(Folder folder) {
    // If this is the first folder, make it expanded by default
    if (_folders.isEmpty) {
      folder = Folder(
        id: folder.id,
        name: folder.name,
        songIds: folder.songIds,
        isExpanded: true,
      );
    }
    _folders.add(folder);
    _saveFolderToStorage(folder);
    notifyListeners();
  }

  void removeFolder(String folderId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      final wasExpanded = _folders[index].isExpanded;
      _folders.removeAt(index);
      _deleteFolderFromStorage(folderId);
      
      // If we removed the expanded folder, expand the first available one
      if (wasExpanded && _folders.isNotEmpty) {
        _folders[0] = Folder(
          id: _folders[0].id,
          name: _folders[0].name,
          songIds: _folders[0].songIds,
          isExpanded: true,
        );
      }
      notifyListeners();
    }
  }

  void updateFolder(Folder updatedFolder) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == updatedFolder.id);
    if (folderIndex != -1) {
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void addSongToFolder(String folderId, String songId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      final updatedFolder = Folder(
        id: _folders[folderIndex].id,
        name: _folders[folderIndex].name,
        songIds: [..._folders[folderIndex].songIds, songId],
        isExpanded: _folders[folderIndex].isExpanded,
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
      );
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void toggleFolderExpansion(String folderId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      // Update all folders in memory only - no storage operations
      // Collapse all other folders
      for (int i = 0; i < _folders.length; i++) {
        if (i != folderIndex) {
          final collapsedFolder = Folder(
            id: _folders[i].id,
            name: _folders[i].name,
            songIds: _folders[i].songIds,
            isExpanded: false,
          );
          _folders[i] = collapsedFolder;
        }
      }

      // Set the selected folder to expanded (radio button behavior - cannot be closed by clicking)
      final updatedFolder = Folder(
        id: _folders[folderIndex].id,
        name: _folders[folderIndex].name,
        songIds: _folders[folderIndex].songIds,
        isExpanded: true,
      );
      _folders[folderIndex] = updatedFolder;
      
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
      debugPrint('🧹 Cleared all folders from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear folders from storage: $e');
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getStorageStats();
  }
}