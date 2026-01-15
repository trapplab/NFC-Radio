import 'package:flutter/material.dart';
import 'storage_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyFilterAudioOnly = 'filter_audio_only';
  
  bool _filterAudioOnly = false;
  bool _isInitialized = false;

  bool get filterAudioOnly => _filterAudioOnly;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _filterAudioOnly = StorageService.instance.getSetting(_keyFilterAudioOnly, defaultValue: false);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setFilterAudioOnly(bool value) async {
    _filterAudioOnly = value;
    await StorageService.instance.saveSetting(_keyFilterAudioOnly, value);
    notifyListeners();
  }
}
