import 'package:flutter_test/flutter_test.dart';
import 'package:geoquiz_battle/presentation/providers/multiplayer_provider.dart';
import 'package:geoquiz_battle/domain/entities/match.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';

void main() {
  group('Multiplayer Performance Bonus Tests', () {
    test('calculatePerformanceScore applies bonus for fast correct answers', () {
      final state = MultiplayerState(
        playerAnswers: [
          Answer(questionIndex: 0, selectedAnswer: 'A', isCorrect: true, timeMs: 1000, answeredAt: DateTime.now()), // <2s: bonus 0.5
          Answer(questionIndex: 1, selectedAnswer: 'B', isCorrect: true, timeMs: 4000, answeredAt: DateTime.now()), // <5s: bonus 0.2
          Answer(questionIndex: 2, selectedAnswer: 'C', isCorrect: true, timeMs: 8000, answeredAt: DateTime.now()), // >5s: no bonus
        ],
      );

      // Expected: 3 correct answers (3.0) + 0.5 (fast) + 0.2 (medium) = 3.7
      expect(state.calculatePerformanceScore(), closeTo(3.7, 0.01));
    });

    test('calculatePerformanceScore does not apply bonus for wrong answers', () {
      final state = MultiplayerState(
        playerAnswers: [
          Answer(questionIndex: 0, selectedAnswer: 'A', isCorrect: false, timeMs: 500, answeredAt: DateTime.now()), // Correct is false
        ],
      );

      expect(state.calculatePerformanceScore(), 0.0);
    });

    test('calculatePerformanceScore handles mixed results', () {
      final state = MultiplayerState(
        playerAnswers: [
          Answer(questionIndex: 0, selectedAnswer: 'A', isCorrect: true, timeMs: 1500, answeredAt: DateTime.now()), // 1.0 + 0.5
          Answer(questionIndex: 1, selectedAnswer: 'B', isCorrect: false, timeMs: 1000, answeredAt: DateTime.now()), // 0.0
        ],
      );

      expect(state.calculatePerformanceScore(), closeTo(1.5, 0.01));
    });
  });
}
