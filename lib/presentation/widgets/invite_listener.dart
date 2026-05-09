import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invite_provider.dart';
import '../providers/multiplayer_provider.dart';
import '../../services/realtime_matchmaking_service.dart';

/// Shell widget placed inside the authenticated ShellRoute.
/// Listens for incoming friend invites and shows InviteDialog.
class InviteShell extends ConsumerWidget {
  final Widget child;
  const InviteShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<InviteState>(inviteProvider, (prev, next) {
      if (next.pendingInvite != null && prev?.pendingInvite == null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => InviteDialog(invite: next.pendingInvite!),
        );
      }
    });
    return child;
  }
}

/// Dialog shown when a friend sends a real-time match invite.
class InviteDialog extends ConsumerStatefulWidget {
  final InviteData invite;
  const InviteDialog({required this.invite, super.key});

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  late Timer _countdown;
  int _secondsLeft = 60;
  bool _acted = false;
  bool _waitingForGame = false;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
      if (_secondsLeft <= 0 && !_acted) {
        _reject();
      }
    });
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_acted) return;
    _acted = true;
    _waitingForGame = true;
    _countdown.cancel();

    final accepted = await ref.read(inviteProvider.notifier).accept();
    if (!mounted) return;

    if (!accepted) {
      _waitingForGame = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    // If accepted, ref.listen on multiplayerProvider handles navigation
  }

  void _reject() {
    if (_acted) return;
    _acted = true;
    _countdown.cancel();
    ref.read(inviteProvider.notifier).reject();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MultiplayerState>(multiplayerProvider, (_, next) {
      if (!mounted || !_waitingForGame) return;
      if (next.status == MultiplayerStatus.found ||
          next.status == MultiplayerStatus.playing) {
        _waitingForGame = false;
        Navigator.of(context, rootNavigator: true).pop();
        context.go('/multiplayer-game');
      } else if (next.status == MultiplayerStatus.error) {
        _waitingForGame = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.sports_esports, color: Color(0xFF4FC3F7), size: 22),
          SizedBox(width: 8),
          Text(
            'Reto recibido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.invite.fromDisplayName} te reta a una partida',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 4),
              Text(
                'ELO: ${widget.invite.fromElo}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$_secondsLeft s',
            style: TextStyle(
              color: _secondsLeft <= 10 ? Colors.redAccent : const Color(0xFF4FC3F7),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _acted ? null : _reject,
          child: const Text('Rechazar', style: TextStyle(color: Colors.redAccent)),
        ),
        ElevatedButton(
          onPressed: _acted ? null : _accept,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.black,
          ),
          child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
