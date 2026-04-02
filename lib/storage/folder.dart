import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../l10n/app_localizations.dart';
import 'storage_service.dart';
import '../config/config.dart';
import '../iap/iap_service.dart';

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

  @HiveField(5)
  String? connectedNfcUuid;

  @HiveField(6)
  bool isShuffleEnabled;

  @HiveField(7)
  bool isLoopPlaylistEnabled;

  @HiveField(8)
  int? lastPlayedSongIndex;

  @HiveField(9)
  int? lastPlayedPositionMs;

  @HiveField(10)
  bool nfcSkipsToNext;

  @HiveField(11)
  String? parentFolderId;

  Folder({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.isExpanded = false,
    this.position = 0,
    this.connectedNfcUuid,
    this.isShuffleEnabled = false,
    this.isLoopPlaylistEnabled = false,
    this.lastPlayedSongIndex,
    this.lastPlayedPositionMs,
    this.nfcSkipsToNext = false,
    this.parentFolderId,
  });

  Folder copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    bool? isExpanded,
    int? position,
    String? Function()? connectedNfcUuid,
    bool? isShuffleEnabled,
    bool? isLoopPlaylistEnabled,
    int? Function()? lastPlayedSongIndex,
    int? Function()? lastPlayedPositionMs,
    bool? nfcSkipsToNext,
    String? Function()? parentFolderId,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      isExpanded: isExpanded ?? this.isExpanded,
      position: position ?? this.position,
      connectedNfcUuid: connectedNfcUuid != null
          ? connectedNfcUuid()
          : this.connectedNfcUuid,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isLoopPlaylistEnabled:
          isLoopPlaylistEnabled ?? this.isLoopPlaylistEnabled,
      lastPlayedSongIndex: lastPlayedSongIndex != null
          ? lastPlayedSongIndex()
          : this.lastPlayedSongIndex,
      lastPlayedPositionMs: lastPlayedPositionMs != null
          ? lastPlayedPositionMs()
          : this.lastPlayedPositionMs,
      nfcSkipsToNext: nfcSkipsToNext ?? this.nfcSkipsToNext,
      parentFolderId: parentFolderId != null
          ? parentFolderId()
          : this.parentFolderId,
    );
  }

  // Convert the folder to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'isExpanded': isExpanded,
    'position': position,
    'connectedNfcUuid': connectedNfcUuid,
    'isShuffleEnabled': isShuffleEnabled,
    'isLoopPlaylistEnabled': isLoopPlaylistEnabled,
    'lastPlayedSongIndex': lastPlayedSongIndex,
    'lastPlayedPositionMs': lastPlayedPositionMs,
    'nfcSkipsToNext': nfcSkipsToNext,
    'parentFolderId': parentFolderId,
  };

  // Create a folder from a JSON map
  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    songIds: List<String>.from(json['songIds'] ?? []),
    isExpanded: json['isExpanded'] ?? false,
    position: json['position'] ?? 0,
    connectedNfcUuid: json['connectedNfcUuid'],
    isShuffleEnabled: json['isShuffleEnabled'] ?? false,
    isLoopPlaylistEnabled: json['isLoopPlaylistEnabled'] ?? false,
    lastPlayedSongIndex: json['lastPlayedSongIndex'],
    lastPlayedPositionMs: json['lastPlayedPositionMs'],
    nfcSkipsToNext: json['nfcSkipsToNext'] ?? false,
    parentFolderId: json['parentFolderId'],
  );
}

class FolderProvider with ChangeNotifier {
  final List<Folder> _folders = [];
  final StorageService _storageService = StorageService.instance;
  bool _isInitialized = false;

  List<Folder> get folders => _folders;
  bool get isInitialized => _isInitialized;

  // ========== HIERARCHY HELPERS ==========

  /// Root-level folders (no parent), sorted by position
  List<Folder> get rootFolders =>
      (_folders.where((f) => f.parentFolderId == null).toList()
        ..sort((a, b) => a.position.compareTo(b.position)));

  /// Child folders of a given parent, sorted by position
  List<Folder> getChildFolders(String parentId) =>
      (_folders.where((f) => f.parentFolderId == parentId).toList()
        ..sort((a, b) => a.position.compareTo(b.position)));

