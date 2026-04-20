import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import '../../../../core/theme/app_colors.dart';

class AnswerFeedbackWidget extends StatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String selectedAnswer;
  final int score;
  final Question? question;

  const AnswerFeedbackWidget({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.score,
    this.question,
  });

  @override
  State<AnswerFeedbackWidget> createState() => _AnswerFeedbackWidgetState();
}

class _AnswerFeedbackWidgetState extends State<AnswerFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
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

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? AppColors.success : AppColors.error;
    final icon = widget.isCorrect ? Icons.check_circle : Icons.cancel;
    final title = widget.isCorrect ? '¡Correcto!' : '¡Incorrecto!';

    // Extract educational info from extraData
    final infoToShow = widget.question?.extraData?['infoToShow'] as String?;
    final hasInfo = infoToShow != null && infoToShow.isNotEmpty;

    final message = widget.isCorrect
        ? (hasInfo ? '${widget.correctAnswer} tiene $infoToShow' : '+${widget.score} puntos')
        : 'Respuesta correcta: ${widget.correctAnswer}';

    return Container(
      color: AppColors.background,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 80,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    style: GoogleFonts.workSans(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Show question image if available
                  if (widget.question?.imageUrl != null) ...[
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.question!.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => SizedBox(
                          height: 120,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Educational info card
                  if (hasInfo) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppColors.tertiary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.isCorrect
                                  ? '${widget.correctAnswer} tiene $infoToShow'
                                  : '${widget.correctAnswer} tiene $infoToShow',
                              style: GoogleFonts.workSans(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Selected answer indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isCorrect ? Icons.done : Icons.close,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isCorrect
                              ? (hasInfo ? '+${widget.score} puntos' : '¡Respuesta correcta!')
                              : 'Tu respuesta: ${widget.selectedAnswer}',
                          style: GoogleFonts.workSans(
                            color: AppColors.onSurface,
                            fontSize: 16,
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