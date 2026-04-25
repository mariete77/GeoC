import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A sparkline chart widget for displaying ELO history.
class EloSparkline extends StatelessWidget {
  final List<int> eloValues;
  final int currentElo;
  final int eloDelta;

  const EloSparkline({
    super.key,
    required this.eloValues,
    required this.currentElo,
    required this.eloDelta,
  });

  @override
  Widget build(BuildContext context) {
    if (eloValues.length < 2) return const SizedBox.shrink();

    final isPositive = eloDelta >= 0;
    final color = isPositive ? const Color(0xFF4CAF50) : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 32,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: eloValues.map((e) => e.toDouble()).toList(),
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}$eloDelta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final normalizedRange = range == 0 ? 1.0 : range;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / normalizedRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path at bottom
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}