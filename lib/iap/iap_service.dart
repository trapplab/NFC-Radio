import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub service for managing in-app purchases (IAP) for non-Google Play flavors.
/// This implementation has no dependencies on the in_app_purchase package.
class IAPService with ChangeNotifier {
  // Singleton instance
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // Public instance getter
  static IAPService get instance => _instance;

  // State
  final bool _isAvailable = false;
  final bool _isPremium = true; // All non-Google Play flavors have unlimited access
  final bool _isLoading = false;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  /// Initialize the IAP service (no-op for stub)
  Future<void> initialize() async {
    debugPrint('ℹ️ IAP Service (Stub) initialized. Premium: $_isPremium');
  }

  /// Buy the premium upgrade (no-op for stub)
  Future<bool> buyPremium() async {
    debugPrint('ℹ️ IAP not available for this flavor');
    return false;
  }

  /// Clean up resources
  @override
  void dispose() {
    super.dispose();
  }

  /// Debug function to unlock premium (no-op for stub as it's always premium)
  void debugUnlockPremium() async {
    debugPrint('ℹ️ Premium already unlocked for this flavor');
  }

  /// Refresh premium status (no-op for stub)
  Future<void> refreshPremiumStatus() async {
    notifyListeners();
  }
}
