import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geoquiz_battle/presentation/screens/splash/splash_screen.dart';
import 'package:geoquiz_battle/presentation/screens/auth/login_screen.dart';
import 'package:geoquiz_battle/presentation/screens/home/home_screen.dart';
import 'package:geoquiz_battle/presentation/screens/game/game_screen.dart';
import 'package:geoquiz_battle/presentation/screens/multiplayer/matchmaking_screen.dart';
import 'package:geoquiz_battle/presentation/screens/multiplayer/multiplayer_game_screen.dart';
import 'package:geoquiz_battle/presentation/providers/auth_provider.dart';
import 'package:geoquiz_battle/presentation/providers/multiplayer_provider.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import 'package:geoquiz_battle/core/theme/app_theme.dart';
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game/:difficulty',
        builder: (context, state) {
          final difficultyStr = state.pathParameters['difficulty'] ?? 'medium';
          final difficulty = Difficulty.values.firstWhere(
            (d) => d.name.toLowerCase() == difficultyStr.toLowerCase(),
            orElse: () => Difficulty.medium,
          );
          return GameScreen(difficulty: difficulty);
        },
      ),
      GoRoute(
        path: '/matchmaking/:mode',
        builder: (context, state) {
          final modeStr = state.pathParameters['mode'] ?? 'casual';
          final mode = MultiplayerMode.values.firstWhere(
            (m) => m.name.toLowerCase() == modeStr.toLowerCase(),
            orElse: () => MultiplayerMode.casual,
          );
          return MatchmakingScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/multiplayer-game',
        builder: (context, state) => const MultiplayerGameScreen(),
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
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
    );
  }
}
