import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_history_provider.dart';
import 'match_card.dart';

/// Match History Screen — shows all finished matches for the current user.
class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final matchHistory = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top App Bar ───────────────────────────────
          _buildTopBar(context),

          // ── Content ───────────────────────────────────
          Expanded(
            child: _buildContent(matchHistory, currentUser?.userId ?? ''),
          ),
        ],
      ),
      // ── Bottom Navigation Bar (mobile) ───────────────
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? _buildBottomNavBar(context, currentIndex: 2)
          : null,
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
            // Back button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: IconButton(
                onPressed: () => context.go('/home'),
                icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 18),
              ),
            ),
            // Title
            Text(
              'HISTORIAL',
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            // Placeholder for balance
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MatchHistoryState state, String currentUserId) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando partidas...',
              style: GoogleFonts.workSans(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (state.failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el historial',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.failure!.toString(),
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_martial_arts, size: 64, color: AppColors.primary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'Sin partidas aún',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Juega tu primera partida\ny aparecerá aquí.',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show match list
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh match history
        await ref.read(matchHistoryProvider.notifier).fetchMatchHistory();
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: state.matches.length,
        itemBuilder: (context, index) {
          final match = state.matches[index];
          return MatchCard(
            match: match,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, {required int currentIndex}) {
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
          currentIndex: currentIndex,
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
                context.go('/home');
                break;
              case 1:
                context.go('/matchmaking/casual');
                break;
              case 2:
                // Already on history
                break;
              case 3:
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
