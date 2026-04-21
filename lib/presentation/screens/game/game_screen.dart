import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/question.dart';
import '../../providers/game_provider.dart';
import 'widgets/timer_widget.dart';
import 'widgets/question_card.dart';
import 'widgets/answer_options_widget.dart';
import 'widgets/answer_feedback_widget.dart';
import 'widgets/game_result_widget.dart';
import 'widgets/type_answer_widget.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/theme/app_colors.dart';

class GameScreen extends ConsumerWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final currentQuestion = ref.watch(currentQuestionProvider);
    final progress = ref.watch(progressPercentageProvider);
    final timerProgress = ref.watch(timerProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => _showExitDialog(context, ref),
        ),
        actions: [
          // Score pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  gameState.maybeWhen(
                    playing: (_, __, ___, score, _____, ______, _______) => '$score',
                    answered: (_, __, ___, score) => '$score',
                    finished: (score, ___, _____, _______, ______) => '$score',
                    orElse: () => '0',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
            _buildPlaying(context, ref, currentQuestion, currentQuestionIndex, progress, timerProgress, score, correctAnswers),
        answered: (isCorrect, correctAnswer, selectedAnswer, score) =>
            _buildAnswered(context, ref, isCorrect, correctAnswer, selectedAnswer, score, currentQuestion),
        finished: (score, totalQuestions, correctAnswers, userAnswers, averageTime) =>
            _buildFinished(context, ref, score, totalQuestions, correctAnswers, userAnswers, averageTime),
        error: (message) => _buildError(context, message, ref),
      ),
    );
  }

  Widget _buildInitial(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_circle_outline, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Text(
              'Ready to Play?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Difficulty: ${difficulty.name.toUpperCase()}',
              style: GoogleFonts.workSans(
                fontSize: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: () => ref.read(gameNotifierProvider.notifier).startGame(difficulty: difficulty),
                    child: Center(
                      child: Text(
                        'START GAME',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Loading questions...',
            style: GoogleFonts.workSans(fontSize: 18, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context, WidgetRef ref, dynamic currentQuestion,
    int currentQuestionIndex, double progress, double timerProgress,
    int score, int correctAnswers,
  ) {
    if (currentQuestion == null) return _buildLoading();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Bar & Progress (Partida mockup) ────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUESTION ${currentQuestionIndex + 1}/10',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.name == 'easy' ? 'World Tour' : difficulty.name == 'medium' ? 'Deep Dive' : 'Expert',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SCORE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Question Area with Overhanging Timer ──────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative accent blur
              Positioned(
                top: -40,
                left: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryContainer.withOpacity(0.20),
                  ),
                ),
              ),
              // Question card
              QuestionCard(question: currentQuestion),
              // Overhanging timer (top-right, overlapping border)
              Positioned(
                top: -24,
                right: -12,
                child: TimerWidget(progress: timerProgress),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Answer Options ────────────────────────────
          if (currentQuestion.options.isEmpty)
            TypeAnswerWidget(
              question: currentQuestion,
              timeRemaining: ref.watch(timerProgressProvider) > 0
                  ? (ref.watch(timerProgressProvider) * GameConstants.secondsPerTypeQuestion).round()
                  : 0,
              onAnswerSubmitted: (answer) {
                ref.read(gameNotifierProvider.notifier).submitTypedAnswer(typedAnswer: answer);
              },
            )
          else
            AnswerOptionsWidget(
              question: currentQuestion,
              onAnswerSelected: (answer) {
                ref.read(gameNotifierProvider.notifier).submitAnswer(selectedAnswer: answer, isTimeout: false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnswered(BuildContext context, WidgetRef ref, bool isCorrect,
    String correctAnswer, String selectedAnswer, int score, dynamic currentQuestion,
  ) {
    return AnswerFeedbackWidget(
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      selectedAnswer: selectedAnswer,
      score: score,
      question: currentQuestion,
      onNextQuestion: () => ref.read(gameNotifierProvider.notifier).nextQuestion(),
    );
  }

  Widget _buildFinished(BuildContext context, WidgetRef ref, int score,
    int totalQuestions, int correctAnswers, List<dynamic> userAnswers, double averageTime,
  ) {
    return GameResultWidget(
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      averageTime: averageTime,
      onPlayAgain: () => ref.read(gameNotifierProvider.notifier).startGame(difficulty: difficulty),
      onGoHome: () {
        context.go('/home');
        Future.microtask(() => ref.read(gameNotifierProvider.notifier).resetGame());
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.workSans(fontSize: 16, color: AppColors.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Exit Game?', style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
        content: Text('Your progress will be lost. Are you sure?', style: GoogleFonts.workSans(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(gameNotifierProvider.notifier).cancelGame();
              context.go('/home');
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}