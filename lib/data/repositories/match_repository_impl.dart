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
      // Use simple query (only arrayContains) to avoid composite index requirement.
      // Filter by status and sort client-side.
      final snapshot = await _firestore
          .collection(FirebaseConstants.matches)
          .where(FirebaseConstants.players, arrayContains: userId)
          .limit(50)
          .get();

      // Filter by status client-side
      var docs = snapshot.docs;
      if (status != null) {
        docs = docs.where((doc) {
          final data = doc.data();
          return data[FirebaseConstants.status] == status.name;
        }).toList();
      }

      // Sort client-side by createdAt descending
      docs.sort((a, b) {
        final aMs = (a.data()[FirebaseConstants.createdAt] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        final bMs = (b.data()[FirebaseConstants.createdAt] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        return bMs.compareTo(aMs);
      });

      // Apply limit
      docs = docs.take(limit).toList();

      final matches = docs
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
      final logMsg = 'Searching for $mode match for user $userId (Elo: $playerElo)';
      developer.log(logMsg, name: 'MatchRepo');
      print('DEBUG: $logMsg');
      
      // Get any waiting match of correct type.
      final snapshot = await _firestore
          .collection(FirebaseConstants.matches)
          .where(FirebaseConstants.status, isEqualTo: 'waiting')
          .limit(40)
          .get();

      if (snapshot.docs.isEmpty) {
        const msg = 'No waiting matches found in Firestore';
        developer.log(msg, name: 'MatchRepo');
        print('DEBUG: $msg');
        return const Right(null);
      }

      // Filter client-side: exclude own matches, match type
      final matches = snapshot.docs.where((doc) {
        final data = doc.data();
        final players = List<String>.from(data['players'] ?? []);
        final matchType = data['type'] as String? ?? '';
        
        final isOwnMatch = players.contains(userId);
        final isCorrectType = matchType == mode;
        
        return !isOwnMatch && isCorrectType;
      }).toList();

      if (matches.isEmpty) {
        final msg = 'Found ${snapshot.docs.length} waiting matches, but none match criteria (mode=$mode, not own)';
        developer.log(msg, name: 'MatchRepo');
        print('DEBUG: $msg');
        return const Right(null);
      }

      // If multiple, pick the one closest to player ELO
      matches.sort((a, b) {
        final eloA = (a.data()['creatorElo'] as int? ?? 1000);
        final eloB = (b.data()['creatorElo'] as int? ?? 1000);
        return (eloA - playerElo).abs().compareTo((eloB - playerElo).abs());
      });

      final foundId = matches.first.id;
      developer.log('Match found! ID: $foundId', name: 'MatchRepo');
      print('DEBUG: Match found! ID: $foundId');
      
      final gameMatch = MatchModel.fromFirestore(matches.first).toDomain();
      return Right(gameMatch);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final errMsg = 'Error finding match: $e';
      developer.log(errMsg, name: 'MatchRepo', error: e);
      print('DEBUG: $errMsg');
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

  @override
  Future<Either<Failure, void>> saveMatchResult({
    required String matchId,
    required MatchResult result,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.matches)
          .doc(matchId)
          .update({
        'result': {
          'winnerId': result.winnerId,
          'scores': result.scores,
          'eloChanges': result.eloChanges,
          'newElo': result.newElo,
        },
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
