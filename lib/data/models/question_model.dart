import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geoquiz_battle/data/models/json_key_converter.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';

part 'question_model.freezed.dart';

@freezed
class QuestionModel with _$QuestionModel {
  const QuestionModel._();

  const factory QuestionModel({
    required String id,
    @QuestionTypeConverter() required QuestionType type,
    @DifficultyConverter() required Difficulty difficulty,
    required String correctAnswer,
    required List<String> options,
    String? imageUrl,
    String? questionText,
    Map<String, dynamic>? extraData,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing with defaults for null fields
    return QuestionModel(
      id: (json['id'] as String?) ?? '',
      type: const QuestionTypeConverter()
          .fromJson((json['type'] as String?) ?? 'flag'),
      difficulty: const DifficultyConverter()
          .fromJson((json['difficulty'] as String?) ?? 'medium'),
      correctAnswer: (json['correctAnswer'] as String?) ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['imageUrl'] as String?,
      questionText: json['questionText'] as String?,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  /// Convert to domain entity
  Question toDomain() {
    return Question(
      id: id,
      type: type,
      difficulty: difficulty,
      correctAnswer: correctAnswer,
      options: options,
      imageUrl: imageUrl,
      questionText: questionText,
      extraData: extraData,
    );
  }

  /// Convert from domain entity
  factory QuestionModel.fromDomain(Question question) {
    return QuestionModel(
      id: question.id,
      type: question.type,
      difficulty: question.difficulty,
      correctAnswer: question.correctAnswer,
      options: question.options,
      imageUrl: question.imageUrl,
      questionText: question.questionText,
      extraData: question.extraData,
    );
  }

  /// Check if answer is correct
  bool isCorrect(String answer) {
    return answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
  }
}
