// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive/hive.dart';
import '../config/flavor_config.dart';

/// Service for managing in-app purchases (IAP) for the Google Play flavor.
/// Only initialized for Google Play release; other flavors ignore IAP.
class IAPService with ChangeNotifier {
  // Singleton instance
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // Public instance getter
  static IAPService get instance => _instance;

  // Constants
  static const String _premiumBoxName = 'premium_status';
  static const String _isPremiumKey = 'is_premium';
  static const String _premiumProductId = 'nfc_radio_premium';

  // State
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _isPremium = false;
  final bool _isLoading = false;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  /// Initialize the IAP service
  /// Only works for Google Play flavor; other flavors are no-ops
  Future<void> initialize() async {
    // Only initialize for Google Play release
    if (!FlavorConfig.isPlay) {
      debugPrint('ℹ️ IAP disabled for non-Google Play flavor');
      _isPremium = true; // All non-Google Play flavors have unlimited access
      return;
    }

    // Check if IAP is available on this device
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('ℹ️ IAP not available on this device');
      return;
    }

    // Listen for purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        debugPrint('❌ IAP subscription error: $error');
      },
    );

    // Load cached premium status
    final bool hasLocalStatus = await _loadPremiumStatus();

    if (hasLocalStatus) {
      debugPrint('✅ Using cached premium status: $_isPremium');
      notifyListeners(); // Notify UI that premium status is ready
    } else {
      debugPrint('ℹ️ No local premium status found, checking Play Store...');
      // If no local status, we try to restore purchases to check if user already bought it
      await _restorePurchases();
      
      // We'll wait a bit and if still not premium, set to false.
      // Only do this if we're still not premium (don't overwrite if set by debug mode)
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isPremium) {
          debugPrint('ℹ️ No purchase found after restore attempt, setting local status to false');
          _savePremiumStatus(false);
        } else {
          debugPrint('✅ Premium status already set (possibly by debug mode), skipping false save');
        }
      });
    }

    // Verify pending purchases
    await _verifyPendingPurchases();

    debugPrint('✅ IAP Service initialized. Premium: $_isPremium');
  }

  /// Load premium status from local storage. Returns true if status was found.
  Future<bool> _loadPremiumStatus() async {
    try {
      final box = await Hive.openBox(_premiumBoxName);
      if (box.containsKey(_isPremiumKey)) {
        _isPremium = box.get(_isPremiumKey);
        debugPrint('📦 Loaded premium status from storage: $_isPremium');
        return true;
      }
      debugPrint('📦 No premium status found in storage');
      return false;
    } catch (e) {
      debugPrint('⚠️ Failed to load premium status: $e');
      _isPremium = false;
      return false;
    }
  }

  /// Save premium status to local storage and notify listeners
  Future<void> _savePremiumStatus(bool value) async {
    try {
      final box = await Hive.openBox(_premiumBoxName);
      await box.put(_isPremiumKey, value);
      // Always update the cached value when saving
      _isPremium = value;
      notifyListeners();
      debugPrint('💾 Saved premium status to storage: $value');
    } catch (e) {
      debugPrint('⚠️ Failed to save premium status: $e');
    }
  }

  /// Handle purchase updates from Google Play
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify the purchase
        final bool valid = _verifyPurchase(purchaseDetails);
        if (valid) {
          _savePremiumStatus(true);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase error: ${purchaseDetails.error?.message}');
      }

      // Complete the purchase if it's pending
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify a purchase (simplified version - in production, verify with server)
  bool _verifyPurchase(PurchaseDetails purchase) {
    // For now, we trust Google Play's verification
    // In production, you should verify with your backend server
    if (purchase.productID == _premiumProductId) {
      return purchase.status == PurchaseStatus.purchased ||
             purchase.status == PurchaseStatus.restored;
    }
    return false;
  }

  /// Verify any pending purchases on startup
  Future<void> _verifyPendingPurchases() async {
    // Note: In the newer in_app_purchase API, past purchases are handled
    // automatically through the purchaseStream. We rely on the cached status
    // and the restorePurchases() method for manual verification.
    // For production, consider server-side verification.
    debugPrint('ℹ️ IAP pending verification skipped (using cached status)');
  }

  /// Buy the premium upgrade
  /// In debug mode, this will use debugUnlockPremium instead of actual purchase
  Future<bool> buyPremium() async {
    if (!FlavorConfig.isPlay) {
      debugPrint('ℹ️ IAP not available for non-Google Play flavor');
      return false;
    }

    // In debug mode, use debug unlock instead of actual purchase
    // This works even if IAP is not available on the device
    if (kDebugMode) {
      debugPrint('🔓 DEBUG: Unlocking premium for testing');
      debugUnlockPremium();
      return true;
    }

    if (!_isAvailable) {
      debugPrint('⚠️ IAP not available');
      return false;
    }

    // Check if product is already purchased
    if (_isPremium) {
      debugPrint('ℹ️ Already premium');
      return true;
    }

    // Look up the product
    final response = await _inAppPurchase.queryProductDetails({_premiumProductId});
    if (response.error != null) {
      debugPrint('❌ Error looking up product: ${response.error?.message}');
      return false;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('❌ Product not found: $_premiumProductId');
      return false;
    }

    final productDetails = response.productDetails.first;

    // Make the purchase
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('🛒 Purchase initiated for $_premiumProductId');
      // Result will be handled in _handlePurchaseUpdate
      return true;
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases (internal use only)
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('🔄 Purchase restore initiated');
    } catch (e) {
      debugPrint('❌ Restore failed: $e');
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  /// Debug function to unlock premium for testing
  /// Only works in debug mode
  void debugUnlockPremium() async {
    if (kDebugMode) {
      _isPremium = true;
      await _savePremiumStatus(true);
      // Explicitly reload to ensure consistency
      await _loadPremiumStatus();
      debugPrint('🔓 DEBUG: Premium unlocked for testing');
    } else {
      debugPrint('⚠️ Debug unlock only available in debug mode');
    }
  }

  /// Refresh premium status from storage
  /// Call this after clearing the status to get the current value
  Future<void> refreshPremiumStatus() async {
    try {
      final box = await Hive.openBox(_premiumBoxName);
      if (box.containsKey(_isPremiumKey)) {
        _isPremium = box.get(_isPremiumKey);
      } else {
        _isPremium = false;
      }
      notifyListeners();
      debugPrint('🔄 Refreshed premium status: $_isPremium');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh premium status: $e');
    }
  }
}
