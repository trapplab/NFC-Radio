import 'package:flutter/material.dart';
import '../storage/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyFilterAudioOnly = 'filter_audio_only';
  static const String _keyUseSystemOverlay = 'use_system_overlay';
  static const String _keyShowAudioControlsOnLockscreen = 'show_audio_controls_on_lockscreen';
  static const String _keySleepTimerDurationMinutes = 'sleep_timer_duration_minutes';
  static const String _keyAutoSleepTimerEnabled = 'auto_sleep_timer_enabled';
  static const String _keyAutoSleepTimerRestrictHours = 'auto_sleep_timer_restrict_hours';
  static const String _keyAutoSleepTimerStartHour = 'auto_sleep_timer_start_hour';
  static const String _keyAutoSleepTimerEndHour = 'auto_sleep_timer_end_hour';

  bool _filterAudioOnly = true;
  bool _useSystemOverlay = false;
  bool _showAudioControlsOnLockscreen = false;
  int _sleepTimerDurationMinutes = 30;
  bool _autoSleepTimerEnabled = false;
  bool _autoSleepTimerRestrictHours = false;
  int _autoSleepTimerStartHour = 19;
  int _autoSleepTimerEndHour = 6;
  bool _isInitialized = false;

  bool get filterAudioOnly => _filterAudioOnly;
  bool get useSystemOverlay => _useSystemOverlay;
  bool get showAudioControlsOnLockscreen => _showAudioControlsOnLockscreen;
  int get sleepTimerDurationMinutes => _sleepTimerDurationMinutes;
  bool get autoSleepTimerEnabled => _autoSleepTimerEnabled;
  bool get autoSleepTimerRestrictHours => _autoSleepTimerRestrictHours;
  int get autoSleepTimerStartHour => _autoSleepTimerStartHour;
  int get autoSleepTimerEndHour => _autoSleepTimerEndHour;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _filterAudioOnly = StorageService.instance.getSetting(_keyFilterAudioOnly, defaultValue: true);
    _useSystemOverlay = StorageService.instance.getSetting(_keyUseSystemOverlay, defaultValue: false);
    _showAudioControlsOnLockscreen = StorageService.instance.getSetting(_keyShowAudioControlsOnLockscreen, defaultValue: false);
    _sleepTimerDurationMinutes = StorageService.instance.getSetting(_keySleepTimerDurationMinutes, defaultValue: 30);
    _autoSleepTimerEnabled = StorageService.instance.getSetting(_keyAutoSleepTimerEnabled, defaultValue: false);
    _autoSleepTimerRestrictHours = StorageService.instance.getSetting(_keyAutoSleepTimerRestrictHours, defaultValue: false);
    _autoSleepTimerStartHour = StorageService.instance.getSetting(_keyAutoSleepTimerStartHour, defaultValue: 19);
    _autoSleepTimerEndHour = StorageService.instance.getSetting(_keyAutoSleepTimerEndHour, defaultValue: 6);
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

  Future<void> setSleepTimerDurationMinutes(int value) async {
    _sleepTimerDurationMinutes = value;
    await StorageService.instance.saveSetting(_keySleepTimerDurationMinutes, value);
    notifyListeners();
  }

  Future<void> setAutoSleepTimerEnabled(bool value) async {
    _autoSleepTimerEnabled = value;
    await StorageService.instance.saveSetting(_keyAutoSleepTimerEnabled, value);
    notifyListeners();
  }

  Future<void> setAutoSleepTimerRestrictHours(bool value) async {
    _autoSleepTimerRestrictHours = value;
    await StorageService.instance.saveSetting(_keyAutoSleepTimerRestrictHours, value);
    notifyListeners();
  }

  Future<void> setAutoSleepTimerStartHour(int value) async {
    _autoSleepTimerStartHour = value;
    await StorageService.instance.saveSetting(_keyAutoSleepTimerStartHour, value);
    notifyListeners();
  }

  Future<void> setAutoSleepTimerEndHour(int value) async {
    _autoSleepTimerEndHour = value;
    await StorageService.instance.saveSetting(_keyAutoSleepTimerEndHour, value);
    notifyListeners();
  }
}
