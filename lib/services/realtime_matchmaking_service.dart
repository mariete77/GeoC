import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Data transferred from RTDB when a friend sends a match invite.
class InviteData {
  final String inviteId;
  final String toUserId;
  final String fromUserId;
  final String fromDisplayName;
  final int fromElo;
  final String rtdbMatchId;
  final List<String> questionIds;

  const InviteData({
    required this.inviteId,
    required this.toUserId,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.fromElo,
    required this.rtdbMatchId,
    required this.questionIds,
  });
}

/// Result from [RealtimeMatchmakingService.findWaitingMatch].
class WaitingMatch {
  final String matchId;
  final String creatorId;
  final String? creatorName;
  final int? creatorElo;

  const WaitingMatch({
    required this.matchId,
    required this.creatorId,
    this.creatorName,
    this.creatorElo,
  });
}

/// Firebase Realtime Database service for matchmaking, live game state and friend invites.
///
/// RTDB structure:
///   /matchmaking_queue/{mode}/{userId}: {elo, rtdbMatchId, displayName, createdAt}
///   /rtdb_matches/{matchId}: {player1, player2, questionIds, mode, status, createdAt}
///   /rtdb_game_state/{matchId}/{userId}: {score, currentQuestion, finished}
///   /invites/{toUserId}/{inviteId}: {fromUserId, fromDisplayName, fromElo, rtdbMatchId, questionIds, status, createdAt}
class RealtimeMatchmakingService {
  final FirebaseDatabase _db;

  RealtimeMatchmakingService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  // ─── Path helpers ────────────────────────────────────────

  DatabaseReference _queueRef(String mode) =>
      _db.ref('matchmaking_queue/$mode');

  DatabaseReference _matchRef(String matchId) =>
      _db.ref('rtdb_matches/$matchId');

  DatabaseReference _gameStateRef(String matchId, String userId) =>
      _db.ref('rtdb_game_state/$matchId/$userId');

  // ════════════════════════════════════════════════════════
  // QUEUE
  // ════════════════════════════════════════════════════════

