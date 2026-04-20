import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import '../../../../core/theme/app_colors.dart';

class AnswerOptionsWidget extends StatelessWidget {
  final Question question;
  final Function(String) onAnswerSelected;

  const AnswerOptionsWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < options.length - 1 ? 16 : 0),
          child: _AnswerOptionButton(
            option: option,
            index: index,
            onPressed: () => onAnswerSelected(option),
          ),
        );
      }).toList(),
    );
  }
}

class _AnswerOptionButton extends StatefulWidget {
  final String option;
  final int index;
  final VoidCallback onPressed;

  const _AnswerOptionButton({
    required this.option,
    required this.index,
    required this.onPressed,
  });

  @override
  State<_AnswerOptionButton> createState() => _AnswerOptionButtonState();
}

class _AnswerOptionButtonState extends State<_AnswerOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.surfaceDim
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1C1B).withOpacity(0.02),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Letter circle — clean, small, "surface" bg
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ['A', 'B', 'C', 'D'].elementAt(widget.index),
                    style: GoogleFonts.plusJakartaSans(
                      color: _isPressed
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Answer text — Work Sans, editorial body voice
              Expanded(
                child: Text(
                  widget.option,
                  style: GoogleFonts.workSans(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}