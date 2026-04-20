import 'package:geoquiz_battle/domain/entities/question.dart';
import 'package:geoquiz_battle/domain/repositories/question_repository.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// Mock implementation of QuestionRepository for testing
class MockQuestionRepository implements QuestionRepository {
  final Map<String, Question> _questions = {};
  final List<Question> _allQuestions = [];

  MockQuestionRepository({List<Question>? initialQuestions}) {
    if (initialQuestions != null) {
      for (final question in initialQuestions) {
        _questions[question.id] = question;
        _allQuestions.add(question);
      }
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getRandomQuestions({
    int count = 10,
    List<QuestionType>? types,
    Difficulty? maxDifficulty,
  }) async {
    var filtered = List<Question>.from(_allQuestions);

    // Filter by type if specified
    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((q) => types.contains(q.type)).toList();
    }

    // Filter by difficulty if specified
    if (maxDifficulty != null) {
      filtered = filtered
          .where((q) => q.difficulty.index <= maxDifficulty.index)
          .toList();
    }

    // Shuffle and take count
    filtered.shuffle();
    final result = filtered.take(count).toList();

    if (result.isEmpty) {
      return Left(NotFoundFailure('No questions available'));
    }

    return Right(result);
  }

  @override
  Future<Either<Failure, Question>> getQuestionById(String id) async {
    final question = _questions[id];
    if (question == null) {
      return Left(NotFoundFailure('Question not found: $id'));
    }
    return Right(question);
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByType(
    QuestionType type,
  ) async {
    final filtered =
        _allQuestions.where((q) => q.type == type).toList();
    if (filtered.isEmpty) {
      return Left(NotFoundFailure('No questions of type: $type'));
    }
    return Right(filtered);
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByDifficulty(
    Difficulty difficulty,
  ) async {
    final filtered = _allQuestions.where((q) => q.difficulty == difficulty).toList();
    if (filtered.isEmpty) {
      return Left(NotFoundFailure('No questions of difficulty: $difficulty'));
    }
    return Right(filtered);
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByIds(List<String> ids) async {
    final questions = ids
        .map((id) => _questions[id])
        .whereType<Question>()
        .toList();
    return Right(questions);
  }

  /// Helper method to add questions to the mock
  void addQuestion(Question question) {
    _questions[question.id] = question;
    _allQuestions.add(question);
  }

  /// Helper method to get all questions
  List<Question> getAllQuestions() {
    return List.unmodifiable(_allQuestions);
  }

  /// Helper method to clear all questions
  void clear() {
    _questions.clear();
    _allQuestions.clear();
  }
}

/// Factory for creating sample questions for testing
class QuestionFactory {
  static Question createSample({
    String id = 'q1',
    QuestionType type = QuestionType.flag,
    Difficulty difficulty = Difficulty.medium,
    String correctAnswer = 'Spain',
    List<String>? options,
    String? imageUrl,
    String? questionText,
  }) {
    return Question(
      id: id,
      type: type,
      difficulty: difficulty,
      correctAnswer: correctAnswer,
      options: options ?? ['Spain', 'France', 'Italy', 'Portugal'],
      imageUrl: imageUrl,
      questionText: questionText,
      extraData: null,
    );
  }

  static List<Question> createSampleQuestions({int count = 10}) {
    final questions = <Question>[];
    for (int i = 0; i < count; i++) {
      questions.add(createSample(
        id: 'q$i',
        type: QuestionType.values[i % QuestionType.values.length],
        difficulty: Difficulty.values[i % Difficulty.values.length],
      ));
    }
    return questions;
  }
}