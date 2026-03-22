import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/failures.dart';

part 'user_provider.g.dart';

/// User repository provider
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl();
}

/// Current user profile provider
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.data(null);
  }

  /// Get user profile
  Future<void> getUserProfile(String userId) async {
    state = const AsyncValue.loading();
    final result = await ref.read(userRepositoryProvider).getUserProfile(userId);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  /// Update user profile
  Future<void> updateUserProfile(User user) async {
    final currentData = state.valueOrNull;
    if (currentData == null) return;

    state = AsyncValue.data(user);
    final result = await ref.read(userRepositoryProvider).updateUserProfile(user);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        // Success - state already updated
      },
    );
  }

  /// Record game played
  Future<void> recordGamePlayed(String userId, bool isRanked) async {
    final result =
        await ref.read(userRepositoryProvider).recordGamePlayed(userId, isRanked);
    result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => getUserProfile(userId), // Refresh user profile
    );
  }

  /// Get daily games remaining
  Future<void> getDailyGames(String userId) async {
    final result =
        await ref.read(userRepositoryProvider).getDailyGames(userId);
    // Daily games are part of user profile, so refresh profile
    result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => getUserProfile(userId),
    );
  }

  /// Get error message
  String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return 'An unknown error occurred';
  }
}

/// Daily games status provider
@riverpod
DailyGamesStatus dailyGamesStatus(DailyGamesStatusRef ref) {
  final user = ref.watch(userNotifierProvider);
  return user.when(
    data: (userData) {
      if (userData == null) {
        return DailyGamesStatus.unknown();
      }

      final dailyGames = userData.dailyGames;
      final isPremium = userData.isPremium;

      final casualRemaining = isPremium
          ? 999 // Ilimitadas para premium
          : 1 - dailyGames.casualPlayed;
      final rankedRemaining = isPremium
          ? 5 - dailyGames.rankedPlayed
          : 1 - dailyGames.rankedPlayed;

      return DailyGamesStatus(
        casualRemaining: casualRemaining.clamp(0, 999),
        rankedRemaining: rankedRemaining.clamp(0, 5),
        canPlayCasual: casualRemaining > 0,
        canPlayRanked: rankedRemaining > 0,
      );
    },
    loading: () => DailyGamesStatus.unknown(),
    error: (_, __) => DailyGamesStatus.unknown(),
  );
}

/// Daily games status model
class DailyGamesStatus {
  final int casualRemaining;
  final int rankedRemaining;
  final bool canPlayCasual;
  final bool canPlayRanked;

  const DailyGamesStatus({
    required this.casualRemaining,
    required this.rankedRemaining,
    required this.canPlayCasual,
    required this.canPlayRanked,
  });

  factory DailyGamesStatus.unknown() {
    return const DailyGamesStatus(
      casualRemaining: 0,
      rankedRemaining: 0,
      canPlayCasual: false,
      canPlayRanked: false,
    );
  }
}
