import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/realtime_matchmaking_service.dart';
import 'multiplayer_provider.dart';

class InviteState {
  final InviteData? pendingInvite;
  const InviteState({this.pendingInvite});

  InviteState copyWith({InviteData? pendingInvite}) =>
      InviteState(pendingInvite: pendingInvite);

  InviteState cleared() => const InviteState();
}

class InviteNotifier extends StateNotifier<InviteState> {
  final Ref _ref;
  StreamSubscription? _sub;

  InviteNotifier(this._ref) : super(const InviteState()) {
    _startListening();
    _ref.onDispose(() => _sub?.cancel());
  }

  void _startListening() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _sub = _ref
        .read(realtimeMatchmakingServiceProvider)
        .watchPendingInvites(userId)
        .listen((invites) {
      // Only surface first invite; ignore if one is already being shown
      if (invites.isNotEmpty && state.pendingInvite == null) {
        state = state.copyWith(pendingInvite: invites.first);
      }
    });
  }

  /// Accept the pending invite: joins the RTDB match and starts the game.
  Future<bool> accept() async {
    final invite = state.pendingInvite;
    if (invite == null) return false;

    // Clear immediately to prevent double-tap
    state = const InviteState();

    final rtdb = _ref.read(realtimeMatchmakingServiceProvider);
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    final joined = await rtdb.acceptInvite(
      toUserId: invite.toUserId,
      inviteId: invite.inviteId,
      rtdbMatchId: invite.rtdbMatchId,
      userId: invite.toUserId,
      displayName: displayName,
    );

    if (joined) {
      await _ref
          .read(multiplayerProvider.notifier)
          .joinFromInvite(invite);
      rtdb.cleanupInvite(invite.toUserId, invite.inviteId).catchError((_) {});
      return true;
    }
    // Match was already taken or cancelled
    return false;
  }

  /// Reject the pending invite.
  Future<void> reject() async {
    final invite = state.pendingInvite;
    if (invite == null) return;
    state = const InviteState();

    await _ref
        .read(realtimeMatchmakingServiceProvider)
        .rejectInvite(toUserId: invite.toUserId, inviteId: invite.inviteId);
    _ref
        .read(realtimeMatchmakingServiceProvider)
        .cleanupInvite(invite.toUserId, invite.inviteId)
        .catchError((_) {});
  }
}

final inviteProvider =
    StateNotifierProvider<InviteNotifier, InviteState>((ref) {
  return InviteNotifier(ref);
});
