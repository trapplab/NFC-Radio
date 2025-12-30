import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'storage_service.dart';

part 'nfc_music_mapping.g.dart';

@HiveType(typeId: 1)
class NFCMusicMapping extends HiveObject {
  @HiveField(0)
  String nfcUuid;
  @HiveField(1)
  String songId;

  NFCMusicMapping({
    required this.nfcUuid,
    required this.songId,
  });

  // Convert the mapping to a JSON map
  Map<String, dynamic> toJson() => {
    'nfcUuid': nfcUuid,
    'songId': songId,
  };

  // Create a mapping from a JSON map
  factory NFCMusicMapping.fromJson(Map<String, dynamic> json) => NFCMusicMapping(
    nfcUuid: json['nfcUuid'],
    songId: json['songId'],
  );
}

class NFCMusicMappingProvider with ChangeNotifier {
  final List<NFCMusicMapping> _mappings = [];
  final StorageService _storageService = StorageService.instance;
  bool _isInitialized = false;

  List<NFCMusicMapping> get mappings => _mappings;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading mappings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🗺️ ===== NFCMUSICMAPPINGPROVIDER INITIALIZATION STARTED =====');
      
      // Initialize storage service if not already done
      debugPrint('🗺️ Storage service already initialized');
      
      // Load mappings from storage
      debugPrint('🗺️ Loading mappings from storage...');
      final storedMappings = _storageService.getAllMappings();
      debugPrint('🗺️ Loaded ${storedMappings.length} mappings from storage');
      
      _mappings.clear();
      _mappings.addAll(storedMappings);
      
      // Log each mapping for debugging
      if (_mappings.isNotEmpty) {
        debugPrint('🗺️ Mappings in provider:');
        for (int i = 0; i < _mappings.length; i++) {
          final mapping = _mappings[i];
          debugPrint('🗺️   $i: NFC "${mapping.nfcUuid}" -> Song "${mapping.songId}"');
        }
      } else {
        debugPrint('🗺️ No mappings found in storage');
      }
      
      _isInitialized = true;
      debugPrint('✅ NFCMusicMappingProvider initialized with ${_mappings.length} mappings');
      debugPrint('🗺️ ===== NFCMUSICMAPPINGPROVIDER INITIALIZATION COMPLETED =====');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize NFCMusicMappingProvider: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Continue with empty list if storage fails
      _isInitialized = true;
      notifyListeners();
    }
  }

  void addMapping(NFCMusicMapping mapping) {
    _mappings.add(mapping);
    _saveMappingToStorage(mapping);
    notifyListeners();
  }

  void removeMapping(String nfcUuid) {
    _mappings.removeWhere((mapping) => mapping.nfcUuid == nfcUuid);
    _deleteMappingFromStorage(nfcUuid);
    notifyListeners();
  }

  String? getSongId(String nfcUuid) {
    final mapping = _mappings.firstWhere(
      (mapping) => mapping.nfcUuid == nfcUuid,
      orElse: () => NFCMusicMapping(nfcUuid: '', songId: ''),
    );
    return mapping.songId.isNotEmpty ? mapping.songId : null;
  }

  // ========== STORAGE OPERATIONS ==========

  /// Save a mapping to storage (with fallback to in-memory on error)
  Future<void> _saveMappingToStorage(NFCMusicMapping mapping) async {
    if (!_isInitialized) return; // Skip if not initialized yet
    
    try {
      await _storageService.saveMapping(mapping);
    } catch (e) {
      debugPrint('⚠️ Failed to save mapping to storage: $e');
      // Continue without storage - data will be lost on app restart
    }
  }

  /// Delete a mapping from storage (with fallback to in-memory on error)
  Future<void> _deleteMappingFromStorage(String nfcUuid) async {
    if (!_isInitialized) return; // Skip if not initialized yet
    
    try {
      await _storageService.deleteMapping(nfcUuid);
    } catch (e) {
      debugPrint('⚠️ Failed to delete mapping from storage: $e');
      // Continue without storage
    }
  }

  /// Clear all mappings from storage
  Future<void> clearAllMappings() async {
    try {
      await _storageService.clearMappings();
      debugPrint('🧹 Cleared all mappings from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear mappings from storage: $e');
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getStorageStats();
  }
}