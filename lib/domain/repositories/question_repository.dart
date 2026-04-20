import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/question.dart';

/// Question repository interface
abstract class QuestionRepository {
  /// Get random questions
  Future<Either<Failure, List<Question>>> getRandomQuestions({
    int count,
    List<QuestionType>? types,
    Difficulty? maxDifficulty,
  });

  /// Get question by ID
  Future<Either<Failure, Question>> getQuestionById(String id);

  /// Get questions by type
  Future<Either<Failure, List<Question>>> getQuestionsByType(
    QuestionType type,
  );

  /// Get questions by difficulty
  Future<Either<Failure, List<Question>>> getQuestionsByDifficulty(
    Difficulty difficulty,
  );

  /// Get questions by their IDs (for multiplayer shared questions)
  Future<Either<Failure, List<Question>>> getQuestionsByIds(List<String> ids);
}
