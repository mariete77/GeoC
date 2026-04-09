import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

/// Home screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userState = ref.watch(userNotifierProvider);
    final dailyGames = ref.watch(dailyGamesStatusProvider);

    // Load user profile from Firestore in background
    if (currentUser != null && userState.valueOrNull == null && !userState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userNotifierProvider.notifier).getUserProfile(currentUser.userId);
      });
    }

    // Use Firestore user if available, otherwise fall back to auth user
    final displayUser = userState.valueOrNull ?? currentUser;

    if (displayUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user data')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _buildHomeContent(context, ref, displayUser, dailyGames),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    DailyGamesStatus dailyGames,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.displayName[0].toUpperCase(),
                                    style: AppTextStyles.h2.copyWith(
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          // Name and ELO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user.elo} ELO',
                                      style: AppTextStyles.elo.copyWith(
                                        color: AppColors.secondary,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Settings button
                          IconButton(
                            onPressed: () {
                              // TODO: Navigate to settings
                            },
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Rank badge
                      const SizedBox(height: 16),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.military_tech,
                              color: AppColors.rankGold,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.rank,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                _buildStatsRow(user),

                const SizedBox(height: 24),

                // Game mode buttons
                _buildGameModes(context, ref, dailyGames),

                const SizedBox(height: 24),

                // Quick actions
                _buildQuickActions(context),

                const SizedBox(height: 24),

                // Recent matches
                _buildRecentMatches(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Partidas',
            '${user.stats.totalGames}',
            Icons.sports_esports,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Victorias',
            '${user.stats.wins}',
            Icons.emoji_events,
            AppColors.correct,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Racha',
            '${user.stats.currentWinStreak}',
            Icons.local_fire_department,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildGameModes(
    BuildContext context,
    WidgetRef ref,
    DailyGamesStatus dailyGames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modos de Juego',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        // Casual game
        _buildGameModeCard(
          'Partida Rápida',
          'Sin ELO • Diviértete',
          Icons.play_arrow,
          AppColors.primary,
          dailyGames.canPlayCasual,
          dailyGames.casualRemaining >= 999 ? '∞' : '${dailyGames.casualRemaining}',
          () {
            context.go('/game/easy');
          },
        ),
        const SizedBox(height: 12),
        // Ranked game
        _buildGameModeCard(
          'Ranked',
          'ELO • Compite en el ranking',
          Icons.leaderboard,
          AppColors.secondary,
          dailyGames.canPlayRanked,
          '${dailyGames.rankedRemaining}',
          () {
            context.go('/game/medium');
          },
        ),
      ],
    );
  }

  Widget _buildGameModeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool canPlay,
    String remaining,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: canPlay ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!canPlay)
                  const Icon(
                    Icons.lock,
                    color: AppColors.textSecondary,
                  )
                else
                  Column(
                    children: [
                      Text(
                        remaining,
                        style: AppTextStyles.h3.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'restantes',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Perfil',
                Icons.person,
                () {
                  // TODO: Navigate to profile
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Leaderboard',
                Icons.leaderboard,
                () {
                  // TODO: Navigate to leaderboard
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Suscripción',
                Icons.workspace_premium,
                () {
                  // TODO: Navigate to subscription
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMatches(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Partidas Recientes',
              style: AppTextStyles.h3,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to match history
              },
              child: Text('Ver todas', style: AppTextStyles.buttonSmall),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay partidas recientes',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Start first match
                  },
                  child: const Text('Jugar tu primera partida'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
