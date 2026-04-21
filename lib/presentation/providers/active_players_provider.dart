import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that streams the count of active players (seen in the last hour)
final activePlayersProvider = StreamProvider<int>((ref) {
  final oneHourAgo = Timestamp.fromDate(
    DateTime.now().subtract(const Duration(hours: 1)),
  );

  return FirebaseFirestore.instance
      .collection('users')
      .where('lastLoginAt', isGreaterThanOrEqualTo: oneHourAgo)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Updates the user's lastSeenAt timestamp periodically.
/// Call this from the main app widget or home screen.
class PresenceService {
  Timer? _timer;

  /// Start periodic presence updates (every 5 minutes)
  void startPresenceUpdates() {
    _updatePresence(); // Immediate first update
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updatePresence(),
    );
  }

  /// Stop presence updates
  void stopPresenceUpdates() {
    _timer?.cancel();
    _timer = null;
  }

  /// Update lastLoginAt timestamp in Firestore
  void _updatePresence() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    }).catchError((_) {
      // Silently fail — presence is non-critical
    });
  }
}

/// Singleton presence service provider
final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService();
  ref.onDispose(() => service.stopPresenceUpdates());
  return service;
});
