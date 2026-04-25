import 'package:dartz/dartz.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/data/models/quiz_attempt_model.dart';

/// Stats for a single question's attempts
class QuestionStats {
  final String questionId;
  final String questionType;
  final int totalAttempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final double successRate;
  final double avgTimeMs;
  final double avgSimilarity;
  final int timeoutCount;

  const QuestionStats({
    required this.questionId,
    required this.questionType,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.successRate,
    required this.avgTimeMs,
    required this.avgSimilarity,
    required this.timeoutCount,
  });
}

/// Stats for a question type
class TypeStats {
  final String type;
  final int totalAttempts;
  final int correctAttempts;
  final double successRate;
  final double avgTimeMs;
  final int uniqueQuestions;

  const TypeStats({
    required this.type,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.successRate,
    required this.avgTimeMs,
    required this.uniqueQuestions,
  });
}

/// Repository interface for tracking quiz attempts (analytics)
abstract class QuizAttemptRepository {
  Future<Either<Failure, String>> recordAttempt(QuizAttemptModel attempt);
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByQuestion(String questionId, {int limit});
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByType(String questionType, {int limit});
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByDateRange(DateTime startDate, DateTime endDate, {String? questionType, int limit});
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByUser(String userId, {int limit});
  Future<Either<Failure, double>> getSuccessRate(String questionId);
  Future<Either<Failure, List<QuestionStats>>> getMostFailedQuestions({int limit, int minAttempts});
  Future<Either<Failure, List<QuestionStats>>> getEasiestQuestions({int limit, int minAttempts});
  Future<Either<Failure, Map<String, TypeStats>>> getStatsByType({DateTime? startDate, DateTime? endDate});
}