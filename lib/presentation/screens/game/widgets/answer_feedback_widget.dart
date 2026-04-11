import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/question.dart';

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
    final color = widget.isCorrect ? Colors.green : Colors.red;
    final icon = widget.isCorrect ? Icons.check_circle : Icons.cancel;
    final title = widget.isCorrect ? 'Correct!' : 'Wrong!';
    final message = widget.isCorrect
        ? '+${widget.score} points'
        : 'Correct answer: ${widget.correctAnswer}';

    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
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
                      color: color.withOpacity(0.2),
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
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
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
                        placeholder: (context, url) => const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(
                          height: 120,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

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
                              ? 'You answered correctly'
                              : 'You answered: ${widget.selectedAnswer}',
                          style: TextStyle(
                            color: Colors.white,
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
