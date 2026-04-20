import 'package:equatable/equatable.dart';

/// Question types
enum QuestionType {
  silhouette,
  flag,
  capital,
  population,
  river,
  cityPhoto,
  area,
  language,
  currency,
  region,
}

/// Question difficulty
enum Difficulty { easy, medium, hard }

/// Question entity
class Question extends Equatable {
  final String id;
  final QuestionType type;
  final Difficulty difficulty;
  final String correctAnswer;
  final List<String> options;
  final String? imageUrl;
  final String? questionText;
  final Map<String, dynamic>? extraData;

  const Question({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.correctAnswer,
    required this.options,
    this.imageUrl,
    this.questionText,
    this.extraData,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        difficulty,
        correctAnswer,
        options,
        imageUrl,
        questionText,
        extraData,
      ];

  /// Check if answer is correct
  bool isCorrect(String answer) {
    return answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
  }
}
