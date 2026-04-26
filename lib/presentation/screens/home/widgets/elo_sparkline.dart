import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// A sparkline chart widget for displaying ELO history.
/// Shows a full-width graph with gradient fill and trend indicator.
/// When insufficient data, shows a placeholder flat line.
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
    final hasData = eloValues.length >= 2;
    final isPositive = eloDelta >= 0;
    final color = hasData
        ? (isPositive ? const Color(0xFF4CAF50) : AppColors.error)
        : AppColors.primary.withOpacity(0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sparkline graph (always visible)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: CustomPaint(
            painter: hasData
                ? _SparklinePainter(
                    values: eloValues.map((e) => e.toDouble()).toList(),
                    color: color,
                  )
                : _PlaceholderLinePainter(color: color),
          ),
        ),
        const SizedBox(height: 6),
        // Trend indicator row (only when has data)
        if (hasData)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Text(
            'Juega partidas para ver tu progreso',
            style: GoogleFonts.workSans(
              fontSize: 11,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}

/// Placeholder painter — subtle animated-looking flat line
class _PlaceholderLinePainter extends CustomPainter {
  final Color color;

  _PlaceholderLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw a gentle wave across the middle
    final path = Path();
    final midY = size.height * 0.5;
    path.moveTo(0, midY + 4);
    path.quadraticBezierTo(size.width * 0.25, midY - 6, size.width * 0.5, midY);
    path.quadraticBezierTo(size.width * 0.75, midY + 6, size.width, midY - 2);

    canvas.drawPath(path, paint);

    // Subtle fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _PlaceholderLinePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// Actual sparkline painter with smooth curves and gradient fill
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

    // Add vertical padding so line doesn't touch edges
    const verticalPadding = 4.0;
    final drawHeight = size.height - (verticalPadding * 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.25),
          color.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedY = (values[i] - minVal) / normalizedRange;
      final y = verticalPadding + drawHeight - (normalizedY * drawHeight);
      points.add(Offset(x, y));
    }

    // Build smooth curve using quadratic bezier
    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(
          controlX, prev.dy, (prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      fillPath.quadraticBezierTo(
          controlX, prev.dy, (prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
    }
    // Final segment to last point
    final last = points.last;
    path.lineTo(last.dx, last.dy);
    fillPath.lineTo(last.dx, last.dy);

    // Close fill path at bottom
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dot on last point
    canvas.drawCircle(last, 4, Paint()..color = color);
    canvas.drawCircle(last, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}