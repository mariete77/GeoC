import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/revenue_cat_constants.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(RevenueCatConstants.googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(RevenueCatConstants.appleApiKey);
      } else {
        return;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  /// Get available offerings
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  /// Make a purchase
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      debugPrint('Error making purchase: $e');
      return null;
    }
  }

  /// Restore purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return null;
    }
  }

  /// Get customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Log in user to RevenueCat
  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Error logging in to RevenueCat: $e');
    }
  }

  /// Log out user from RevenueCat
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Error logging out from RevenueCat: $e');
    }
  }
}
