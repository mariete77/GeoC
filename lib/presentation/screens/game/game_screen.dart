import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/question.dart';
import '../../providers/game_provider.dart';
import 'widgets/timer_widget.dart';
import 'widgets/question_card.dart';
import 'widgets/answer_options_widget.dart';
import 'widgets/answer_feedback_widget.dart';
import 'widgets/game_result_widget.dart';

class GameScreen extends ConsumerWidget {
  final Difficulty difficulty;

  const GameScreen({
    super.key,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final currentQuestion = ref.watch(currentQuestionProvider);
    final progress = ref.watch(progressPercentageProvider);
    final timerProgress = ref.watch(timerProgressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _showExitDialog(context, ref);
          },
        ),
        actions: [
          // Score display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  gameState.maybeWhen(
                    playing: (_, __, ___, score, _____, _______, ______) => '$score',
                    answered: (_, __, ___, score) => '$score',
                    finished: (score, ___, _____, _______, ______) => '$score',
                    orElse: () => '0',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: gameState.when(
        initial: () => _buildInitial(context, ref),
        loading: () => _buildLoading(),
        playing: (_, currentQuestionIndex, ___, score, _____, correctAnswers, ________) =>
            _buildPlaying(
          context,
          ref,
          currentQuestion,
          currentQuestionIndex,
          progress,
          timerProgress,
          score,
          correctAnswers,
        ),
        answered: (isCorrect, correctAnswer, selectedAnswer, score) =>
            _buildAnswered(
          context,
          ref,
          isCorrect,
          correctAnswer,
          selectedAnswer,
          score,
          currentQuestion,
        ),
        finished: (score, totalQuestions, correctAnswers, userAnswers, averageTime) =>
            _buildFinished(
          context,
          ref,
          score,
          totalQuestions,
          correctAnswers,
          userAnswers,
          averageTime,
        ),
        error: (message) => _buildError(context, message, ref),
      ),
    );
  }

  Widget _buildInitial(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Play?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Difficulty: ${difficulty.name.toUpperCase()}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(gameNotifierProvider.notifier).startGame(
                    difficulty: difficulty,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'START GAME',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading questions...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    dynamic currentQuestion,
    int currentQuestionIndex,
    double progress,
    double timerProgress,
    int score,
    int correctAnswers,
  ) {
    if (currentQuestion == null) {
      return _buildLoading();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${currentQuestionIndex + 1}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timer
          TimerWidget(progress: timerProgress),
          const SizedBox(height: 30),

          // Question card
          QuestionCard(question: currentQuestion),
          const SizedBox(height: 30),

          // Answer options
          AnswerOptionsWidget(
            question: currentQuestion,
            onAnswerSelected: (answer) {
              ref.read(gameNotifierProvider.notifier).submitAnswer(
                    selectedAnswer: answer,
                    isTimeout: false,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswered(
    BuildContext context,
    WidgetRef ref,
    bool isCorrect,
    String correctAnswer,
    String selectedAnswer,
    int score,
    dynamic currentQuestion,
  ) {
    return AnswerFeedbackWidget(
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      selectedAnswer: selectedAnswer,
      score: score,
      question: currentQuestion,
    );
  }

  Widget _buildFinished(
    BuildContext context,
    WidgetRef ref,
    int score,
    int totalQuestions,
    int correctAnswers,
    List<dynamic> userAnswers,
    double averageTime,
  ) {
    return GameResultWidget(
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      averageTime: averageTime,
      onPlayAgain: () {
        ref.read(gameNotifierProvider.notifier).startGame(
              difficulty: difficulty,
            );
      },
      onGoHome: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildError(BuildContext context, String message, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Exit Game?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will be lost. Are you sure?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameNotifierProvider.notifier).cancelGame();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
