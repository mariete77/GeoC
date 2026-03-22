import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/match.dart';

/// Match repository interface
abstract class MatchRepository {
  /// Get match by ID
  Future<Either<Failure, Match>> getMatch(String matchId);

  /// Watch match updates (realtime)
  Stream<Match> watchMatch(String matchId);

  /// Create match (for testing/admin)
  Future<Either<Failure, String>> createMatch(Match match);

  /// Update match
  Future<Either<Failure, void>> updateMatch(String matchId, Match match);

  /// Submit answer
  Future<Either<Failure, void>> submitAnswer(
    String matchId,
    Answer answer,
  );

  /// Get user's matches
  Future<Either<Failure, List<Match>>> getUserMatches(
    String userId, {
    int limit,
    MatchStatus? status,
  });

  /// Finish match (call when game ends)
  Future<Either<Failure, void>> finishMatch(String matchId);
}
