import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/ghost_run_repository.dart';
import '../models/ghost_run_model.dart';

/// Ghost run repository implementation
class GhostRunRepositoryImpl implements GhostRunRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  GhostRunRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, GhostRun?>> findGhostRun({
    required String userId,
    required int playerElo,
  }) async {
    try {
      // Search for ghost runs in similar ELO range
      final minElo = playerElo - GameConstants.ghostRunEloRange;
      final maxElo = playerElo + GameConstants.ghostRunEloRange;

      final snapshot = await _firestore
          .collection(FirebaseConstants.ghostRuns)
          .where(FirebaseConstants.elo, isGreaterThanOrEqualTo: minElo)
          .where(FirebaseConstants.elo, isLessThanOrEqualTo: maxElo)
          .where(FirebaseConstants.ghostUserId, isNotEqualTo: userId)
          .orderBy(FirebaseConstants.elo)
          .orderBy(FirebaseConstants.createdAt, descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        // If no ghost runs in range, search for any
        final fallbackSnapshot = await _firestore
            .collection(FirebaseConstants.ghostRuns)
            .where(FirebaseConstants.ghostUserId, isNotEqualTo: userId)
            .orderBy(FirebaseConstants.ghostUserId)
            .orderBy(FirebaseConstants.createdAt, descending: true)
            .limit(10)
            .get();

        if (fallbackSnapshot.docs.isEmpty) {
          return const Right(null);
        }

        final randomIndex = _random.nextInt(fallbackSnapshot.docs.length);
        final ghostRun =
            GhostRunModel.fromFirestore(fallbackSnapshot.docs[randomIndex])
                .toDomain();
        return Right(ghostRun);
      }

      // Select random ghost run from range
      final randomIndex = _random.nextInt(snapshot.docs.length);
      final ghostRun =
          GhostRunModel.fromFirestore(snapshot.docs[randomIndex]).toDomain();
      return Right(ghostRun);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveGhostRun({
    required String userId,
    required int elo,
    required List<String> questionIds,
    required List<Answer> answers,
  }) async {
    try {
      final ghostAnswers = answers
          .map((a) => GhostAnswer(
                questionIndex: a.questionIndex,
                isCorrect: a.isCorrect,
                timeMs: a.timeMs,
              ))
          .toList();

      final runId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final ghostRun = GhostRunModel(
        userId: userId,
        ghostRunId: runId,
        elo: elo,
        questionIds: questionIds,
        answers: ghostAnswers
            .map((a) => GhostAnswerModel.fromDomain(a))
            .toList(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.ghostRuns)
          .doc(runId)
          .set(ghostRun.toFirestore());

      // Cleanup old ghost runs (keep last N)
      await _cleanupOldGhostRuns(userId, GameConstants.maxGhostRunsPerUser);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GhostRun>>> getUserGhostRuns(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.ghostRuns)
          .where(FirebaseConstants.ghostUserId, isEqualTo: userId)
          .orderBy(FirebaseConstants.createdAt, descending: true)
          .get();

      final ghostRuns = snapshot.docs
          .map((doc) => GhostRunModel.fromFirestore(doc).toDomain())
          .toList();

      return Right(ghostRuns);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> _cleanupOldGhostRuns(
    String userId,
    int keepCount,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.ghostRuns)
          .where(FirebaseConstants.ghostUserId, isEqualTo: userId)
          .orderBy(FirebaseConstants.createdAt, descending: true)
          .get();

      if (snapshot.docs.length > keepCount) {
        final toDelete = snapshot.docs.sublist(keepCount);
        final batch = _firestore.batch();

        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}