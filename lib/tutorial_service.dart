import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service class to manage tutorial/onboarding state
class TutorialService {
  static const String _boxName = 'tutorial';
  static const String _tutorialShownKey = 'onboarding_shown';

  static TutorialService? _instance;
  static TutorialService get instance => _instance ??= TutorialService._();

  TutorialService._();

  Box? _box;
  bool _isInitialized = false;

  /// Initialize the tutorial service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
      if (kDebugMode) debugPrint('✅ TutorialService initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to initialize TutorialService: $e');
      _isInitialized = false;
    }
  }

  /// Check if the tutorial should be shown (first run)
  bool get shouldShowTutorial {
    if (!_isInitialized || _box == null) {
      if (kDebugMode) debugPrint('⚠️ TutorialService not initialized, defaulting to show tutorial');
      return true;
    }
    return !(_box?.get(_tutorialShownKey, defaultValue: false) ?? false);
  }

  /// Mark the tutorial as shown
  Future<void> markTutorialShown() async {
    if (!_isInitialized || _box == null) {
      if (kDebugMode) debugPrint('⚠️ TutorialService not initialized, cannot mark tutorial as shown');
      return;
    }

    try {
      await _box?.put(_tutorialShownKey, true);
      if (kDebugMode) debugPrint('✅ Tutorial marked as shown');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to mark tutorial as shown: $e');
    }
  }

  /// Reset the tutorial (for testing or user request)
  Future<void> resetTutorial() async {
    if (!_isInitialized || _box == null) {
      if (kDebugMode) debugPrint('⚠️ TutorialService not initialized, cannot reset tutorial');
      return;
    }

    try {
      await _box?.put(_tutorialShownKey, false);
      if (kDebugMode) debugPrint('✅ Tutorial reset');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to reset tutorial: $e');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
