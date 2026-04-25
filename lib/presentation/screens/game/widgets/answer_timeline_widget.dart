import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/match.dart';

/// Widget que muestra una línea de tiempo de respuestas
/// Visualiza gráficamente dónde acertó o falló cada jugador
/// 
/// Design System: Modern Explorer's Journal
/// - No-Line Rule: Sin bordes de 1px, usar cambios de color de fondo
/// - Tonal Layering: Definir jerarquía con capas de surface
/// - Glassmorphism: backdrop-blur(20px) para elementos flotantes
/// - Asymmetric Layouts: Layouts asimétricos con offset
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Asymmetric layout
          _buildHeader(),
          const SizedBox(height: 32),

          // Timeline - Tonal layering
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player section - Left aligned
            Expanded(
              flex: 3,
              child: _buildPlayerHeader(
                name: playerName,
                answers: playerAnswers.length,
                isPrimary: true,
              ),
            ),

            // Negative space
            const SizedBox(width: 32),

            // Legend - Right aligned, offset vertically
            if (!isWide) ...[
              const Spacer(),
              _buildLegend(),
            ],

            // VS section - For multiplayer
            if (opponentAnswers != null && opponentName != null) ...[
              // VS indicator - Glassmorphism
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(width: 32),

              // Opponent section
              Expanded(
                flex: 3,
                child: _buildPlayerHeader(
                  name: opponentName!,
                  answers: opponentAnswers!.length,
                  isPrimary: false,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPlayerHeader({
    required String name,
    required int answers,
    required bool isPrimary,
  }) {
    final color = isPrimary ? AppColors.primary : AppColors.error;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player name - High contrast typography
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        
        // Answer count - Subtle body text
        Text(
          '$answers ${answers == 1 ? 'respuesta' : 'respuestas'}',
          style: GoogleFonts.workSans(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Color accent line - Tonal layering
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(
            color: AppColors.primary,
            label: 'Correcta',
          ),
          const SizedBox(width: 20),
          _buildLegendItem(
            color: AppColors.error,
            label: 'Incorrecta',
          ),
          const SizedBox(width: 20),
          _buildLegendItem(
            color: AppColors.tertiary,
            label: 'Tiempo',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status dot - No border, tonal
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
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
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number - Display typography, left aligned
          SizedBox(
            width: 56,
            child: Text(
              '#${questionIndex + 1}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Player answer - Tonal layering
          Expanded(
            child: _buildAnswerCard(
              answer: playerAnswer,
              color: playerColor,
              label: playerName,
              isPrimary: true,
            ),
          ),

          // Negative space instead of divider
          if (opponentAnswers != null) ...[
            const SizedBox(width: 24),
          ],

          // Opponent answer
          if (opponentAnswers != null)
            Expanded(
              child: _buildAnswerCard(
                answer: opponentAnswer,
                color: opponentColor,
                label: opponentName ?? '',
                isPrimary: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard({
    required Answer? answer,
    required Color color,
    required String label,
    required bool isPrimary,
  }) {
    final backgroundColor = color.withOpacity(0.08);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        // No border - Tonal layering instead
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              // Status indicator - Glassmorphism
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _getStatusIcon(answer, color),
                ),
              ),

              const SizedBox(width: 12),

              // Status label - Display typography
              Expanded(
                child: Text(
                  _getStatusLabel(answer),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          // Answer details - Body typography
          if (answer != null) ...[
            const SizedBox(height: 8),
            if (answer.selectedAnswer.isNotEmpty) ...[
              Text(
                answer.selectedAnswer,
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Time taken - Subtle
            if (answer.timeMs > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${(answer.timeMs / 1000).toStringAsFixed(1)}s',
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ] else
            // Not answered - Subtle, italic
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sin respuesta',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
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
      // Assuming timeMs == 0 means timeout
      return AppColors.tertiary;
    }

    return answer.isCorrect ? AppColors.primary : AppColors.error;
  }

  String _getStatusLabel(Answer? answer) {
    if (answer == null) {
      return '—';
    }

    if (answer.timeMs == 0) {
      return '⏱ Tiempo agotado';
    }

    return answer.isCorrect ? '✓ Correcta' : '✗ Incorrecta';
  }

  Widget _getStatusIcon(Answer? answer, Color color) {
    if (answer == null) {
      return Icon(
        Icons.circle_outlined,
        color: color,
        size: 16,
        weight: 3, // Thin weight
      );
    }

    if (answer.timeMs == 0) {
      return Icon(
        Icons.timer_outlined,
        color: color,
        size: 16,
        weight: 3, // Thin weight
      );
    }

    return Icon(
      answer.isCorrect ? Icons.check : Icons.close,
      color: color,
      size: 18,
      weight: 3, // Thin weight
    );
  }
}
