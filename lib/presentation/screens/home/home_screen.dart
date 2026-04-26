import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/active_players_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/elo_history_provider.dart';
import '../../providers/match_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/match.dart';
import 'widgets/elo_sparkline.dart';
import 'widgets/subscription_modal.dart';
import '../../widgets/common/geoc_page_transitions.dart';
import 'package:intl/intl.dart';

/// Home screen — "PantallaPrincipal" mockup.
/// Bento-grid layout with editorial player stats and game mode cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userState = ref.watch(userNotifierProvider);
    final dailyGames = ref.watch(dailyGamesStatusProvider);
    final eloHistory = ref.watch(eloHistoryProvider);
    final matchHistory = ref.watch(matchHistoryProvider);

    // Load user profile from Firestore
    if (currentUser != null &&
        userState.valueOrNull == null &&
        !userState.isLoading &&
        !userState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userNotifierProvider.notifier).getUserProfile(currentUser.userId);
      });
    }

    // Start presence service (updates lastLoginAt every 5 min)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presenceServiceProvider).startPresenceUpdates();
    });

    final displayUser = userState.valueOrNull ?? currentUser;

    if (displayUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, size: 64, color: AppColors.primary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'Cargando...',
                style: GoogleFonts.workSans(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top App Bar ───────────────────────────────
          _buildTopBar(context, ref, displayUser),

          // ── Scrollable Content (staggered entrance) ────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: StaggeredEntrance(
                staggerDelay: const Duration(milliseconds: 100),
                itemDuration: const Duration(milliseconds: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player Stats Section
                    StaggeredItem(
                      index: 0,
                      child: _buildPlayerStats(context, displayUser, eloHistory),
                    ),
                    const SizedBox(height: 24),

                    // Game Mode Cards
                    StaggeredItem(
                      index: 1,
                      child: _buildGameModes(context, ref, dailyGames),
                    ),
                    const SizedBox(height: 16),

                    // Clasificación Card
                    StaggeredItem(
                      index: 2,
                      child: _buildLeaderboardCard(context),
                    ),
                    const SizedBox(height: 16),

                    // Historial Section
                    StaggeredItem(
                      index: 3,
                      child: _buildHistorySection(context, ref, matchHistory, currentUser?.userId ?? ''),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? _buildBottomNavBar(context)
          : null,
    );
  }

  // ── Top App Bar ─────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, WidgetRef ref, User user) {
    // Start presence updates and watch active players
    final activePlayersAsync = ref.watch(activePlayersProvider);
    final activeCount = activePlayersAsync.valueOrNull ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Logo
                Text(
                  'GeoC',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Subscription Button ─────────────
                Material(
                  color: AppColors.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(9999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: () => SubscriptionModal.show(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.workspace_premium,
                          size: 20, color: AppColors.tertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Active Players Indicator ─────────────
                if (activeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Green neon dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4CAF50),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$activeCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // Settings
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Navigate to settings
                    },
                    icon: Icon(Icons.settings_outlined, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Player Stats Section ────────────────────────────────

  Widget _buildPlayerStats(BuildContext context, User user, EloHistoryState eloHistory) {
    final winStreak = user.stats.currentWinStreak;
    final elo = user.elo;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Top row — Player Info (left) + ELO Score (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left — Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPLORADOR',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Streak: $winStreak',
                            style: GoogleFonts.workSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right — ELO Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CLASIFICACIÓN GLOBAL',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$elo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puntuación ELO',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Bottom — Full-width ELO Sparkline (always visible)
          const SizedBox(height: 20),
          EloSparkline(
            eloValues: eloHistory.eloValues,
            currentElo: eloHistory.currentElo,
            eloDelta: eloHistory.eloDelta,
          ),
        ],
      ),
    );
  }

  // ── Game Modes (Bento Grid) ─────────────────────────────

  Widget _buildGameModes(
    BuildContext context,
    WidgetRef ref,
    DailyGamesStatus dailyGames,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 640;

    if (isWide) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _buildQuickPlayCard(context, dailyGames)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _buildRankedCard(context, dailyGames)),
            ],
          ),
          const SizedBox(height: 16),
          _buildGhostRunCard(context),
        ],
      );
    }

    return Column(
      children: [
        _buildQuickPlayCard(context, dailyGames),
        const SizedBox(height: 16),
        _buildRankedCard(context, dailyGames),
        const SizedBox(height: 16),
        _buildGhostRunCard(context),
      ],
    );
  }

  /// Partida Rápida — dominant CTA with green gradient
  Widget _buildQuickPlayCard(BuildContext context, DailyGamesStatus dailyGames) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD5F2E5), Color(0xFFB9D9B8)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: dailyGames.canPlayCasual ? () => context.go('/game/easy') : null,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bolt, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 48),
                Text(
                  'Partida Rápida',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salta a una partida casual instantánea.',
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ranked — compact card repurposed as Multijugador
  Widget _buildRankedCard(BuildContext context, DailyGamesStatus dailyGames) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              dailyGames.canPlayRanked ? () => context.go('/matchmaking/ranked') : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.outlineVariant.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      Icon(Icons.military_tech, size: 22, color: AppColors.tertiary),
                ),
                const SizedBox(height: 48),
                Text(
                  'Multijugador',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partidas competitivas por ELO.',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clasificación — full-width row card (design system colors, no purple)
  Widget _buildLeaderboardCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow(),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/leaderboard'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.emoji_events, size: 28, color: AppColors.tertiary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clasificación',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mira tu posición respecto a los demás jugadores.',
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, size: 32, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fantasma (Ghost Run) — full-width row card
  Widget _buildGhostRunCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/matchmaking/ghostRun'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.history_edu,
                      size: 28, color: AppColors.secondary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fantasma',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Practica contra las mejores partidas pasadas.',
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward,
                    size: 32, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Historial — Rich section with summary stats + recent matches
  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    MatchHistoryState matchHistory,
    String currentUserId,
  ) {
    final matches = matchHistory.matches;
    final isLoading = matchHistory.isLoading;

    // Calculate summary stats from match history
    int wins = 0;
    int losses = 0;
    int draws = 0;
    int totalEloDelta = 0;

    for (final match in matches) {
      final result = match.result;
      if (result == null) continue;
      final isWin = result.winnerId == currentUserId;
      final isDraw = result.isDraw;

      if (isDraw) {
        draws++;
      } else if (isWin) {
        wins++;
      } else {
        losses++;
      }
      totalEloDelta += result.eloChanges[currentUserId] ?? 0;
    }

    final totalGames = wins + losses + draws;
    final winRate = totalGames > 0 ? (wins / totalGames * 100).round() : 0;

    // Take the 3 most recent matches for preview
    final recentMatches = matches.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Historial',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                // Ver todo button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.go('/history'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver todo',
                            style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.sports_martial_arts, size: 40, color: AppColors.primary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'Sin partidas aún',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Juega tu primera partida para ver tu historial.',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ── Summary Stats Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  _buildStatPill(
                    icon: Icons.emoji_events_outlined,
                    label: 'Victorias',
                    value: '$wins',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    icon: Icons.close,
                    label: 'Derrotas',
                    value: '$losses',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    icon: Icons.percent,
                    label: 'Win Rate',
                    value: '$winRate%',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  if (totalEloDelta != 0)
                    _buildStatPill(
                      icon: totalEloDelta > 0 ? Icons.trending_up : Icons.trending_down,
                      label: 'ELO',
                      value: '${totalEloDelta > 0 ? '+' : ''}$totalEloDelta',
                      color: totalEloDelta > 0 ? AppColors.success : AppColors.error,
                    ),
                ],
              ),
            ),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
            ),

            // ── Recent Matches ──
            ...recentMatches.map((match) => _buildRecentMatchTile(context, match, currentUserId)),
          ],
        ],
      ),
    );
  }

  /// Small stat pill for the history summary
  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Compact match tile for the home screen preview
  Widget _buildRecentMatchTile(BuildContext context, GameMatch match, String currentUserId) {
    final result = match.result;
    final isWin = result?.winnerId == currentUserId;
    final isDraw = result?.isDraw ?? false;
    final eloChange = result?.eloChanges[currentUserId] ?? 0;
    final myScore = result?.scores[currentUserId] ?? 0;
    final opponentId = match.getOpponentId(currentUserId);
    final opponentScore = result?.scores[opponentId] ?? 0;

    // Result indicator
    final resultLabel = isDraw ? 'E' : (isWin ? 'V' : 'D');
    final resultColor = isDraw
        ? AppColors.tertiary
        : (isWin ? AppColors.success : AppColors.error);
    final resultBg = isDraw
        ? AppColors.tertiaryContainer.withOpacity(0.2)
        : (isWin ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12));

    // Date formatting
    final dateStr = match.finishedAt != null
        ? _formatRelativeDate(match.finishedAt!)
        : '';

    // Type tag
    final typeLabel = match.type == MatchType.ranked ? 'Ranked' : 'Casual';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/history'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Result badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: resultBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      resultLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$myScore',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isWin ? AppColors.success : AppColors.onSurface,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: AppColors.outlineVariant,
                              ),
                            ),
                          ),
                          Text(
                            '$opponentScore',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: !isWin && !isDraw ? AppColors.error : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: match.type == MatchType.ranked
                                  ? AppColors.tertiaryContainer.withOpacity(0.3)
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: GoogleFonts.workSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.workSans(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ELO change
                if (eloChange != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: eloChange > 0
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          eloChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 11,
                          color: eloChange > 0 ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${eloChange > 0 ? '+' : ''}$eloChange',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: eloChange > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format a date as a relative time string (e.g., "hace 5 min", "ayer")
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return DateFormat('dd MMM', 'es_ES').format(date);
  }

  // ── Bottom Navigation Bar ───────────────────────────────

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant.withOpacity(0.5),
          selectedLabelStyle: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          unselectedLabelStyle: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          onTap: (index) {
            switch (index) {
              case 0:
                // Home - already here
                break;
              case 1:
                context.go('/matchmaking/casual');
                break;
              case 2:
                context.go('/friends');
                break;
              case 3:
                context.go('/history');
                break;
              case 4:
                // TODO: Navigate to profile
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_martial_arts),
              label: 'BATTLE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'FRIENDS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories),
              label: 'JOURNAL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}