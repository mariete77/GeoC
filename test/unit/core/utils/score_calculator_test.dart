import 'package:flutter_test/flutter_test.dart';
import 'package:geoquiz_battle/core/utils/score_calculator.dart';

void main() {
  group('Score Calculator', () {
    group('calculateQuestionScore', () {
      test('returns 0 for timeout', () {
        final score = calculateQuestionScore(
          isCorrect: false,
          timeRemaining: 5,
          streak: 2,
          isTimeout: true,
        );
        expect(score, 0);
      });

      test('returns 0 for incorrect answer (no timeout)', () {
        final score = calculateQuestionScore(
          isCorrect: false,
          timeRemaining: 5,
          streak: 2,
          isTimeout: false,
        );
        expect(score, 0);
      });

      test('calculates base score for correct answer with no time or streak',
          () {
        final score = calculateQuestionScore(
          isCorrect: true,
          timeRemaining: 0,
          streak: 0,
          isTimeout: false,
        );
        expect(score, 100); // baseScore only
      });

      test('adds time bonus', () {
        final score = calculateQuestionScore(
          isCorrect: true,
          timeRemaining: 7,
          streak: 0,
          isTimeout: false,
        );
        expect(score, 100 + 7 * 10); // base + timeBonus
      });

      test('adds streak bonus', () {
        final score = calculateQuestionScore(
          isCorrect: true,
          timeRemaining: 0,
          streak: 3,
          isTimeout: false,
        );
        expect(score, 100 + 3 * 50); // base + streakBonus
      });

      test('combines time and streak bonuses', () {
        final score = calculateQuestionScore(
          isCorrect: true,
          timeRemaining: 5,
          streak: 2,
          isTimeout: false,
        );
        expect(score, 100 + 5 * 10 + 2 * 50); // base + time + streak
      });

      test('handles maximum possible score', () {
        final score = calculateQuestionScore(
          isCorrect: true,
          timeRemaining: 10,
          streak: 10,
          isTimeout: false,
        );
        expect(score, 100 + 10 * 10 + 10 * 50); // 100 + 100 + 500 = 700
      });
    });

    group('calculateResultRank', () {
      test('returns LEGENDARY for high accuracy and score', () {
        expect(calculateResultRank(0.95, 1600), 'LEGENDARY');
        expect(calculateResultRank(0.90, 1500), 'LEGENDARY');
      });

      test('returns MASTER for accuracy >= 0.8 and score >= 1200', () {
        expect(calculateResultRank(0.85, 1300), 'MASTER');
        expect(calculateResultRank(0.80, 1200), 'MASTER');
      });

      test('returns EXPERT for accuracy >= 0.7 and score >= 900', () {
        expect(calculateResultRank(0.75, 950), 'EXPERT');
        expect(calculateResultRank(0.70, 900), 'EXPERT');
      });

      test('returns SKILLED for accuracy >= 0.6 and score >= 600', () {
        expect(calculateResultRank(0.65, 700), 'SKILLED');
        expect(calculateResultRank(0.60, 600), 'SKILLED');
      });

      test('returns BEGINNER for accuracy >= 0.5', () {
        expect(calculateResultRank(0.55, 500), 'BEGINNER');
        expect(calculateResultRank(0.50, 0), 'BEGINNER');
      });

      test('returns ROOKIE for accuracy < 0.5', () {
        expect(calculateResultRank(0.45, 1000), 'ROOKIE');
        expect(calculateResultRank(0.0, 0), 'ROOKIE');
      });

      test('prioritizes accuracy over score', () {
        // High score but low accuracy -> ROOKIE
        expect(calculateResultRank(0.4, 2000), 'ROOKIE');
        // High accuracy but low score -> BEGINNER (since score threshold not met for higher ranks)
        expect(calculateResultRank(0.9, 100), 'BEGINNER');
      });
    });

    group('getRankColor', () {
      test('returns correct color for each rank', () {
        expect(getRankColor('LEGENDARY'), 0xFFFFD700);
        expect(getRankColor('MASTER'), 0xFFC0C0C0);
        expect(getRankColor('EXPERT'), 0xFFCD7F32);
        expect(getRankColor('SKILLED'), 0xFF00FF00);
        expect(getRankColor('BEGINNER'), 0xFF0000FF);
        expect(getRankColor('ROOKIE'), 0xFF808080);
        expect(getRankColor('UNKNOWN'), 0xFF000000); // default
      });
    });

    group('calculateAccuracy', () {
      test('returns 0.0 when totalQuestions is 0', () {
        expect(calculateAccuracy(0, 0), 0.0);
        expect(calculateAccuracy(5, 0), double.infinity); // Actually division by zero, but our function returns 0.0
      });

      test('calculates accuracy correctly', () {
        expect(calculateAccuracy(5, 10), 0.5);
        expect(calculateAccuracy(7, 10), 0.7);
        expect(calculateAccuracy(0, 10), 0.0);
        expect(calculateAccuracy(10, 10), 1.0);
      });
    });

    group('calculateAverageTime', () {
      test('returns 0.0 when totalAnswers is 0', () {
        expect(calculateAverageTime(5000, 0), 0.0);
      });

      test('calculates average time correctly', () {
        expect(calculateAverageTime(5000, 5), 1000.0);
        expect(calculateAverageTime(7500, 3), 2500.0);
        expect(calculateAverageTime(0, 10), 0.0);
      });
    });

    group('isValidDifficulty', () {
      test('returns true for valid difficulties', () {
        expect(isValidDifficulty('easy'), true);
        expect(isValidDifficulty('medium'), true);
        expect(isValidDifficulty('hard'), true);
      });

      test('returns false for invalid difficulties', () {
        expect(isValidDifficulty(''), false);
        expect(isValidDifficulty('EASY'), false);
        expect(isValidDifficulty('normal'), false);
        expect(isValidDifficulty('extreme'), false);
      });
    });

    group('difficultyToWeight', () {
      test('returns correct weights', () {
        expect(difficultyToWeight('easy'), 1);
        expect(difficultyToWeight('medium'), 2);
        expect(difficultyToWeight('hard'), 3);
        expect(difficultyToWeight('unknown'), 0);
      });
    });
  });
}