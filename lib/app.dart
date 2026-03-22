import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'core/theme/app_theme.dart';

/// App router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // If auth state is loading, don't redirect
      if (authState.value == null) {
        return null;
      }

      final isLoggingIn = state.matchedLocation == '/login';
      final isLoggedIn = authState.value != null;

      // If user is logged in and trying to access login, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      // If user is not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isLoggingIn && state.matchedLocation != '/') {
        return '/login';
      }

      return null;
    },
    routes: [
      // Splash screen (initial)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Home screen (protected)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // TODO: Add more routes as we build them
      // GoRoute(
      //   path: '/matchmaking',
      //   name: 'matchmaking',
      //   builder: (context, state) => const MatchmakingScreen(),
      // ),

      // GoRoute(
      //   path: '/game/:matchId',
      //   name: 'game',
      //   builder: (context, state) => GameScreen(
      //     matchId: state.pathParameters['matchId']!,
      //   ),
      // ),

      // GoRoute(
      //   path: '/results/:matchId',
      //   name: 'results',
      //   builder: (context, state) => ResultsScreen(
      //     matchId: state.pathParameters['matchId']!,
      //   ),
      // ),
    ],
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
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
