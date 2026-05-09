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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
        final hasOpponent = opponentAnswers != null && opponentName != null;
        
        if (!isWide && hasOpponent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerHeader(
                name: playerName,
                answers: playerAnswers.length,
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(width: 16),
                  _buildLegend(),
                ],
              ),
              const SizedBox(height: 16),
              _buildPlayerHeader(
                name: opponentName!,
                answers: opponentAnswers!.length,
                isPrimary: false,
              ),
            ],
          );
        }

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

            // VS section - For multiplayer
            if (hasOpponent) ...[
              const SizedBox(width: 16),
              // VS indicator - Glassmorphism
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 16),

              // Opponent section
              Expanded(
                flex: 3,
                child: _buildPlayerHeader(
                  name: opponentName!,
                  answers: opponentAnswers!.length,
                  isPrimary: false,
                ),
              ),
            ] else ...[
               const Spacer(),
               _buildLegend(),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal scrollable answer pills
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalQuestions,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _buildAnswerPill(index),
          ),
        ),

        // Opponent vs player side-by-side for multiplayer
        if (opponentAnswers != null && opponentName != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildScoreChip(playerName, playerAnswers)),
              const SizedBox(width: 12),
              Expanded(child: _buildScoreChip(opponentName!, opponentAnswers!)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScoreChip(String name, List<Answer> answers) {
    final correct = answers.where((a) => a.isCorrect).length;
    final total = answers.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$correct/$total',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerPill(int questionIndex) {
    final playerAnswer = playerAnswers.cast<Answer?>().firstWhere(
      (a) => a?.questionIndex == questionIndex,
      orElse: () => null,
    );

    final similarity = playerAnswer?.similarity;
    final hasPartial = similarity != null && similarity < 1.0 && similarity >= 0.5;
    final color = _getStatusColor(playerAnswer);
    final bgColor = hasPartial
        ? AppColors.tertiaryContainer.withValues(alpha: 0.2)
        : color.withOpacity(0.12);
    final icon = _getStatusIcon(playerAnswer, color);
    final label = _getStatusLabel(playerAnswer);

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question number
          Text(
            '#${questionIndex + 1}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          // Icon
          SizedBox(width: 22, height: 22, child: icon),
          const SizedBox(height: 4),
          // Accuracy or time
          if (hasPartial)
            Text(
              '${(similarity! * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.tertiary,
              ),
            )
          else if (playerAnswer != null && playerAnswer.timeMs > 0 && playerAnswer.timeMs.isFinite)
            Text(
              '${(playerAnswer.timeMs / 1000).toStringAsFixed(1)}s',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(Answer? answer) {
    if (answer == null) return AppColors.tertiary;
    if (answer.timeMs == 0) return AppColors.tertiary;
    final sim = answer.similarity;
    if (sim != null && sim >= 0.5 && sim < 0.85) return AppColors.tertiary;
    return answer.isCorrect ? AppColors.primary : AppColors.error;
  }

  String _getStatusLabel(Answer? answer) {
    if (answer == null || answer.timeMs == 0) return '—';
    final sim = answer.similarity;
    if (sim != null && sim >= 0.5 && sim < 0.85) return '~';
    return answer.isCorrect ? '✓' : '✗';
  }

  Widget _getStatusIcon(Answer? answer, Color color) {
    if (answer == null || answer.timeMs == 0) {
      return Icon(Icons.timer_outlined, color: color, size: 16);
    }
    final sim = answer.similarity;
    if (sim != null && sim >= 0.5 && sim < 0.85) {
      return Icon(Icons.touch_app, color: AppColors.tertiary, size: 20);
    }
    return Icon(
      answer.isCorrect ? Icons.check_circle : Icons.cancel,
      color: color,
      size: 22,
    );
  }
}
