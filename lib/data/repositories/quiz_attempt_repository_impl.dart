import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:geoquiz_battle/core/errors/exceptions.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/core/constants/firebase_constants.dart';
import 'package:geoquiz_battle/data/models/quiz_attempt_model.dart';
import 'package:geoquiz_battle/domain/repositories/quiz_attempt_repository.dart';

/// Implementación del repositorio de tracking de respuestas
class QuizAttemptRepositoryImpl implements QuizAttemptRepository {
  final FirebaseFirestore _firestore;

  QuizAttemptRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, String>> recordAttempt(
    QuizAttemptModel attempt,
  ) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.quizAttempts)
          .add(attempt.toFirestore());

      developer.log(
        'Quiz attempt recorded: ${attempt.questionId} - Correct: ${attempt.isCorrect}',
        name: 'QuizAttemptRepo',
      );

      return Right(docRef.id);
    } on FirebaseException catch (e) {
      developer.log(
        'FirebaseException recording attempt: ${e.code} - ${e.message}',
        name: 'QuizAttemptRepo',
        error: e,
      );
      return Left(ServerFailure('Firebase: ${e.code} - ${e.message}'));
    } on ServerException catch (e) {
      developer.log(
        'ServerException recording attempt: ${e.message}',
        name: 'QuizAttemptRepo',
      );
      return Left(ServerFailure(e.message));
    } catch (e) {
      developer.log(
        'Error recording attempt: $e',
        name: 'QuizAttemptRepo',
        error: e,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByQuestion(
    String questionId, {
    int limit = 1000,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.quizAttempts)
          .where('questionId', isEqualTo: questionId)
          .orderBy('answeredAt', descending: true)
          .limit(limit)
          .get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      return Right(attempts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByType(
    String questionType, {
    int limit = 1000,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.quizAttempts)
          .where('questionType', isEqualTo: questionType)
          .orderBy('answeredAt', descending: true)
          .limit(limit)
          .get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      return Right(attempts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? questionType,
    int limit = 1000,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.quizAttempts)
          .where('answeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('answeredAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('answeredAt', descending: true)
          .limit(limit);

      if (questionType != null) {
        query = query.where('questionType', isEqualTo: questionType);
      }

      final snapshot = await query.get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      return Right(attempts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByUser(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.quizAttempts)
          .where('userId', isEqualTo: userId)
          .orderBy('answeredAt', descending: true)
          .limit(limit)
          .get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      return Right(attempts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getSuccessRate(String questionId) async {
    final result = await getAttemptsByQuestion(questionId);

    return result.fold(
      (failure) => Left(failure),
      (attempts) {
        if (attempts.isEmpty) {
          return const Right(0.0);
        }

        final correct = attempts.where((a) => a.isCorrect).length;
        return Right(correct / attempts.length);
      },
    );
  }

  @override
  Future<Either<Failure, List<QuestionStats>>> getMostFailedQuestions({
    int limit = 10,
    int minAttempts = 10,
  }) async {
    try {
      // Obtener todos los intentos recientes
      final snapshot = await _firestore
          .collection(FirebaseConstants.quizAttempts)
          .orderBy('answeredAt', descending: true)
          .limit(10000) // Suficientemente grande para análisis
          .get();

      // Agrupar por pregunta
      final questionGroups = <String, List<QuizAttemptModel>>{};
      for (var doc in snapshot.docs) {
        final attempt = QuizAttemptModel.fromFirestore(doc);
        questionGroups.putIfAbsent(attempt.questionId, () => []);
        questionGroups[attempt.questionId]!.add(attempt);
      }

      // Calcular estadísticas para cada pregunta
      final stats = <QuestionStats>[];
      for (final entry in questionGroups.entries) {
        final attempts = entry.value;
        if (attempts.length < minAttempts) continue;

        final correct = attempts.where((a) => a.isCorrect).length;
        final incorrect = attempts.length - correct;
        final successRate = correct / attempts.length;

        final totalTime = attempts.fold<int>(0, (sum, a) => sum + a.timeMs);
        final avgTime = totalTime / attempts.length;

        final incorrectAttempts = attempts.where((a) => !a.isCorrect).toList();
        final totalSimilarity =
            incorrectAttempts.fold<double>(0, (sum, a) => sum + a.answerSimilarity);
        final avgSimilarity =
            incorrectAttempts.isEmpty ? 0.0 : totalSimilarity / incorrectAttempts.length;

        final timeoutCount = attempts.where((a) => a.isTimeout).length;

        stats.add(QuestionStats(
          questionId: entry.key,
          questionType: attempts.first.questionType,
          totalAttempts: attempts.length,
          correctAttempts: correct,
          incorrectAttempts: incorrect,
          successRate: successRate,
          avgTimeMs: avgTime,
          avgSimilarity: avgSimilarity,
          timeoutCount: timeoutCount,
        ));
      }

      // Ordenar por tasa de éxito (menor primero) y devolver los peores
      stats.sort((a, b) => a.successRate.compareTo(b.successRate));

      return Right(stats.take(limit).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestionStats>>> getEasiestQuestions({
    int limit = 10,
    int minAttempts = 10,
  }) async {
    final result = await getMostFailedQuestions(minAttempts: minAttempts);

    return result.fold(
      (failure) => Left(failure),
      (stats) {
        // Ordenar por tasa de éxito (mayor primero)
        final sorted = List<QuestionStats>.from(stats);
        sorted.sort((a, b) => b.successRate.compareTo(a.successRate));
        return Right(sorted.take(limit).toList());
      },
    );
  }

  @override
  Future<Either<Failure, Map<String, TypeStats>>> getStatsByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.quizAttempts);

      if (startDate != null) {
        query = query.where('answeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('answeredAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(10000).get();

      // Agrupar por tipo de pregunta
      final typeGroups = <String, List<QuizAttemptModel>>{};
      final uniqueQuestions = <String, Set<String>>{};

      for (var doc in snapshot.docs) {
        final attempt = QuizAttemptModel.fromFirestore(doc);
        typeGroups.putIfAbsent(attempt.questionType, () => []);
        typeGroups[attempt.questionType]!.add(attempt);

        uniqueQuestions.putIfAbsent(attempt.questionType, () => {});
        uniqueQuestions[attempt.questionType]!.add(attempt.questionId);
      }

      // Calcular estadísticas para cada tipo
      final stats = <String, TypeStats>{};
      for (final entry in typeGroups.entries) {
        final attempts = entry.value;
        final correct = attempts.where((a) => a.isCorrect).length;

        final totalTime = attempts.fold<int>(0, (sum, a) => sum + a.timeMs);
        final avgTime = totalTime / attempts.length;

        stats[entry.key] = TypeStats(
          type: entry.key,
          totalAttempts: attempts.length,
          correctAttempts: correct,
          successRate: correct / attempts.length,
          avgTimeMs: avgTime,
          uniqueQuestions: uniqueQuestions[entry.key]!.length,
        );
      }

      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
