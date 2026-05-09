import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:geoquiz_battle/core/errors/exceptions.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/core/constants/firebase_constants.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import 'package:geoquiz_battle/domain/repositories/question_repository.dart';
import 'package:geoquiz_battle/data/models/question_model.dart';

/// Question repository implementation
class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  QuestionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<Question>>> getRandomQuestions({
    int count = 10,
    List<QuestionType>? types,
    Difficulty? maxDifficulty,
  }) async {
    try {
      // Get all eligible questions
      Query query = _firestore.collection(FirebaseConstants.questions);

      if (types != null && types.isNotEmpty) {
        query = query.where(
          FirebaseConstants.questionType,
          whereIn: types.map((t) => t.name).toList(),
        );
      }

      if (maxDifficulty != null) {
        query = query.where(
          FirebaseConstants.difficulty,
          isLessThanOrEqualTo: maxDifficulty.name,
        );
      }

      final snapshot = await query.get();
      final allQuestions = snapshot.docs
          .map((doc) => QuestionModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }).toDomain())
          .toList();

      if (allQuestions.isEmpty) {
        throw const NotFoundException('No questions found');
      }

      // Shuffle and select
      allQuestions.shuffle(_random);

      // Ensure variety of types
      return Right(_selectBalancedQuestions(allQuestions, count));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Question>> getQuestionById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.questions)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw const NotFoundException('Question not found');
      }

      final question =
          QuestionModel.fromJson({'id': doc.id, ...doc.data()!}).toDomain();
      return Right(question);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByType(
    QuestionType type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.questions)
          .where(FirebaseConstants.questionType, isEqualTo: type.name)
          .get();

      final questions = snapshot.docs
          .map((doc) => QuestionModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }).toDomain())
          .toList();

      return Right(questions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByDifficulty(
    Difficulty difficulty,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.questions)
          .where(FirebaseConstants.difficulty, isEqualTo: difficulty.name)
          .get();

      final questions = snapshot.docs
          .map((doc) => QuestionModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }).toDomain())
          .toList();

      return Right(questions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return const Right([]);

      final questions = <Question>[];
      // Firestore 'in' queries support max 30 items
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
        final snapshot = await _firestore
            .collection(FirebaseConstants.questions)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          questions.add(QuestionModel.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }).toDomain());
        }
      }

      // Preserve original order
      final questionMap = {for (final q in questions) q.id: q};
      final ordered = ids
          .map((id) => questionMap[id])
          .whereType<Question>()
          .toList();

      return Right(ordered);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Select balanced questions (variety of types)
  List<Question> _selectBalancedQuestions(
    List<Question> questions,
    int count,
  ) {
    final selected = <Question>[];
    final usedTypes = <QuestionType>{};

    // First pass: one of each type
    for (final q in questions) {
      if (!usedTypes.contains(q.type) && selected.length < count) {
        selected.add(q);
        usedTypes.add(q.type);
      }
      if (selected.length >= 10) break; // 10 types max
    }

    // Second pass: fill up to count
    for (final q in questions) {
      if (!selected.contains(q) && selected.length < count) {
        selected.add(q);
      }
      if (selected.length >= count) break;
    }

    selected.shuffle(_random);

    // Enrich questions with fewer than 4 options
    return selected.map((q) => _enrichOptions(q, questions)).toList();
  }

  /// Enrich a question's options to have at least 4 choices.
  /// For questions with 0-3 options, adds random distractors from other questions.
  /// Filters distractors by type to avoid mixing currencies, languages, etc.
  Question _enrichOptions(Question question, List<Question> allQuestions) {
    if (question.options.length >= 4) return question;

    final comparisonTypes = {
      QuestionType.population,
      QuestionType.area,
      QuestionType.border,
      QuestionType.region,
    };

    if (question.options.isEmpty && !comparisonTypes.contains(question.type)) {
      return question;
    }

    final enrichedOptions = List<String>.from(question.options);

    // Collect answers from the SAME question type only for type-specific enrichment
    final sameTypeAnswers = allQuestions
        .where((q) => q.type == question.type)
        .map((q) => q.correctAnswer)
        .where((a) => a.isNotEmpty && a != question.correctAnswer)
        .where((a) => !enrichedOptions.contains(a))
        .toSet()
        .toList();

    sameTypeAnswers.shuffle(_random);
    for (final distractor in sameTypeAnswers) {
      if (enrichedOptions.length >= 4) break;
      enrichedOptions.add(distractor);
    }

    // Fallback: if still not enough, use any answer but prefer countries for geo types
    if (enrichedOptions.length < 4) {
      final geoTypes = {QuestionType.population, QuestionType.area, QuestionType.flag, QuestionType.silhouette};
      final isGeoType = geoTypes.contains(question.type);

      final fallbackAnswers = allQuestions
          .map((q) => q.correctAnswer)
          .where((a) => a.isNotEmpty && a != question.correctAnswer)
          .where((a) => !enrichedOptions.contains(a))
          .toSet()
          .toList();

      fallbackAnswers.shuffle(_random);

      if (isGeoType) {
        final countryAnswers = allQuestions
            .where((q) => geoTypes.contains(q.type))
            .map((q) => q.correctAnswer)
            .where((a) => a.isNotEmpty && a != question.correctAnswer)
            .where((a) => !enrichedOptions.contains(a))
            .toSet()
            .toList();
        countryAnswers.shuffle(_random);
        fallbackAnswers.insertAll(0, countryAnswers);
      }

      for (final distractor in fallbackAnswers) {
        if (enrichedOptions.length >= 4) break;
        enrichedOptions.add(distractor);
      }
    }

    if (enrichedOptions.length < 2) return question;
    if (!enrichedOptions.contains(question.correctAnswer)) {
      enrichedOptions.add(question.correctAnswer);
    }
    enrichedOptions.shuffle(_random);

    return Question(
      id: question.id,
      type: question.type,
      difficulty: question.difficulty,
      correctAnswer: question.correctAnswer,
      options: enrichedOptions,
      imageUrl: question.imageUrl,
      questionText: question.questionText,
      extraData: question.extraData,
    );
  }
}
