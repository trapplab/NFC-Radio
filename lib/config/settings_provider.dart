import 'package:flutter/material.dart';
import '../storage/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyFilterAudioOnly = 'filter_audio_only';
  static const String _keyUseSystemOverlay = 'use_system_overlay';
  static const String _keyShowAudioControlsOnLockscreen = 'show_audio_controls_on_lockscreen';
  
  bool _filterAudioOnly = true;
  bool _useSystemOverlay = false;
  bool _showAudioControlsOnLockscreen = false;
  bool _isInitialized = false;

  bool get filterAudioOnly => _filterAudioOnly;
  bool get useSystemOverlay => _useSystemOverlay;
  bool get showAudioControlsOnLockscreen => _showAudioControlsOnLockscreen;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _filterAudioOnly = StorageService.instance.getSetting(_keyFilterAudioOnly, defaultValue: true);
    _useSystemOverlay = StorageService.instance.getSetting(_keyUseSystemOverlay, defaultValue: false);
    _showAudioControlsOnLockscreen = StorageService.instance.getSetting(_keyShowAudioControlsOnLockscreen, defaultValue: false);
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

  Future<void> setShowAudioControlsOnLockscreen(bool value) async {
    _showAudioControlsOnLockscreen = value;
    await StorageService.instance.saveSetting(_keyShowAudioControlsOnLockscreen, value);
    notifyListeners();
  }
}
