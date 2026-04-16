import 'package:flutter/material.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';

/// Widget for typing answers in type-answer game mode
class TypeAnswerWidget extends StatefulWidget {
  final Question question;
  final int timeRemaining;
  final Function(String answer) onAnswerSubmitted;

  const TypeAnswerWidget({
    super.key,
    required this.question,
    required this.timeRemaining,
    required this.onAnswerSubmitted,
  });

  @override
  State<TypeAnswerWidget> createState() => _TypeAnswerWidgetState();
}

class _TypeAnswerWidgetState extends State<TypeAnswerWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Listen to text changes to update button state
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_submitted) return;
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _submitted = true);
    _focusNode.unfocus();
    widget.onAnswerSubmitted(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hint text based on question type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.keyboard, color: Colors.orange.withOpacity(0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                _getHintText(),
                style: TextStyle(
                  color: Colors.orange.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Text input
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _submitted
                  ? Colors.grey
                  : Colors.orange.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            enabled: !_submitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitAnswer(),
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta...',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              suffixIcon: !_submitted
                  ? IconButton(
                      icon: const Icon(Icons.send, color: Colors.orange),
                      onPressed: _submitAnswer,
                    )
                  : const Icon(Icons.check, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Submit button
        if (!_submitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _textController.text.trim().isEmpty ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  String _getHintText() {
    switch (widget.question.type) {
      case QuestionType.capital:
        return 'Escribe el nombre de la capital';
      case QuestionType.flag:
        return 'Escribe el nombre del país';
      case QuestionType.silhouette:
        return 'Escribe el nombre del país';
      case QuestionType.population:
        return 'Escribe la población aproximada';
      case QuestionType.river:
        return 'Escribe el nombre del río';
      case QuestionType.cityPhoto:
        return 'Escribe el nombre de la ciudad';
      case QuestionType.area:
        return 'Escribe la superficie aproximada';
      default:
        return 'Escribe tu respuesta';
    }
  }
}