  /// Returns true if the folder has at least one child subfolder
  bool isGroupFolder(String folderId) =>
      _folders.any((f) => f.parentFolderId == folderId);

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
    return AppConfig.isGooglePlayRelease &&
        !isPremiumUnlocked &&
        _folders.length >= 2;
  }

  /// Check if the song limit is reached for a specific folder
  bool isSongLimitReached(String folderId) {
    // GitHub and F-Droid are always unrestricted
    if (AppConfig.isFdroidRelease || AppConfig.isGitHubRelease) return false;

    // Google Play: restricted unless premium unlocked
    if (AppConfig.isGooglePlayRelease && !isPremiumUnlocked) {
      final folderIndex = _folders.indexWhere(
        (folder) => folder.id == folderId,
      );
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
          title: Text(AppLocalizations.of(context)!.limitReached),
          content: Text(AppLocalizations.of(context)!.folderLimitReached),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            if (AppConfig.isGooglePlayRelease)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await IAPService.instance.buyPremium();
                },
                child: Text(AppLocalizations.of(context)!.upgrade),
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
          title: Text(AppLocalizations.of(context)!.limitReached),
          content: Text(AppLocalizations.of(context)!.songLimitReached),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            if (AppConfig.isGooglePlayRelease)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await IAPService.instance.buyPremium();
                },
                child: Text(AppLocalizations.of(context)!.upgrade),
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
          debugPrint(
            '📁   $i: "${folder.name}" (ID: ${folder.id}) - Songs: ${folder.songIds.length} - Expanded: ${folder.isExpanded} - Position: ${folder.position}',
          );
        }
      } else {
        debugPrint('📁 No folders found in storage');
      }

      _isInitialized = true;

      debugPrint(
        '✅ FolderProvider initialized with ${_folders.length} folders',
      );
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
    final newFolder = folder.copyWith(position: _folders.length);

    _folders.add(newFolder);
    _saveFolderToStorage(newFolder);
    notifyListeners();
  }

  /// Remove a folder and all its child subfolders from storage.
  /// Returns the IDs of all removed folders (including children) so the caller
  /// can clean up songs and NFC mappings.
  Future<List<String>> removeFolder(String folderId) async {
    final removedIds = <String>[];

    // Remove children first (subfolders of this folder)
    final children = getChildFolders(folderId);
    for (final child in children) {
      final childIndex = _folders.indexWhere((f) => f.id == child.id);
      if (childIndex != -1) {
        _folders.removeAt(childIndex);
        await _deleteFolderFromStorage(child.id);
        removedIds.add(child.id);
      }
    }

    // Remove the folder itself
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      _folders.removeAt(index);
      await _deleteFolderFromStorage(folderId);
      removedIds.add(folderId);
    }

    // Update positions of remaining root folders
    await _updateFolderPositions();

    notifyListeners();
    return removedIds;
  }

  /// Add a subfolder inside a parent (group) folder.
  void addSubFolder(String parentFolderId, Folder subfolder) {
    if (isFolderLimitReached()) return;

    // Position = number of existing children
    final childCount = getChildFolders(parentFolderId).length;
    final newSubfolder = Folder(
      id: subfolder.id,
      name: subfolder.name,
      songIds: const [],
      isExpanded: false,
      position: childCount,
      parentFolderId: parentFolderId,
    );
    _folders.add(newSubfolder);
    _saveFolderToStorage(newSubfolder);
    notifyListeners();
  }

  /// Reorder subfolders within a group
  Future<void> reorderSubFolders(
    String parentId,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) newIndex -= 1;

    // Work on only the children of this parent
    final children = getChildFolders(parentId);
    final moved = children.removeAt(oldIndex);
    children.insert(newIndex, moved);

    // Update positions for those children
    for (int i = 0; i < children.length; i++) {
      final idx = _folders.indexWhere((f) => f.id == children[i].id);
      if (idx != -1) {
        _folders[idx] = _folders[idx].copyWith(position: i);
        await _saveFolderToStorage(_folders[idx]);
      }
    }
    notifyListeners();
  }

  void updateFolder(Folder updatedFolder) {
    final folderIndex = _folders.indexWhere(
      (folder) => folder.id == updatedFolder.id,
    );
    if (folderIndex != -1) {
      final updated = updatedFolder.copyWith(
        position: _folders[folderIndex].position,
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

      final updatedFolder = _folders[folderIndex].copyWith(
        songIds: [..._folders[folderIndex].songIds, songId],
      );
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void removeSongFromFolder(String folderId, String songId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      final updatedFolder = _folders[folderIndex].copyWith(
        songIds: _folders[folderIndex].songIds
            .where((id) => id != songId)
            .toList(),
      );
      _folders[folderIndex] = updatedFolder;
      _saveFolderToStorage(updatedFolder);
      notifyListeners();
    }
  }

  void toggleFolderExpansion(String folderId) {
    final folderIndex = _folders.indexWhere((folder) => folder.id == folderId);
    if (folderIndex != -1) {
      final updatedFolder = _folders[folderIndex].copyWith(
        isExpanded: !_folders[folderIndex].isExpanded,
      );
      _folders[folderIndex] = updatedFolder;

      _saveFolderToStorage(updatedFolder);

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

  /// Update positions of root-level folders after reordering or removal.
  /// Child folder positions are managed separately within their parent.
  Future<void> _updateFolderPositions() async {
    final roots = rootFolders;
    for (int i = 0; i < roots.length; i++) {
      final idx = _folders.indexWhere((f) => f.id == roots[i].id);
      if (idx != -1) {
        _folders[idx] = _folders[idx].copyWith(position: i);
        await _saveFolderToStorage(_folders[idx]);
      }
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

  /// Reorder root-level folders and update their positions.
  /// Indices refer to positions within the root folders list.
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;

    final roots = rootFolders;
    if (oldIndex >= roots.length || newIndex >= roots.length) return;

    // Find global indices for the two root folders
    final movedId = roots[oldIndex].id;
    final movedGlobalIdx = _folders.indexWhere((f) => f.id == movedId);
    if (movedGlobalIdx == -1) return;

    final folder = _folders.removeAt(movedGlobalIdx);

    // Recalculate insertion point in global list based on new root position
    final targetId = roots[newIndex].id;
    final targetGlobalIdx = _folders.indexWhere((f) => f.id == targetId);
    final insertAt = targetGlobalIdx == -1
        ? _folders.length
        : (oldIndex < newIndex ? targetGlobalIdx + 1 : targetGlobalIdx);
    _folders.insert(insertAt, folder);

    // Update positions
    await _updateFolderPositions();

    notifyListeners();
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getStorageStats();
  }

  // ========== FOLDER NFC & PLAYLIST OPERATIONS ==========

  void connectFolderToNfc(String folderId, String nfcUuid) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(
        connectedNfcUuid: () => nfcUuid,
      );
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  void disconnectFolderFromNfc(String folderId) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(
        connectedNfcUuid: () => null,
      );
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  void updateFolderPlaybackState(
    String folderId, {
    int? lastPlayedSongIndex,
    int? lastPlayedPositionMs,
  }) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(
        lastPlayedSongIndex: () => lastPlayedSongIndex,
        lastPlayedPositionMs: () => lastPlayedPositionMs,
      );
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      // Don't notify listeners to avoid UI flicker during playback
    }
  }

  void updateFolderShuffle(String folderId, bool value) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(isShuffleEnabled: value);
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  void updateFolderLoop(String folderId, bool value) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(
        isLoopPlaylistEnabled: value,
      );
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  void updateFolderNfcSkipsToNext(String folderId, bool value) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updated = _folders[folderIndex].copyWith(nfcSkipsToNext: value);
      _folders[folderIndex] = updated;
      _saveFolderToStorage(updated);
      notifyListeners();
    }
  }

  Folder? findFolderByNfcUuid(String nfcUuid) {
    return _folders.firstWhereOrNull((f) => f.connectedNfcUuid == nfcUuid);
  }

  // ========== SONG MOVE & COPY OPERATIONS ==========

  /// Check for conflicts when moving/copying a song to a target folder
  /// Returns MoveResult with conflict info if any issues found, null if all clear
  MoveResult? _checkMoveConflicts(
    String songId,
    String toFolderId,
    List<dynamic> songs,
  ) {
    // Check if target folder has song limit
    if (isSongLimitReached(toFolderId)) {
      return MoveResult(success: false, reason: MoveFailureReason.songLimit);
    }

    // Check if song already exists in target folder
    final toFolderIndex = _folders.indexWhere((f) => f.id == toFolderId);
    if (toFolderIndex != -1) {
      final toFolder = _folders[toFolderIndex];
      if (toFolder.songIds.contains(songId)) {
        return MoveResult(success: false, reason: MoveFailureReason.duplicate);
      }
    }

    // Check for NFC conflict
    final song = songs.firstWhereOrNull((s) => s.id == songId);
    if (song != null && song.connectedNfcUuid != null) {
      if (toFolderIndex != -1) {
        final toFolder = _folders[toFolderIndex];
        final conflictingSongId = toFolder.songIds.firstWhereOrNull((id) {
          final folderSong = songs.firstWhereOrNull((s) => s.id == id);
          return folderSong != null &&
              folderSong.connectedNfcUuid == song.connectedNfcUuid;
        });

        if (conflictingSongId != null) {
          return MoveResult(
            success: false,
            reason: MoveFailureReason.nfcConflict,
            conflictingSongId: conflictingSongId,
          );
        }
      }
    }

    return null; // No conflicts
  }

  /// Move a song from one folder to another
  /// Returns MoveResult with success status and optional conflict info
  Future<MoveResult> moveSongToFolder(
    String songId,
    String fromFolderId,
    String toFolderId,
    List<dynamic> songs,
  ) async {
    // Check for conflicts
    final conflict = _checkMoveConflicts(songId, toFolderId, songs);
    if (conflict != null) return conflict;

    // Remove from source folder
    removeSongFromFolder(fromFolderId, songId);

    // Add to target folder
    addSongToFolder(toFolderId, songId);

    return MoveResult(success: true);
  }

  /// Copy a song to another folder (keeps song in both folders)
  /// Returns MoveResult with success status and optional conflict info
  Future<MoveResult> copySongToFolder(
    String songId,
    String toFolderId,
    List<dynamic> songs,
  ) async {
    // Check for conflicts
    final conflict = _checkMoveConflicts(songId, toFolderId, songs);
    if (conflict != null) return conflict;

    // Add to target folder (keep in source folder)
    addSongToFolder(toFolderId, songId);

    return MoveResult(success: true);
  }
}

/// Enum for move/copy failure reasons
enum MoveFailureReason { songLimit, nfcConflict, duplicate }

/// Result class for move/copy operations
class MoveResult {
  final bool success;
  final MoveFailureReason? reason;
  final String? conflictingSongId;

  MoveResult({required this.success, this.reason, this.conflictingSongId});
}
