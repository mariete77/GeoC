import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/question_repository.dart';
import '../../core/constants/game_constants.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/fuzzy_matcher.dart';

part 'game_provider.freezed.dart';
part 'game_provider.g.dart';

/// Question repository provider
@riverpod
QuestionRepository questionRepository(QuestionRepositoryRef ref) {
  return QuestionRepositoryImpl();
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
  Timer? _answeredTimer;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  // Pending state for manual "next question" flow
  int _pendingScore = 0;
  List<Answer> _pendingUserAnswers = [];
  int _pendingCorrectAnswers = 0;
  int _pendingStreak = 0;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _answeredTimer?.cancel();
    });
    return const GameState.initial();
  }

  /// Start a new game
  Future<void> startGame({
    required Difficulty difficulty,
  }) async {
    state = const GameState.loading();

    try {
      // Fetch all questions (no difficulty filter) to maximize pool and reduce repeats
      final questionsResult = await ref
          .read(questionRepositoryProvider)
          .getRandomQuestions(
            count: GameConstants.questionsPerMatch,
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

          // Convert some questions to type-answer mode (strip options)
          _questions = _convertToTypeAnswer(questions);
          _currentQuestionIndex = 0;

          // Auto-detect time based on first question type
          final secondsPerQuestion = _getTimeForQuestion(_questions.first);

          state = GameState.playing(
            questions: _questions,
            currentQuestionIndex: 0,
            timeRemaining: secondsPerQuestion,
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

  /// Get appropriate time limit based on question type
  int _getTimeForQuestion(Question question) {
    // Type-answer questions (no options) get more time
    if (question.options.isEmpty) {
      return GameConstants.secondsPerTypeQuestion;
    }
    return GameConstants.secondsPerQuestion;
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

  /// Submit a typed answer for type-answer mode
  void submitTypedAnswer({
    required String typedAnswer,
  }) {
    final currentState = state;
    if (currentState is! _Playing) return;

    _timer?.cancel();

    final question = currentState.questions[currentState.currentQuestionIndex];
    final similarity = answerSimilarity(typedAnswer, question.correctAnswer);
    final isCorrect = similarity >= 0.85; // 85%+ counts as correct

    final maxTime = _getTimeForQuestion(question);

    final questionScore = calculateTypedScore(
      similarity: similarity,
      timeRemaining: currentState.timeRemaining,
      maxTime: maxTime,
      streak: currentState.streak,
    );

    final answer = Answer(
      questionIndex: currentState.currentQuestionIndex,
      selectedAnswer: typedAnswer,
      isCorrect: isCorrect,
      timeMs: (maxTime - currentState.timeRemaining) * 1000,
      answeredAt: DateTime.now(),
    );

    final updatedAnswers = [...currentState.userAnswers, answer];
    final newScore = currentState.score + questionScore;
    final newCorrectAnswers = isCorrect ? currentState.correctAnswers + 1 : currentState.correctAnswers;
    final newStreak = isCorrect ? currentState.streak + 1 : 0;

    _transitionToAnswered(
      isCorrect: isCorrect,
      isTimeout: false,
      question: question,
      selectedAnswer: typedAnswer,
      newScore: newScore,
      updatedAnswers: updatedAnswers,
      newCorrectAnswers: newCorrectAnswers,
      newStreak: newStreak,
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

    // Calculate score using score_calculator
    final questionScore = calculateQuestionScore(
      isCorrect: isCorrect,
      timeRemaining: currentState.timeRemaining,
      streak: currentState.streak,
      isTimeout: isTimeout,
    );

    // Create answer record - use appropriate time for this question type
    final maxTime = _getTimeForQuestion(question);
    final answer = Answer(
      questionIndex: currentState.currentQuestionIndex,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeMs: (maxTime - currentState.timeRemaining) * 1000,
      answeredAt: DateTime.now(),
    );

    // Update user answers list
    final updatedAnswers = [...currentState.userAnswers, answer];

    // Calculate new state
    final newScore = currentState.score + questionScore;
    final newCorrectAnswers =
        isCorrect ? currentState.correctAnswers + 1 : currentState.correctAnswers;
    final newStreak = isCorrect ? currentState.streak + 1 : 0;

    // Transition to answered state with appropriate delay
    _transitionToAnswered(
      isCorrect: isCorrect,
      isTimeout: isTimeout,
      question: question,
      selectedAnswer: selectedAnswer,
      newScore: newScore,
      updatedAnswers: updatedAnswers,
      newCorrectAnswers: newCorrectAnswers,
      newStreak: newStreak,
    );
  }

  /// Transition to answered state with appropriate delay
  void _transitionToAnswered({
    required bool isCorrect,
    required bool isTimeout,
    required Question question,
    required String selectedAnswer,
    required int newScore,
    required List<Answer> updatedAnswers,
    required int newCorrectAnswers,
    required int newStreak,
  }) {
    final displayAnswer = isTimeout ? "Time's up!" : selectedAnswer;

    // Store pending values for manual next-question flow
    _pendingScore = newScore;
    _pendingUserAnswers = updatedAnswers;
    _pendingCorrectAnswers = newCorrectAnswers;
    _pendingStreak = newStreak;

    state = GameState.answered(
      isCorrect: isCorrect,
      correctAnswer: question.correctAnswer,
      selectedAnswer: displayAnswer,
      score: newScore,
    );

    // Determine delay based on result
    final delayMs = isTimeout
        ? GameConstants.answeredDelayTimeoutMs
        : isCorrect
            ? GameConstants.answeredDelayCorrectMs
            : GameConstants.answeredDelayIncorrectMs;

    _answeredTimer?.cancel();
    _answeredTimer = Timer(Duration(milliseconds: delayMs), () {
      nextQuestion();
    });
  }

  /// Move to next question or finish game
  /// Can be called without args (uses stored pending values) for manual tap.
  void nextQuestion({
    int? score,
    List<Answer>? userAnswers,
    int? correctAnswers,
    int? streak,
  }) {
    _answeredTimer?.cancel();

    // Use provided values or fall back to stored pending values
    final s = score ?? _pendingScore;
    final ua = userAnswers ?? _pendingUserAnswers;
    final ca = correctAnswers ?? _pendingCorrectAnswers;
    final st = streak ?? _pendingStreak;

    // Use instance variables instead of state, since state is _Answered here
    final nextIndex = _currentQuestionIndex + 1;

    if (nextIndex >= _questions.length) {
      finishGame(
        score: s,
        userAnswers: ua,
        correctAnswers: ca,
      );
    } else {
      _currentQuestionIndex = nextIndex;

      // Auto-detect time based on next question type
      final nextQuestion = _questions[nextIndex];
      final secondsPerQuestion = _getTimeForQuestion(nextQuestion);

      state = GameState.playing(
        questions: _questions,
        currentQuestionIndex: nextIndex,
        timeRemaining: secondsPerQuestion,
        score: s,
        userAnswers: ua,
        correctAnswers: ca,
        streak: st,
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
    final averageTime = calculateAverageTime(totalTimeMs, userAnswers.length);

    state = GameState.finished(
      score: score,
      totalQuestions: GameConstants.questionsPerMatch,
      correctAnswers: correctAnswers,
      userAnswers: userAnswers,
      averageTime: averageTime,
    );
  }

  /// Cancel game
  void cancelGame() {
    _timer?.cancel();
    _answeredTimer?.cancel();
    state = const GameState.initial();
  }

  /// Reset game state (for navigating back home)
  void resetGame() {
    _timer?.cancel();
    _answeredTimer?.cancel();
    _questions = [];
    _currentQuestionIndex = 0;
    _pendingScore = 0;
    _pendingUserAnswers = [];
    _pendingCorrectAnswers = 0;
    _pendingStreak = 0;
    state = const GameState.initial();
  }

  /// Convert some questions to type-answer mode by stripping options
  /// Roughly 30% of questions become type-answer
  List<Question> _convertToTypeAnswer(List<Question> questions) {
    final random = Random();
    return questions.map((q) {
      // 30% chance to convert to type-answer
      if (random.nextDouble() < 0.3) {
        return Question(
          id: q.id,
          type: q.type,
          difficulty: q.difficulty,
          correctAnswer: q.correctAnswer,
          options: [], // Empty options = type-answer mode
          imageUrl: q.imageUrl,
          questionText: q.questionText,
          extraData: q.extraData,
        );
      }
      return q;
    }).toList();
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
      // Use the correct max time based on current question type
      final currentQuestion = currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;
      final maxTime = currentQuestion != null && currentQuestion.options.isEmpty
          ? GameConstants.secondsPerTypeQuestion
          : GameConstants.secondsPerQuestion;
      return timeRemaining / maxTime;
    },
    orElse: () => 0.0,
  );
}
