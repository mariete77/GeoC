import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geoquiz_battle/presentation/screens/splash/splash_screen.dart';
import 'package:geoquiz_battle/presentation/screens/auth/login_screen.dart';
import 'package:geoquiz_battle/presentation/screens/home/home_screen.dart';
import 'package:geoquiz_battle/presentation/screens/game/game_screen.dart';
import 'package:geoquiz_battle/presentation/screens/multiplayer/matchmaking_screen.dart';
import 'package:geoquiz_battle/presentation/screens/multiplayer/multiplayer_game_screen.dart';
import 'package:geoquiz_battle/presentation/screens/home/leaderboard_screen.dart';
import 'package:geoquiz_battle/presentation/screens/history/match_history_screen.dart';
import 'package:geoquiz_battle/presentation/screens/friends/friends_screen.dart';
import 'package:geoquiz_battle/presentation/providers/auth_provider.dart';
import 'package:geoquiz_battle/presentation/providers/multiplayer_provider.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import 'package:geoquiz_battle/core/theme/app_theme.dart';
import 'package:geoquiz_battle/presentation/widgets/common/geoc_page_transitions.dart';
import 'package:geoquiz_battle/l10n/generated/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStreamState = ref.watch(authStateChangesProvider);
  final authNotifierState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Check both: direct auth state (from sign-in methods) and stream state (from Firebase)
      final isLoggedIn = authNotifierState.valueOrNull != null ||
          authStreamState.valueOrNull != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isGoingToLogin && state.matchedLocation != '/') {
        return '/login';
      }

      // Redirect to home if authenticated and trying to access login
      if (isLoggedIn && isGoingToLogin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => GeoCTransitions.splashPage(
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => GeoCTransitions.enterFadeScale(
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => GeoCTransitions.enterFadeScale(
          duration: const Duration(milliseconds: 450),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/game/:difficulty',
        pageBuilder: (context, state) {
          final difficultyStr = state.pathParameters['difficulty'] ?? 'medium';
          final difficulty = Difficulty.values.firstWhere(
            (d) => d.name.toLowerCase() == difficultyStr.toLowerCase(),
            orElse: () => Difficulty.medium,
          );
          return GeoCTransitions.slideInFromRight(
            child: GameScreen(difficulty: difficulty),
          );
        },
      ),
      GoRoute(
        path: '/matchmaking/:mode',
        pageBuilder: (context, state) {
          final modeStr = state.pathParameters['mode'] ?? 'casual';
          final mode = MultiplayerMode.values.firstWhere(
            (m) => m.name.toLowerCase() == modeStr.toLowerCase(),
            orElse: () => MultiplayerMode.casual,
          );
          return GeoCTransitions.slideInFromBottom(
            child: MatchmakingScreen(mode: mode),
          );
        },
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (context, state) => GeoCTransitions.slideInFromRight(
          child: const LeaderboardScreen(),
        ),
      ),
      GoRoute(
        path: '/multiplayer-game',
        pageBuilder: (context, state) => GeoCTransitions.slideInFromBottom(
          child: const MultiplayerGameScreen(),
        ),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => GeoCTransitions.slideInFromRight(
          child: const MatchHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) => GeoCTransitions.slideInFromRight(
          child: const FriendsScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Main app widget
class GeoQuizBattleApp extends ConsumerWidget {
  const GeoQuizBattleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GeoQuiz Battle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
    );
  }
}
