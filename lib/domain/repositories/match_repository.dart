import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/match.dart';

/// Match repository interface
abstract class MatchRepository {
  /// Get match by ID
  Future<Either<Failure, GameMatch>> getMatch(String matchId);

  /// Watch match updates (realtime)
  Stream<GameMatch> watchMatch(String matchId);

  /// Create match (for testing/admin)
  Future<Either<Failure, String>> createMatch(GameMatch gameMatch);

  /// Update match
  Future<Either<Failure, void>> updateMatch(String matchId, GameMatch gameMatch);

  /// Submit answer
  Future<Either<Failure, void>> submitAnswer(
    String matchId,
    Answer answer,
  );

  /// Get user's matches
  Future<Either<Failure, List<GameMatch>>> getUserMatches(
    String userId, {
    int limit,
    MatchStatus? status,
  });

  /// Finish match (call when game ends)
  Future<Either<Failure, void>> finishMatch(String matchId);

  /// Find a waiting match for the given mode and ELO range
  Future<Either<Failure, GameMatch?>> findWaitingMatch({
    required String mode,
    required int playerElo,
    required String userId,
  });

  /// Join an existing waiting match
  Future<Either<Failure, GameMatch>> joinMatch({
    required String matchId,
    required String userId,
  });

  /// Get a player's submitted answers for a match
  Future<Either<Failure, List<Answer>>> getPlayerAnswers({
    required String matchId,
    required String userId,
  });
}
