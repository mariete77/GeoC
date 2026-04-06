import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import 'package:geoquiz_battle/helpers/mocks/mock_question_repository.dart';
import 'package:geoquiz_battle/presentation/providers/game_provider.dart';

void main() {
  group('Game Provider', () {
    late ProviderContainer container;
    late MockQuestionRepository mockRepo;

    setUp(() {
      mockRepo = MockQuestionRepository(
        initialQuestions: QuestionFactory.createSampleQuestions(count: 15),
      );
      container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('GameState transitions', () {
      test('starts in initial state', () {
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Initial>());
      });

      test('transitions to loading when starting game', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Loading>());
      });

      test('transitions to playing after questions are loaded', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        
        // Wait a bit for async operation
        await Future.delayed(const Duration(milliseconds: 100));
        
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Playing>());
      });

      test('transitions to answered after submitting answer', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        notifier.submitAnswer(
          selectedAnswer: 'Spain',
          isTimeout: false,
        );
        
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Answered>());
      });

      test('transitions to finished after all questions', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        // Create only 2 questions for faster test
        mockRepo.clear();
        mockRepo.addQuestion(QuestionFactory.createSample(id: 'q1', correctAnswer: 'Spain'));
        mockRepo.addQuestion(QuestionFactory.createSample(id: 'q2', correctAnswer: 'France'));
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Answer first question
        notifier.submitAnswer(
          selectedAnswer: 'Spain',
          isTimeout: false,
        );
        
        // Wait for auto-transition
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Answer second question
        notifier.submitAnswer(
          selectedAnswer: 'France',
          isTimeout: false,
        );
        
        // Wait for finish
        await Future.delayed(const Duration(milliseconds: 1500));
        
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Finished>());
      });
    });

    group('Score calculation', () {
      test('calculates correct score for perfect answer with time bonus', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Answer quickly (should have time bonus)
        final beforeState = container.read(gameNotifierProvider) as _Playing;
        notifier.submitAnswer(
          selectedAnswer: 'Spain', // Assuming this is correct
          isTimeout: false,
        );
        
        final afterState = container.read(gameNotifierProvider) as _Answered;
        
        // Score should be > 100 (base + time bonus)
        expect(afterState.score, greaterThan(100));
        expect(afterState.score, lessThanOrEqualTo(100 + 10 * 10 + 0)); // Max without streak
      });

      test('calculates zero score for wrong answer', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Answer wrong
        final beforeState = container.read(gameNotifierProvider) as _Playing;
        notifier.submitAnswer(
          selectedAnswer: 'WrongAnswer',
          isTimeout: false,
        );
        
        final afterState = container.read(gameNotifierProvider) as _Answered;
        expect(afterState.score, equals(beforeState.score)); // No change
      });

      test('calculates zero score for timeout', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Timeout
        final beforeState = container.read(gameNotifierProvider) as _Playing;
        notifier.submitAnswer(
          selectedAnswer: '',
          isTimeout: true,
        );
        
        final afterState = container.read(gameNotifierProvider) as _Answered;
        expect(afterState.score, equals(beforeState.score)); // No change
      });

      test('calculates streak bonus', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        // Create 3 questions with the same correct answer
        mockRepo.clear();
        mockRepo.addQuestion(QuestionFactory.createSample(id: 'q1', correctAnswer: 'Spain'));
        mockRepo.addQuestion(QuestionFactory.createSample(id: 'q2', correctAnswer: 'Spain'));
        mockRepo.addQuestion(QuestionFactory.createSample(id: 'q3', correctAnswer: 'Spain'));
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Answer first question (streak = 0 -> 1)
        notifier.submitAnswer(selectedAnswer: 'Spain', isTimeout: false);
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Answer second question (streak = 1 -> 2, should have bonus)
        final state2 = container.read(gameNotifierProvider) as _Playing;
        notifier.submitAnswer(selectedAnswer: 'Spain', isTimeout: false);
        
        final afterState2 = container.read(gameNotifierProvider) as _Answered;
        
        // Should have streak bonus (50 points)
        expect(afterState2.score - state2.score, greaterThan(100)); // Base + streak bonus
      });
    });

    group('Timer functionality', () {
      test('decrements timer each second', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final initialState = container.read(gameNotifierProvider) as _Playing;
        final initialTime = initialState.timeRemaining;
        
        // Wait 1 second
        await Future.delayed(const Duration(seconds: 1));
        
        final afterState = container.read(gameNotifierProvider) as _Playing;
        expect(afterState.timeRemaining, equals(initialTime - 1));
      });

      test('resets timer when moving to next question', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Wait a bit
        await Future.delayed(const Duration(seconds: 2));
        
        final state1 = container.read(gameNotifierProvider) as _Playing;
        final timeAfterWait = state1.timeRemaining;
        
        // Answer and move to next question
        notifier.submitAnswer(selectedAnswer: 'Spain', isTimeout: false);
        await Future.delayed(const Duration(milliseconds: 1500));
        
        final state2 = container.read(gameNotifierProvider) as _Playing;
        
        // Timer should be reset to 10 seconds
        expect(state2.timeRemaining, equals(10));
        expect(state2.timeRemaining, greaterThan(timeAfterWait));
      });

      test('triggers timeout when timer reaches 0', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Wait for timeout (10+ seconds)
        await Future.delayed(const Duration(seconds: 11));
        
        // State should be in answered state due to timeout
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Answered>());
      });
    });

    group('Game cancellation', () {
      test('resets to initial state when cancelled', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(container.read(gameNotifierProvider), isA<_Playing>());
        
        notifier.cancelGame();
        
        expect(container.read(gameNotifierProvider), isA<_Initial>());
      });

      test('cancels timer when game is cancelled', () async {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        notifier.cancelGame();
        
        // Timer should be cancelled and not decrement further
        await Future.delayed(const Duration(seconds: 2));
        
        expect(container.read(gameNotifierProvider), isA<_Initial>());
      });
    });

    group('Error handling', () {
      test('handles error when no questions are available', () async {
        mockRepo.clear(); // Remove all questions
        
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final state = container.read(gameNotifierProvider);
        expect(state, isA<_Error>());
      });
    });
  });

  group('Provider helpers', () {
    test('currentQuestionProvider returns current question', () async {
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(
            MockQuestionRepository(
              initialQuestions: QuestionFactory.createSampleQuestions(count: 10),
            ),
          ),
        ],
      );
      
      try {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final currentQuestion = container.read(currentQuestionProvider);
        expect(currentQuestion, isNotNull);
        expect(currentQuestion, isA<Question>());
      } finally {
        container.dispose();
      }
    });

    test('progressPercentageProvider calculates correctly', () async {
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(
            MockQuestionRepository(
              initialQuestions: QuestionFactory.createSampleQuestions(count: 10),
            ),
          ),
        ],
      );
      
      try {
        final notifier = container.read(gameNotifierProvider.notifier);
        
        await notifier.startGame(difficulty: Difficulty.medium);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final progress = container.read(progressPercentageProvider);
        expect(progress, greaterThan(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      } finally {
        container.dispose();
      }
    });
  });
}