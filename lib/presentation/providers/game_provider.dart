import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/question_repository.dart';

part 'game_provider.freezed.dart';
part 'game_provider.g.dart';

/// Question repository provider
@riverpod
QuestionRepository questionRepository(QuestionRepositoryRef ref) {
  throw UnimplementedError('QuestionRepository not implemented yet');
}

/// Game state
@freezed
class GameState with _$GameState {
  const factory GameState.initial() = _Initial;
  const factory GameState.loading() = _Loading;
  const factory GameState.playing({
    required List<Question> questions,
    required int currentQuestionIndex,
    required int timeRemaining,
    required int score,
    required List<Answer> userAnswers,
    required int correctAnswers,
    required int streak,
  }) = _Playing;
  const factory GameState.answered({
    required bool isCorrect,
    required String correctAnswer,
    required String selectedAnswer,
    required int score,
  }) = _Answered;
  const factory GameState.finished({
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required List<Answer> userAnswers,
    required double averageTime,
  }) = _Finished;
  const factory GameState.error({
    required String message,
  }) = _Error;
}

/// Game provider
@riverpod
class GameNotifier extends _$GameNotifier {
  Timer? _timer;
  static const int _questionTimeSeconds = 10;
  static const int _questionsPerRound = 10;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const GameState.initial();
  }

  /// Start a new game
  Future<void> startGame({
    required Difficulty difficulty,
  }) async {
    state = const GameState.loading();

    try {
      final questionsResult = await ref
          .read(questionRepositoryProvider)
          .getRandomQuestions(
            count: _questionsPerRound,
            maxDifficulty: difficulty,
          );

      questionsResult.fold(
        (failure) {
          state = GameState.error(message: failure.message);
        },
        (questions) {
          if (questions.isEmpty) {
            state = const GameState.error(message: 'No questions available');
            return;
          }

          state = GameState.playing(
            questions: questions,
            currentQuestionIndex: 0,
            timeRemaining: _questionTimeSeconds,
            score: 0,
            userAnswers: [],
            correctAnswers: 0,
            streak: 0,
          );

          _startTimer();
        },
      );
    } catch (e) {
      state = GameState.error(message: 'Failed to start game: $e');
    }
  }

  /// Start timer for current question
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final currentState = state;
        if (currentState is! _Playing) {
          timer.cancel();
          return;
        }

        if (currentState.timeRemaining <= 1) {
          timer.cancel();
          submitAnswer(
            selectedAnswer: '',
            isTimeout: true,
          );
        } else {
          state = currentState.copyWith(
            timeRemaining: currentState.timeRemaining - 1,
          );
        }
      },
    );
  }

  /// Submit answer for current question
  void submitAnswer({
    required String selectedAnswer,
    required bool isTimeout,
  }) {
    final currentState = state;
    if (currentState is! _Playing) return;

    _timer?.cancel();

    final question = currentState.questions[currentState.currentQuestionIndex];
    final isCorrect = !isTimeout && question.isCorrect(selectedAnswer);

    // Calculate score based on time and streak
    final timeBonus = currentState.timeRemaining * 10;
    final streakBonus = currentState.streak * 50;
    final baseScore = isCorrect ? 100 : 0;
    final questionScore = isTimeout ? 0 : (baseScore + timeBonus + streakBonus);

    // Create answer record
    final answer = Answer(
      questionIndex: currentState.currentQuestionIndex,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeMs: (_questionTimeSeconds - currentState.timeRemaining) * 1000,
      answeredAt: DateTime.now(),
    );

    // Update user answers list
    final updatedAnswers = [...currentState.userAnswers, answer];

    // Calculate new state
    final newScore = currentState.score + questionScore;
    final newCorrectAnswers =
        isCorrect ? currentState.correctAnswers + 1 : currentState.correctAnswers;
    final newStreak = isCorrect ? currentState.streak + 1 : 0;

    if (isTimeout) {
      state = GameState.answered(
        isCorrect: false,
        correctAnswer: question.correctAnswer,
        selectedAnswer: "Time's up!",
        score: newScore,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        nextQuestion(
          score: newScore,
          userAnswers: updatedAnswers,
          correctAnswers: newCorrectAnswers,
          streak: newStreak,
        );
      });
    } else {
      state = GameState.answered(
        isCorrect: isCorrect,
        correctAnswer: question.correctAnswer,
        selectedAnswer: selectedAnswer,
        score: newScore,
      );

      Future.delayed(Duration(milliseconds: isCorrect ? 1000 : 2000), () {
        nextQuestion(
          score: newScore,
          userAnswers: updatedAnswers,
          correctAnswers: newCorrectAnswers,
          streak: newStreak,
        );
      });
    }
  }

  /// Move to next question or finish game
  void nextQuestion({
    required int score,
    required List<Answer> userAnswers,
    required int correctAnswers,
    required int streak,
  }) {
    final currentState = state;
    if (currentState is! _Playing) return;

    final nextIndex = currentState.currentQuestionIndex + 1;

    if (nextIndex >= currentState.questions.length) {
      finishGame(
        score: score,
        userAnswers: userAnswers,
        correctAnswers: correctAnswers,
      );
    } else {
      state = currentState.copyWith(
        currentQuestionIndex: nextIndex,
        timeRemaining: _questionTimeSeconds,
        score: score,
        userAnswers: userAnswers,
        correctAnswers: correctAnswers,
        streak: streak,
      );
      _startTimer();
    }
  }

  /// Finish game and show results
  void finishGame({
    required int score,
    required List<Answer> userAnswers,
    required int correctAnswers,
  }) {
    _timer?.cancel();

    final totalTimeMs = userAnswers.fold<int>(
      0,
      (sum, answer) => sum + answer.timeMs,
    );
    final averageTime =
        userAnswers.isEmpty ? 0.0 : totalTimeMs / userAnswers.length;

    state = GameState.finished(
      score: score,
      totalQuestions: _questionsPerRound,
      correctAnswers: correctAnswers,
      userAnswers: userAnswers,
      averageTime: averageTime,
    );
  }

  /// Cancel game
  void cancelGame() {
    _timer?.cancel();
    state = const GameState.initial();
  }

  /// Skip to next question (for testing/debug)
  void skipQuestion() {
    final currentState = state;
    if (currentState is! _Playing) return;

    submitAnswer(
      selectedAnswer: '',
      isTimeout: true,
    );
  }
}

