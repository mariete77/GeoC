import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoquiz_battle/core/errors/exceptions.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/core/constants/firebase_constants.dart';
import 'package:geoquiz_battle/core/constants/game_constants.dart';
import 'package:geoquiz_battle/domain/entities/match.dart';
import 'package:geoquiz_battle/domain/repositories/match_repository.dart';
import 'package:geoquiz_battle/data/models/match_model.dart';

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
      final data = matchModel.toFirestore();
      developer.log('Creating match with data: $data', name: 'MatchRepo');
      final docRef = await _firestore
          .collection(FirebaseConstants.matches)
          .add(data);
      developer.log('Match created with ID: ${docRef.id}', name: 'MatchRepo');
      return Right(docRef.id);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException creating match: ${e.code} - ${e.message}', name: 'MatchRepo', error: e);
      return Left(ServerFailure('Firebase: ${e.code} - ${e.message}'));
    } on ServerException catch (e) {
      developer.log('ServerException creating match: ${e.message}', name: 'MatchRepo');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      developer.log('Error creating match: $e', name: 'MatchRepo', error: e, level: 900);
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
    Answer answer, {
    String? userId,
  }) async {
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final docRef = _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .collection(FirebaseConstants.answers);

      final answerModel = {
        'questionIndex': answer.questionIndex,
        'selectedAnswer': answer.selectedAnswer,
        'isCorrect': answer.isCorrect,
        'timeMs': answer.timeMs,
        'answeredAt': Timestamp.fromDate(answer.answeredAt),
      };

      await docRef.doc(uid).set({
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

  @override
  Future<Either<Failure, GameMatch?>> findWaitingMatch({
    required String mode,
    required int playerElo,
    required String userId,
  }) async {
    try {
      // Use simple query (only status filter) to avoid needing composite indexes.
      // Filter by type and ELO client-side. No orderBy to avoid composite index requirement.
      final snapshot = await _firestore
          .collection(FirebaseConstants.matches)
          .where(FirebaseConstants.status, isEqualTo: 'waiting')
          .limit(20)
          .get();

      // Filter client-side: exclude own matches, match type, prefer ELO range
      final minElo = playerElo - GameConstants.matchmakingEloRange;
      final maxElo = playerElo + GameConstants.matchmakingEloRange;

      // First pass: find matches in ELO range and correct type
      var matches = snapshot.docs.where((doc) {
        final data = doc.data();
        final players = List<String>.from(data['players'] ?? []);
        final type = data['type'] as String? ?? '';
        final creatorElo = data['creatorElo'] as int? ?? 1000;
        return !players.contains(userId) &&
            type == mode &&
            creatorElo >= minElo &&
            creatorElo <= maxElo;
      }).toList();

      // Fallback: any waiting match of correct type regardless of ELO
      if (matches.isEmpty) {
        matches = snapshot.docs.where((doc) {
          final data = doc.data();
          final players = List<String>.from(data['players'] ?? []);
          final type = data['type'] as String? ?? '';
          return !players.contains(userId) && type == mode;
        }).toList();
      }

      if (matches.isEmpty) {
        return const Right(null);
      }

      final gameMatch = MatchModel.fromFirestore(matches.first).toDomain();
      return Right(gameMatch);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameMatch>> joinMatch({
    required String matchId,
    required String userId,
  }) async {
    try {
      // Atomically add player and activate match
      await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .update({
        FirebaseConstants.players: FieldValue.arrayUnion([userId]),
        FirebaseConstants.status: 'active',
        FirebaseConstants.startedAt: FieldValue.serverTimestamp(),
      });

      // Fetch updated match
      final doc = await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .get();

      if (!doc.exists) {
        throw const NotFoundException('Match not found after joining');
      }

      return Right(MatchModel.fromFirestore(doc).toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Answer>>> getPlayerAnswers({
    required String matchId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .collection(FirebaseConstants.answers)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return const Right([]);
      }

      final data = doc.data()!;
      final answersList = List<Map<String, dynamic>>.from(data['answers'] ?? []);

      final answers = answersList.map((a) => Answer(
        questionIndex: a['questionIndex'] as int? ?? 0,
        selectedAnswer: a['selectedAnswer'] as String? ?? '',
        isCorrect: a['isCorrect'] as bool? ?? false,
        timeMs: a['timeMs'] as int? ?? 0,
        answeredAt: a['answeredAt'] is Timestamp
            ? (a['answeredAt'] as Timestamp).toDate()
            : DateTime.now(),
      )).toList();

      return Right(answers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
