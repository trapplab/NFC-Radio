import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

/// Service to manage tutorial state persistence
class TutorialService {
  static const String _boxName = 'tutorial_status';
  static const String _keyShown = 'tutorial_shown';

  TutorialService._();

  static final TutorialService instance = TutorialService._();

  bool _initialized = false;
  bool _shouldShowTutorial = true;

  /// Initialize the tutorial service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final box = await Hive.openBox(_boxName);
      _shouldShowTutorial = !(box.get(_keyShown, defaultValue: false) as bool);
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize tutorial service: $e');
      _shouldShowTutorial = true;
      _initialized = true;
    }
  }

  /// Check if tutorial should be shown
  bool get shouldShowTutorial => _shouldShowTutorial;

  /// Mark tutorial as shown
  Future<void> markTutorialShown() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_keyShown, true);
      _shouldShowTutorial = false;
    } catch (e) {
      debugPrint('Failed to mark tutorial as shown: $e');
    }
  }

  /// Reset tutorial state (for testing/development)
  Future<void> resetTutorial() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_keyShown);
      _shouldShowTutorial = true;
    } catch (e) {
      debugPrint('Failed to reset tutorial: $e');
    }
  }
}
