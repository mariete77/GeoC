/// Score Calculator for game questions
///
/// Contains pure functions for calculating scores, ranks, and other
/// game-related calculations.

/// Calculates the score for a single question answer.
///
/// [isCorrect] - Whether the answer was correct
/// [timeRemaining] - Seconds remaining when answered (0-10)
/// [streak] - Current streak of correct answers
/// [isTimeout] - Whether the answer timed out
///
/// Returns the score for this question.
int calculateQuestionScore({
  required bool isCorrect,
  required int timeRemaining,
  required int streak,
  required bool isTimeout,
}) {
  if (isTimeout) {
    return 0;
  }

  if (!isCorrect) {
    return 0;
  }

  const baseScore = 100;
  final timeBonus = timeRemaining * 10;
  final streakBonus = streak * 50;

  return baseScore + timeBonus + streakBonus;
}

/// Determines the result rank based on accuracy and total score.
///
/// [accuracy] - Percentage of correct answers (0.0 to 1.0)
/// [totalScore] - Total score achieved in the game
///
/// Returns a rank string (LEGENDARY, MASTER, EXPERT, SKILLED, BEGINNER, ROOKIE).
String calculateResultRank(double accuracy, int totalScore) {
  if (accuracy >= 0.9 && totalScore >= 1500) {
    return 'LEGENDARY';
  }
  if (accuracy >= 0.8 && totalScore >= 1200) {
    return 'MASTER';
  }
  if (accuracy >= 0.7 && totalScore >= 900) {
    return 'EXPERT';
  }
  if (accuracy >= 0.6 && totalScore >= 600) {
    return 'SKILLED';
  }
  if (accuracy >= 0.5) {
    return 'BEGINNER';
  }
  return 'ROOKIE';
}

/// Gets the color associated with a result rank.
///
/// [rank] - Rank string (LEGENDARY, MASTER, etc.)
///
/// Returns a color value (as integer) for the rank.
int getRankColor(String rank) {
  switch (rank) {
    case 'LEGENDARY':
      return 0xFFFFD700; // Gold
    case 'MASTER':
      return 0xFFC0C0C0; // Silver
    case 'EXPERT':
      return 0xFFCD7F32; // Bronze
    case 'SKILLED':
      return 0xFF00FF00; // Green
    case 'BEGINNER':
      return 0xFF0000FF; // Blue
    case 'ROOKIE':
      return 0xFF808080; // Grey
    default:
      return 0xFF000000; // Black
  }
}

/// Calculates accuracy from correct and total answers.
///
/// [correctAnswers] - Number of correct answers
/// [totalQuestions] - Total number of questions
///
/// Returns accuracy as a double between 0.0 and 1.0.
double calculateAccuracy(int correctAnswers, int totalQuestions) {
  if (totalQuestions == 0) {
    return 0.0;
  }
  return correctAnswers / totalQuestions;
}

/// Calculates average time per answer in milliseconds.
///
/// [totalTimeMs] - Total time spent on all answers (milliseconds)
/// [totalAnswers] - Number of answers provided
///
/// Returns average time in milliseconds, or 0.0 if no answers.
double calculateAverageTime(int totalTimeMs, int totalAnswers) {
  if (totalAnswers == 0) {
    return 0.0;
  }
  return totalTimeMs / totalAnswers;
}

/// Validates that the given difficulty string is valid.
///
/// [difficulty] - Difficulty string to validate
///
/// Returns true if the difficulty is one of: easy, medium, hard.
bool isValidDifficulty(String difficulty) {
  return difficulty == 'easy' ||
      difficulty == 'medium' ||
      difficulty == 'hard';
}

/// Converts a difficulty string to a numeric weight for sorting.
///
/// [difficulty] - Difficulty string
///
/// Returns weight (1 for easy, 2 for medium, 3 for hard, 0 for unknown).
int difficultyToWeight(String difficulty) {
  switch (difficulty) {
    case 'easy':
      return 1;
    case 'medium':
      return 2;
    case 'hard':
      return 3;
    default:
      return 0;
  }
}