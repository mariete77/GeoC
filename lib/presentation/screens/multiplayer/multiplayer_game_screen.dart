import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/multiplayer_provider.dart';
import '../game/widgets/timer_widget.dart';
import '../game/widgets/question_card.dart';
import '../game/widgets/answer_options_widget.dart';
import '../game/widgets/type_answer_widget.dart';
import '../game/widgets/game_result_widget.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Multiplayer game screen
class MultiplayerGameScreen extends ConsumerWidget {
  const MultiplayerGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiplayerProvider);
    final isFinished = state.status == MultiplayerStatus.finished;

    return Scaffold(
      backgroundColor: isFinished ? AppColors.background : const Color(0xFF1A1A2E),
      appBar: isFinished
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _showExitDialog(context, ref),
              ),
              actions: [
                _buildScoreBar(state),
              ],
            ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildScoreBar(MultiplayerState state) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player score
          Text(
            '${state.playerScore}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'VS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // Opponent score
          Text(
            '${state.opponentScore}',
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, MultiplayerState state) {
    switch (state.status) {
      case MultiplayerStatus.playing:
        return _buildPlaying(context, ref, state);
      case MultiplayerStatus.finished:
        return _buildFinished(context, ref, state);
      case MultiplayerStatus.error:
        return _buildError(context, state.errorMessage ?? 'Unknown error');
      default:
        return _buildLoading();
    }
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
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaying(BuildContext context, WidgetRef ref, MultiplayerState state) {
    final currentIndex = state.currentQuestionIndex;
    if (currentIndex >= state.questions.length) return _buildLoading();

    final question = state.questions[currentIndex];
    final totalQuestions = state.questions.length;
    final progress = (currentIndex + 1) / totalQuestions;

    // Calculate timer progress
    final maxTime = question.options.isEmpty
        ? GameConstants.secondsPerTypeQuestion
        : GameConstants.secondsPerQuestion;
    final timerProgress = state.timeRemaining / maxTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar with opponent indicator
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
                '${currentIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Opponent info bar
          _buildOpponentBar(state),
          const SizedBox(height: 16),

          // Timer
          TimerWidget(progress: timerProgress),
          const SizedBox(height: 30),

          // Question card
          QuestionCard(question: question),
          const SizedBox(height: 30),

          // Answer options
          if (question.options.isEmpty)
            TypeAnswerWidget(
              question: question,
              timeRemaining: state.timeRemaining,
              onAnswerSubmitted: (answer) {
                ref.read(multiplayerProvider.notifier).submitTypedAnswer(
                      typedAnswer: answer,
                    );
              },
            )
          else
            AnswerOptionsWidget(
              question: question,
              onAnswerSelected: (answer) {
                ref.read(multiplayerProvider.notifier).submitAnswer(
                      selectedAnswer: answer,
                      isTimeout: false,
                    );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOpponentBar(MultiplayerState state) {
    final isWinning = state.playerScore >= state.opponentScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Player side
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tú',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${state.playerScore}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Opponent side
          Expanded(
            child: Row(
              children: [
                Text(
                  '${state.opponentScore}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  state.opponentName ?? 'Opponent',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_outline, color: Colors.redAccent, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(BuildContext context, WidgetRef ref, MultiplayerState state) {
    final won = state.playerScore > state.opponentScore;
    final totalQuestions = state.questions.length;
    final avgTime = state.playerAnswers.isEmpty
        ? 0.0
        : state.playerAnswers
                .map((a) => a.timeMs / 1000.0)
                .reduce((a, b) => a + b) /
            state.playerAnswers.length;

    return GameResultWidget(
      score: state.playerScore,
      totalQuestions: totalQuestions,
      correctAnswers: state.correctAnswers,
      averageTime: avgTime,
      isVictory: won,
      opponentName: state.opponentName,
      eloChange: state.eloChange,
      onPlayAgain: () {
        ref.read(multiplayerProvider.notifier).reset();
        context.go('/home');
      },
      onGoHome: () {
        ref.read(multiplayerProvider.notifier).reset();
        context.go('/home');
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Volver'),
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
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('¿Salir?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Perderás tu progreso. ¿Estás seguro?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(multiplayerProvider.notifier).reset();
              context.go('/home');
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}