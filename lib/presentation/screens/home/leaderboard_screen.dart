import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';

/// Leaderboard screen — shows all players ranked by ELO.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────────
          _buildTopBar(context),

          // ── Content ────────────────────────────────────
          Expanded(
            child: leaderboardAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando clasificación...',
                      style: GoogleFonts.workSans(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar clasificación',
                      style: GoogleFonts.workSans(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(leaderboardProvider),
                      child: Text(
                        'Reintentar',
                        style: GoogleFonts.workSans(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              data: (users) => _buildLeaderboardList(context, users, currentUser?.userId),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: IconButton(
                onPressed: () => context.go('/home'),
                icon: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Clasificación',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.emoji_events, color: AppColors.tertiary, size: 28),
          ],
        ),
      ),
    );
  }

  // ── Leaderboard List ────────────────────────────────────

  Widget _buildLeaderboardList(BuildContext context, List<User> users, String? currentUserId) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No hay jugadores todavía',
              style: GoogleFonts.workSans(
                color: AppColors.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Find current user's rank
    final myIndex = currentUserId != null
        ? users.indexWhere((u) => u.userId == currentUserId)
        : -1;

    return Column(
      children: [
        // ── Your position banner (if found) ───────────
        if (myIndex >= 0) _buildMyPositionBanner(context, users[myIndex], myIndex + 1),

        // ── Podium (top 3) ────────────────────────────
        if (users.length >= 3) _buildPodium(context, users, currentUserId),

        // ── Rest of players ───────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: users.length > 3 ? users.length - 3 : 0,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final actualIndex = index + 3;
              final user = users[actualIndex];
              final isMe = user.userId == currentUserId;
              return _buildPlayerRow(context, user, actualIndex + 1, isMe);
            },
          ),
        ),
      ],
    );
  }

  // ── My Position Banner ──────────────────────────────────

  Widget _buildMyPositionBanner(BuildContext context, User user, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU POSICIÓN',
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // ELO
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.elo}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ELO',
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Podium (Top 3) ──────────────────────────────────────

  Widget _buildPodium(BuildContext context, List<User> users, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _buildPodiumCard(context, users[1], 2, currentUserId, height: 120)),
          const SizedBox(width: 8),
          // 1st place
          Expanded(child: _buildPodiumCard(context, users[0], 1, currentUserId, height: 150)),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(child: _buildPodiumCard(context, users[2], 3, currentUserId, height: 100)),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(BuildContext context, User user, int rank, String? currentUserId, {required double height}) {
    final isMe = user.userId == currentUserId;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primaryContainer.withOpacity(0.15) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
            : Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Medal
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: medalColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: medalColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: user.photoUrl == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            user.displayName.length > 10 ? '${user.displayName.substring(0, 10)}…' : user.displayName,
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // ELO
          Text(
            '${user.elo}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: medalColor,
              height: 1,
            ),
          ),
          if (rank == 1) ...[
            const SizedBox(height: 4),
            Icon(Icons.emoji_events, size: 16, color: medalColor),
          ],
        ],
      ),
    );
  }

  // ── Player Row (4th+) ───────────────────────────────────

  Widget _buildPlayerRow(BuildContext context, User user, int rank, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.06) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppColors.primary.withOpacity(0.2))
            : Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: user.photoUrl == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + rank title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Tú' : user.displayName,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.rank,
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // ELO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${user.elo}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}