import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/subscription_service.dart';
import '../../core/constants/revenue_cat_constants.dart';
import '../../domain/entities/user.dart' as ent;
import 'user_provider.dart';

/// Offering state model
class OfferingState {
  final List<Package> packages;
  final bool isLoading;
  final String? error;

  const OfferingState({
    this.packages = const [],
    this.isLoading = false,
    this.error,
  });

  OfferingState copyWith({
    List<Package>? packages,
    bool? isLoading,
    String? error,
  }) {
    return OfferingState(
      packages: packages ?? this.packages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for available offerings
final offeringsProvider = StateNotifierProvider<OfferingsNotifier, OfferingState>((ref) {
  return OfferingsNotifier();
});

class OfferingsNotifier extends StateNotifier<OfferingState> {
  OfferingsNotifier() : super(const OfferingState()) {
    fetchOfferings();
  }

  Future<void> fetchOfferings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final offerings = await SubscriptionService().getOfferings();
    
    if (offerings != null && offerings.current != null) {
      state = state.copyWith(
        packages: offerings.current!.availablePackages,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar las ofertas.',
      );
    }
  }
}

/// Provider for subscription actions
final subscriptionActionsProvider = Provider((ref) {
  return SubscriptionActions(ref);
});

class SubscriptionActions {
  final Ref _ref;

  SubscriptionActions(this._ref);

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    final customerInfo = await SubscriptionService().purchasePackage(package);
    
    if (customerInfo != null) {
      final hasEntitlement = customerInfo.entitlements.active.containsKey(RevenueCatConstants.entitlementPremium);
      
      if (hasEntitlement) {
        // Sync with Firestore
        await _syncSubscriptionWithFirestore(customerInfo);
        return true;
      }
    }
    return false;
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    final customerInfo = await SubscriptionService().restorePurchases();
    
    if (customerInfo != null) {
      final hasEntitlement = customerInfo.entitlements.active.containsKey(RevenueCatConstants.entitlementPremium);
      
      if (hasEntitlement) {
        // Sync with Firestore
        await _syncSubscriptionWithFirestore(customerInfo);
        return true;
      }
    }
    return false;
  }

  /// Sync subscription status with Firestore user profile
  Future<void> _syncSubscriptionWithFirestore(CustomerInfo customerInfo) async {
    final user = _ref.read(userNotifierProvider).valueOrNull;
    if (user == null) return;

    final hasPremium = customerInfo.entitlements.active.containsKey(RevenueCatConstants.entitlementPremium);
    final premiumEntitlement = customerInfo.entitlements.active[RevenueCatConstants.entitlementPremium];
    
    final updatedSubscription = user.subscription.copyWith(
      type: hasPremium ? 'premium' : 'free',
      isActive: hasPremium,
      expiresAt: premiumEntitlement?.expirationDate != null 
          ? DateTime.parse(premiumEntitlement!.expirationDate!) 
          : null,
    );

    final updatedUser = user.copyWith(subscription: updatedSubscription);
    await _ref.read(userNotifierProvider.notifier).updateUserProfile(updatedUser);
  }
}
