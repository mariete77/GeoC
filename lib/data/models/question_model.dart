import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_key_converter.dart';
import '../domain/entities/question.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {
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

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

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