/// Current question provider
@riverpod
Question? currentQuestion(CurrentQuestionRef ref) {
  final gameState = ref.watch(gameNotifierProvider);
  return gameState.maybeWhen(
    playing: (questions, currentQuestionIndex, timeRemaining, score, userAnswers, correctAnswers, streak) {
      if (currentQuestionIndex < questions.length) {
        return questions[currentQuestionIndex];
      }
      return null;
    },
    orElse: () => null,
  );
}

/// Progress percentage provider
@riverpod
double progressPercentage(ProgressPercentageRef ref) {
  final gameState = ref.watch(gameNotifierProvider);
  return gameState.maybeWhen(
    playing: (questions, currentQuestionIndex, timeRemaining, score, userAnswers, correctAnswers, streak) {
      if (questions.isEmpty) return 0.0;
      return (currentQuestionIndex + 1) / questions.length;
    },
    orElse: () => 0.0,
  );
}

/// Timer progress provider (0.0 to 1.0)
@riverpod
double timerProgress(TimerProgressRef ref) {
  final gameState = ref.watch(gameNotifierProvider);
  return gameState.maybeWhen(
    playing: (questions, currentQuestionIndex, timeRemaining, score, userAnswers, correctAnswers, streak) {
      return timeRemaining / 10.0;
    },
    orElse: () => 0.0,
  );
}