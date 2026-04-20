import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// User repository interface
abstract class UserRepository {
  /// Get user profile by ID
  Future<Either<Failure, User>> getUserProfile(String userId);

  /// Update user profile
  Future<Either<Failure, void>> updateUserProfile(User user);

  /// Get user stats
  Future<Either<Failure, UserStats>> getUserStats(String userId);

  /// Update user stats (after match)
  Future<Either<Failure, void>> updateUserStats(
    String userId,
    Map<String, dynamic> statsUpdate,
  );

  /// Get daily games remaining
  Future<Either<Failure, DailyGames>> getDailyGames(String userId);

  /// Record game played
  Future<Either<Failure, void>> recordGamePlayed(
    String userId,
    bool isRanked,
  );

  /// Update subscription status
  Future<Either<Failure, void>> updateSubscription(
    String userId,
    String type,
    bool isActive,
    DateTime? expiresAt,
  );

  /// Get leaderboard — all users sorted by ELO descending
  Future<Either<Failure, List<User>>> getLeaderboard({int limit = 50});
}
