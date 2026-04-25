import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/active_players_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/elo_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import 'widgets/elo_sparkline.dart';
import '../../widgets/common/geoc_page_transitions.dart';

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
                    const SizedBox(height: 24),

                    // Quick Actions
                    StaggeredItem(
                      index: 3,
                      child: _buildQuickActions(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Bottom Navigation Bar (mobile) ───────────────
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left — Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORER',
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
          // Right — ELO Score + Sparkline
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GLOBAL RATING',
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
                'ELO Score',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.primaryContainer,
                ),
              ),
              if (eloHistory.eloValues.length >= 2) ...[
                const SizedBox(height: 8),
                EloSparkline(
                  eloValues: eloHistory.eloValues,
                  currentElo: eloHistory.currentElo,
                  eloDelta: eloHistory.eloDelta,
                ),
              ],
            ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildGhostRunCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildMultiplayerCard(context)),
            ],
          ),
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
        const SizedBox(height: 16),
        _buildMultiplayerCard(context),
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

  /// Ranked — compact card
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
              dailyGames.canPlayRanked ? () => context.go('/game/medium') : null,
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
                  'Ranked',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compite por ELO y sube en el ranking global.',
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

  /// Multijugador — row card similar to Ghost Run
  Widget _buildMultiplayerCard(BuildContext context) {
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
          onTap: () => context.go('/matchmaking/casual'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sports_martial_arts,
                      size: 28, color: AppColors.tertiary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multijugador',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enfréntate a otros jugadores en tiempo real.',
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

  // ── Quick Actions ───────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionChip(Icons.person, 'Perfil', () {}),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _buildActionChip(Icons.leaderboard, 'Leaderboard', () => context.go('/leaderboard')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionChip(
                  Icons.workspace_premium, 'Suscripción', () {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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