import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../models/match_model.dart';

/// Match repository implementation
class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore _firestore;

  MatchRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, GameMatch>> getMatch(String matchId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .get();

      if (!doc.exists) {
        throw const NotFoundException('Match not found');
      }

      final gameMatch = MatchModel.fromFirestore(doc).toDomain();
      return Right(gameMatch);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<GameMatch> watchMatch(String matchId) {
    return _firestore
        .collection(FirebaseConstants.matches)
        .doc(matchId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw const NotFoundException('Match not found');
      }
      return MatchModel.fromFirestore(doc).toDomain();
    });
  }

  @override
  Future<Either<Failure, String>> createMatch(GameMatch gameMatch) async {
    try {
      final matchModel = MatchModel.fromDomain(gameMatch);
      final docRef = await _firestore
          .collection(FirebaseConstants.matches)
          .add(matchModel.toFirestore());
      return Right(docRef.id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMatch(
    String matchId,
    GameMatch gameMatch,
  ) async {
    try {
      final matchModel = MatchModel.fromDomain(gameMatch);
      await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .update(matchModel.toFirestore());
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitAnswer(
    String matchId,
    Answer answer,
  ) async {
    try {
      final docRef = _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .collection(FirebaseConstants.answers);

      // Get user ID from current Firebase user
      // In real implementation, you'd pass userId
      // For now, we'll use a placeholder
      final userId = 'current_user_id';

      final answerModel = {
        'questionIndex': answer.questionIndex,
        'selectedAnswer': answer.selectedAnswer,
        'isCorrect': answer.isCorrect,
        'timeMs': answer.timeMs,
        'answeredAt': Timestamp.fromDate(answer.answeredAt),
      };

      await docRef.doc(userId).set({
        'answers': FieldValue.arrayUnion([answerModel]),
      }, SetOptions(merge: true));

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GameMatch>>> getUserMatches(
    String userId, {
    int limit = 20,
    MatchStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.matches)
          .where(FirebaseConstants.players, arrayContains: userId)
          .orderBy(FirebaseConstants.createdAt, descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where(FirebaseConstants.status, isEqualTo: status.name);
      }

      final snapshot = await query.get();
      final matches = snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc).toDomain())
          .toList();

      return Right(matches);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finishMatch(String matchId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .update({
        FirebaseConstants.status: MatchStatus.finished.name,
        FirebaseConstants.finishedAt: FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}