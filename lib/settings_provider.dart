import 'package:flutter/material.dart';
import 'storage_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyFilterAudioOnly = 'filter_audio_only';
  static const String _keyUseSystemOverlay = 'use_system_overlay';
  
  bool _filterAudioOnly = true;
  bool _useSystemOverlay = false;
  bool _isInitialized = false;

  bool get filterAudioOnly => _filterAudioOnly;
  bool get useSystemOverlay => _useSystemOverlay;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _filterAudioOnly = StorageService.instance.getSetting(_keyFilterAudioOnly, defaultValue: true);
    _useSystemOverlay = StorageService.instance.getSetting(_keyUseSystemOverlay, defaultValue: false);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setFilterAudioOnly(bool value) async {
    _filterAudioOnly = value;
    await StorageService.instance.saveSetting(_keyFilterAudioOnly, value);
    notifyListeners();
  }

  Future<void> setUseSystemOverlay(bool value) async {
    _useSystemOverlay = value;
    await StorageService.instance.saveSetting(_keyUseSystemOverlay, value);
    notifyListeners();
  }
}
