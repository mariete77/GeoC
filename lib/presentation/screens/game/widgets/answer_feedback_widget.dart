import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/common/report_question_dialog.dart';

class AnswerFeedbackWidget extends StatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String selectedAnswer;
  final int score;
  final Question? question;
  final double? similarity;
  final VoidCallback? onNextQuestion;

  const AnswerFeedbackWidget({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.score,
    this.question,
    this.similarity,
    this.onNextQuestion,
  });

  @override
  State<AnswerFeedbackWidget> createState() => _AnswerFeedbackWidgetState();
}

class _AnswerFeedbackWidgetState extends State<AnswerFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _accuracyLabel(double similarity) {
    if (similarity >= 1.0) return '¡Perfecto!';
    if (similarity >= 0.85) return '¡Casi!';
    if (similarity >= 0.7) return 'Cerca';
    if (similarity >= 0.5) return 'Aprobable';
    return 'Incorrecto';
  }

  @override
  Widget build(BuildContext context) {
    final infoToShow = widget.question?.extraData?['infoToShow'] as String?;
    final hasInfo = infoToShow != null && infoToShow.isNotEmpty;

    final sim = widget.similarity;
    final hasPartial = sim != null && sim < 1.0 && sim >= 0.5;

    Color bannerColor;
    Color bannerFg;
    IconData icon;
    String title;

    if (sim != null && sim >= 1.0) {
      bannerColor = AppColors.primaryContainer;
      bannerFg = AppColors.onPrimaryContainer;
      icon = Icons.check_circle;
      title = '¡Perfecto!';
    } else if (sim != null && sim >= 0.85) {
      bannerColor = AppColors.secondaryContainer;
      bannerFg = AppColors.onSecondaryContainer;
      icon = Icons.check_circle_outline;
      title = '¡Casi!';
    } else if (sim != null && sim >= 0.7) {
      bannerColor = AppColors.tertiaryContainer;
      bannerFg = AppColors.onTertiaryContainer;
      icon = Icons.touch_app;
      title = 'Cerca';
    } else if (sim != null && sim >= 0.5) {
      bannerColor = AppColors.errorContainer.withValues(alpha: 0.6);
      bannerFg = AppColors.onErrorContainer;
      icon = Icons.pending_outlined;
      title = 'Aprobable';
    } else {
      bannerColor = widget.isCorrect
          ? AppColors.primaryContainer
          : AppColors.errorContainer;
      bannerFg = widget.isCorrect
          ? AppColors.onPrimaryContainer
          : AppColors.onErrorContainer;
      icon = widget.isCorrect ? Icons.check_circle : Icons.cancel;
      title = widget.isCorrect ? 'Correcto' : 'Incorrecto';
    }

    return Container(
      color: AppColors.onBackground.withOpacity(0.20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1C1B).withOpacity(0.06),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top Banner (primary-container for correct, error-container for incorrect)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icon
                        Icon(icon, size: 64, color: bannerFg),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: bannerFg,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Content Area
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Correct answer display
                        Text(
                          'La respuesta era:',
                          style: GoogleFonts.workSans(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.correctAnswer,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),

                        // Show image if available
                        if (widget.question?.imageUrl != null) ...[
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: widget.question!.imageUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => SizedBox(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => SizedBox(
                                height: 100,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Stats Bento Grid (2 columns)
                        Row(
                          children: [
                            // Points
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'PUNTOS',
                                      style: GoogleFonts.workSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${widget.score}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Educational info or streak
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: hasInfo
                                    ? Column(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            color: AppColors.tertiary,
                                            size: 18,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            infoToShow,
                                            style: GoogleFonts.workSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            hasPartial ? 'PRECISIÓN' : 'TU RESPUESTA',
                                            style: GoogleFonts.workSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurfaceVariant,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            hasPartial
                                                ? '${(sim! * 100).toStringAsFixed(0)}%'
                                                : (widget.isCorrect
                                                    ? '✓'
                                                    : (widget.selectedAnswer)),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: hasPartial
                                                  ? AppColors.tertiary
                                                  : (widget.isCorrect
                                                      ? AppColors.primary
                                                      : AppColors.error),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // ── Partial/wrong answer indicator
                        if ((!widget.isCorrect || hasPartial) && hasInfo) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Tu respuesta: ${widget.selectedAnswer}',
                                    style: GoogleFonts.workSans(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── Gradient "Siguiente Pregunta" Button (PreguntaCorrecta mockup)
                        const SizedBox(height: 24),

                        // ── Report button (small flag icon, right-aligned)
                        if (widget.question != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReportQuestionDialog(
                                    questionId: widget.question!.id,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.flag_outlined,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: Text(
                                'Reportar',
                                style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9999),
                              gradient: LinearGradient(
                                colors: hasPartial
                                    ? [AppColors.tertiaryContainer, AppColors.tertiary]
                                    : (widget.isCorrect
                                        ? [AppColors.primary, AppColors.primaryContainer]
                                        : [AppColors.error, AppColors.errorContainer]),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (hasPartial
                                          ? AppColors.tertiary
                                          : (widget.isCorrect
                                              ? AppColors.primary
                                              : AppColors.error))
                                      .withOpacity(0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9999),
                                onTap: widget.onNextQuestion,
                                child: Center(
                                  child: Text(
                                    'SIGUIENTE PREGUNTA',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onPrimary,
                                      letterSpacing: 1.5,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