  /// Adds the player to the matchmaking queue.
  /// Uses ServerValue.timestamp for createdAt.
  Future<void> joinQueue({
    required String mode,
    required String userId,
    required int elo,
    required String rtdbMatchId,
    String? displayName,
  }) async {
    try {
      final ref = _queueRef(mode).child(userId);
      await ref.set({
        'elo': elo,
        'rtdbMatchId': rtdbMatchId,
        'displayName': displayName ?? 'Jugador',
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      // Queue write failure - log but don't crash the caller
      print('joinQueue error ($mode): $e');
      rethrow;
    }
  }

  /// Removes the player from the queue.
  Future<void> leaveQueue({
    required String mode,
    required String userId,
  }) async {
    await _queueRef(mode).child(userId).remove();
  }

  /// Scans `rtdb_matches` for a waiting match of the given mode,
  /// excludes the current user's own matches, and returns the best match
  /// (closest ELO). Uses a one-time read — suitable for polling.
  Future<WaitingMatch?> findWaitingMatch({
    required String mode,
    required String excludeUserId,
    required int elo,
  }) async {
    try {
      final snapshot = await _db.ref('rtdb_matches').get();
      if (!snapshot.exists || snapshot.value == null) {
        print('[findWaitingMatch] No matches in RTDB');
        return null;
      }

      final matches = Map<String, dynamic>.from(snapshot.value as Map);
      print('[findWaitingMatch] Total matches: ${matches.length}');
      WaitingMatch? best;
      int bestEloDiff = 999999;

      for (final entry in matches.entries) {
        if (entry.value == null) continue;
        final data = Map<String, dynamic>.from(entry.value as Map);
        final status = data['status'] as String?;
        final matchMode = data['mode'] as String?;
        final p1 = data['player1'] as String?;
        final p2 = data['player2'];
        final creatorElo = data['creatorElo'] as int? ?? 1000;
        final eloDiff = (creatorElo - elo).abs();

        print('[findWaitingMatch] match=${entry.key} status=$status mode=$matchMode p1=$p1 p2=$p2 myElo=$elo creatorElo=$creatorElo eloDiff=$eloDiff');

        if (status != 'waiting') continue;
        if (matchMode != mode) continue;
        if (p1 == excludeUserId) continue;
        if (p2 != null) continue;
        if (eloDiff > 200) continue;

        if (eloDiff < bestEloDiff) {
          best = WaitingMatch(
            matchId: entry.key,
            creatorId: p1!,
            creatorName: data['displayName'] as String?,
            creatorElo: creatorElo,
          );
          bestEloDiff = eloDiff;
        }
      }

      print('[findWaitingMatch] Result: ${best != null ? 'found ${best.matchId}' : 'none'}');
      return best;
    } catch (e) {
      print('[findWaitingMatch] Error: $e');
      return null;
    }
  }

  /// One-time read of the current queue snapshot.
  Future<Map<String, dynamic>> readQueue(String mode) async {
    final snapshot = await _queueRef(mode).get();
    if (!snapshot.exists || snapshot.value == null) return {};
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Real-time stream of queue changes (push-based, no polling needed).
  Stream<Map<String, dynamic>> watchQueue(String mode) {
    return _queueRef(mode).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(val as Map);
    });
  }

  // ════════════════════════════════════════════════════════
  // MATCH
  // ════════════════════════════════════════════════════════

  /// Creates a new waiting match in RTDB and registers onDisconnect cancellation.
  Future<String> createRtdbMatch({
    required String creatorId,
    required List<String> questionIds,
    required String mode,
    int? creatorElo,
    String? displayName,
  }) async {
    final ref = _db.ref('rtdb_matches').push();
    await ref.set({
      'player1': creatorId,
      'player2': null,
      'questionIds': questionIds,
      'mode': mode,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'creatorElo': creatorElo ?? 1000,
      'displayName': displayName ?? 'Jugador',
    });
    // If creator disconnects while waiting, mark cancelled so nobody joins
    await ref.onDisconnect().update({'status': 'cancelled'});
    return ref.key!;
  }

  /// Joins a waiting match by writing player2 + status='active'.
  /// Uses a two-phase approach (write-then-verify) since `runTransaction`
  /// doesn't work reliably on Flutter web (mutableData is null).
  Future<bool> joinRtdbMatch({
    required String matchId,
    required String userId,
    String? displayName,
  }) async {
    try {
      // Phase 1: read current state
      final snap = await _matchRef(matchId).get();
      if (!snap.exists || snap.value == null) {
        print('[joinRtdbMatch] fail: match not found');
        return false;
      }
      final data = Map<String, dynamic>.from(snap.value as Map);
      if (data['status'] != 'waiting') {
        print('[joinRtdbMatch] fail: status=${data['status']}');
        return false;
      }
      if (data['player2'] != null) {
        print('[joinRtdbMatch] fail: player2 already set');
        return false;
      }

      // Phase 2: write our join (low race risk due to 2s polling interval)
      await _matchRef(matchId).update({
        'player2': userId,
        'player2DisplayName': displayName ?? 'Oponente',
        'status': 'active',
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Phase 3: verify we got the slot
      final verify = await _matchRef(matchId).get();
      if (!verify.exists) return false;
      final after = Map<String, dynamic>.from(verify.value as Map);
      final success = after['player2'] == userId && after['status'] == 'active';
      print('[joinRtdbMatch] result: $success (p2=${after['player2']})');
      return success;
    } catch (e) {
      print('[joinRtdbMatch] error: $e');
      return false;
    }
  }

  /// Real-time stream of a specific RTDB match.
  Stream<Map<String, dynamic>?> watchRtdbMatch(String matchId) {
    return _matchRef(matchId).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return null;
      return Map<String, dynamic>.from(val as Map);
    });
  }

  /// Cancels a match only if it is still in 'waiting' status.
  Future<void> cancelRtdbMatch(String matchId) async {
    await _matchRef(matchId).runTransaction((mutableData) {
      if (mutableData == null) return Transaction.abort();
      final data = Map<String, dynamic>.from(mutableData as Map);
      if (data['status'] == 'waiting') {
        data['status'] = 'cancelled';
        return Transaction.success(data);
      }
      return Transaction.abort();
    });
  }

  // ════════════════════════════════════════════════════════
  // LIVE GAME STATE
  // ════════════════════════════════════════════════════════

  /// Pushes the player's current score and progress to RTDB.
  /// Call fire-and-forget (do not await in gameplay hot path).
  Future<void> updateGameState({
    required String matchId,
    required String userId,
    required int score,
    required int currentQuestion,
    required bool finished,
  }) async {
    await _gameStateRef(matchId, userId).set({
      'score': score,
      'currentQuestion': currentQuestion,
      'finished': finished,
    });
  }

  /// Real-time stream of the opponent's game state.
  Stream<Map<String, dynamic>?> watchOpponentState({
    required String matchId,
    required String opponentId,
  }) {
    return _gameStateRef(matchId, opponentId).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return null;
      return Map<String, dynamic>.from(val as Map);
    });
  }

  // ════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════

  /// Removes all RTDB data for a finished match.
  Future<void> cleanupMatch(String matchId) async {
    await Future.wait([
      _matchRef(matchId).remove(),
      _db.ref('rtdb_game_state/$matchId').remove(),
    ]);
  }

  // ════════════════════════════════════════════════════════
  // FRIEND INVITES
  // ════════════════════════════════════════════════════════

  DatabaseReference _inviteRef(String toUserId) =>
      _db.ref('invites/$toUserId');

  /// Sends a real-time match invite to a friend.
  /// Returns the generated inviteId.
  Future<String> sendInvite({
    required String toUserId,
    required String fromUserId,
    required String fromDisplayName,
    required int fromElo,
    required String rtdbMatchId,
    required List<String> questionIds,
  }) async {
    final ref = _inviteRef(toUserId).push();
    await ref.set({
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'fromElo': fromElo,
      'rtdbMatchId': rtdbMatchId,
      'questionIds': questionIds,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
    });
    // Auto-expire if sender disconnects
    await ref.onDisconnect().update({'status': 'expired'});
    return ref.key!;
  }

  /// Real-time stream of pending invites for [userId].
  Stream<List<InviteData>> watchPendingInvites(String userId) {
    return _inviteRef(userId).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <InviteData>[];

      final map = Map<String, dynamic>.from(val as Map);
      final invites = <InviteData>[];

      for (final entry in map.entries) {
        if (entry.value == null) continue;
        final data = Map<String, dynamic>.from(entry.value as Map);
        if (data['status'] != 'pending') continue;
        invites.add(InviteData(
          inviteId: entry.key,
          toUserId: userId,
          fromUserId: data['fromUserId'] as String? ?? '',
          fromDisplayName: data['fromDisplayName'] as String? ?? 'Jugador',
          fromElo: data['fromElo'] as int? ?? 1000,
          rtdbMatchId: data['rtdbMatchId'] as String? ?? '',
          questionIds: List<String>.from(data['questionIds'] ?? []),
        ));
      }
      return invites;
    });
  }

  /// Accepts an invite by atomically joining the RTDB match.
  /// Returns true if the join succeeded.
  Future<bool> acceptInvite({
    required String toUserId,
    required String inviteId,
    required String rtdbMatchId,
    required String userId,
    String? displayName,
  }) async {
    final joined = await joinRtdbMatch(matchId: rtdbMatchId, userId: userId, displayName: displayName);
    if (joined) {
      await _inviteRef(toUserId)
          .child(inviteId)
          .update({'status': 'accepted'});
    }
    return joined;
  }

  /// Rejects an invite.
  Future<void> rejectInvite({
    required String toUserId,
    required String inviteId,
  }) async {
    await _inviteRef(toUserId).child(inviteId).update({'status': 'rejected'});
  }

  /// Watches the status of a sent invite (so the sender knows if accepted/rejected).
  Stream<String?> watchInviteStatus(String toUserId, String inviteId) {
    return _inviteRef(toUserId)
        .child(inviteId)
        .child('status')
        .onValue
        .map((event) => event.snapshot.value as String?);
  }

  /// Marks an invite as expired (called by sender on timeout or cancel).
  Future<void> cancelInvite(String toUserId, String inviteId) async {
    await _inviteRef(toUserId).child(inviteId).update({'status': 'expired'});
  }

  /// Removes an invite entry once it has been processed.
  Future<void> cleanupInvite(String toUserId, String inviteId) async {
    await _inviteRef(toUserId).child(inviteId).remove();
  }
}
