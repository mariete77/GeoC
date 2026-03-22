import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/match.dart';

/// Ghost run repository interface
abstract class GhostRunRepository {
  /// Find a ghost run to play against
  Future<Either<Failure, GhostRun?>> findGhostRun({
    required String userId,
    required int playerElo,
  });

  /// Save ghost run after playing
  Future<Either<Failure, void>> saveGhostRun({
    required String userId,
    required int elo,
    required List<String> questionIds,
    required List<Answer> answers,
  });

  /// Get user's ghost runs
  Future<Either<Failure, List<GhostRun>>> getUserGhostRuns(String userId);

  /// Delete old ghost runs (keep last N)
  Future<Either<Failure, void>> cleanupOldGhostRuns(
    String userId,
    int keepCount,
  );
}
