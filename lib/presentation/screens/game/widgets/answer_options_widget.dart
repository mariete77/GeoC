import 'package:flutter/material.dart';
import '../../../../data/models/question_model.dart';

class AnswerOptionsWidget extends StatelessWidget {
  final QuestionModel question;
  final Function(String) onAnswerSelected;

  const AnswerOptionsWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final shuffledOptions = _shuffleOptions(question.options);

    return Column(
      children: shuffledOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < shuffledOptions.length - 1 ? 12 : 0,
          ),
          child: _AnswerOptionButton(
            option: option,
            onPressed: () => onAnswerSelected(option),
          ),
        );
      }).toList(),
    );
  }

  List<String> _shuffleOptions(List<String> options) {
    final shuffled = List<String>.from(options);
    shuffled.shuffle();
    return shuffled;
  }
}

class _AnswerOptionButton extends StatefulWidget {
  final String option;
  final VoidCallback onPressed;

  const _AnswerOptionButton({
    required this.option,
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
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? Colors.orange.withOpacity(0.4)
                : const Color(0xFF3D3D5C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? Colors.orange
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    ['A', 'B', 'C', 'D'].elementAt(
                      question.options.indexOf(widget.option),
                    ),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.option,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
