import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../domain/entities/match.dart';

/// Widget que muestra una línea de tiempo de respuestas
/// Visualiza gráficamente dónde acertó o falló cada jugador
class AnswerTimeline extends StatelessWidget {
  final int totalQuestions;
  final List<Answer> playerAnswers;
  final List<Answer>? opponentAnswers;
  final String playerName;
  final String? opponentName;

  const AnswerTimeline({
    super.key,
    required this.totalQuestions,
    required this.playerAnswers,
    this.opponentAnswers,
    required this.playerName,
    this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Timeline
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Player icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.primary,
            size: 24,
          ),
        ),

        const SizedBox(width: 12),

        // Player name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${playerAnswers.length} respuestas',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // VS (if opponent)
        if (opponentAnswers != null && opponentName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Opponent icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.error,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Opponent name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponentName!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${opponentAnswers!.length} respuestas',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Correct
        _buildLegendItem(
          color: AppColors.primary,
          label: 'Correcta',
        ),
        const SizedBox(width: 12),
        // Incorrect
        _buildLegendItem(
          color: AppColors.error,
          label: 'Incorrecta',
        ),
        const SizedBox(width: 12),
        // Timeout
        _buildLegendItem(
          color: AppColors.tertiary,
          label: 'Tiempo',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: List.generate(
        totalQuestions,
        (index) => _buildQuestionRow(index),
      ),
    );
  }

  Widget _buildQuestionRow(int questionIndex) {
    // Find answers for this question index
    final playerAnswer = playerAnswers.cast<Answer?>().firstWhere(
      (a) => a?.questionIndex == questionIndex,
      orElse: () => null,
    );

    final opponentAnswer = opponentAnswers?.cast<Answer?>().firstWhere(
      (a) => a?.questionIndex == questionIndex,
      orElse: () => null,
    );

    // Determine status colors
    final playerColor = _getStatusColor(playerAnswer);
    final opponentColor = _getStatusColor(opponentAnswer);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Question number
          SizedBox(
            width: 50,
            child: Text(
              '#${questionIndex + 1}',
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Player answer
          Expanded(
            child: _buildAnswerDot(
              answer: playerAnswer,
              color: playerColor,
              label: playerName,
            ),
          ),

          // Divider (if opponent)
          if (opponentAnswers != null) ...[
            const SizedBox(width: 16),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.outlineVariant.withOpacity(0.3),
            ),
            const SizedBox(width: 16),
          ],

          // Opponent answer
          if (opponentAnswers != null)
            Expanded(
              child: _buildAnswerDot(
                answer: opponentAnswer,
                color: opponentColor,
                label: opponentName ?? '',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerDot({
    required Answer? answer,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: _getStatusIcon(answer),
            ),
          ),

          const SizedBox(width: 10),

          // Answer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answer != null) ...[
                  Text(
                    _getStatusLabel(answer),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (answer.selectedAnswer.isNotEmpty && answer.selectedAnswer.length < 20)
                    Text(
                      answer.selectedAnswer,
                      style: GoogleFonts.workSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ] else
                  Text(
                    'No respondida',
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Answer? answer) {
    if (answer == null) {
      return AppColors.tertiary; // Gray for not answered
    }

    if (answer.timeMs == 0) {
      // Assuming timeMs == 0 means timeout (or check isTimeout flag)
      return AppColors.tertiary;
    }

    return answer.isCorrect ? AppColors.primary : AppColors.error;
  }

  String _getStatusLabel(Answer answer) {
    if (answer.timeMs == 0) {
      return '⏱ Tiempo';
    }

    return answer.isCorrect ? '✓ Correcta' : '✗ Incorrecta';
  }

  Widget _getStatusIcon(Answer? answer) {
    if (answer == null) {
      return Icon(
        Icons.help_outline,
        color: AppColors.onPrimaryContainer,
        size: 14,
      );
    }

    if (answer.timeMs == 0) {
      return Icon(
        Icons.timer,
        color: AppColors.onPrimaryContainer,
        size: 14,
      );
    }

    return Icon(
      answer.isCorrect ? Icons.check : Icons.close,
      color: AppColors.onPrimaryContainer,
      size: 14,
    );
  }
}
