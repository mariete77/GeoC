import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated compass rose widget for the splash screen.
/// Continuously rotates with a smooth sweep animation,
/// styled with the GeoC "Modern Explorer's Journal" palette.
class AnimatedCompass extends StatefulWidget {
  final double size;

  const AnimatedCompass({super.key, this.size = 130});

  @override
  State<AnimatedCompass> createState() => _AnimatedCompassState();
}

class _AnimatedCompassState extends State<AnimatedCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CompassPainter(),
          ),
        );
      },
    );
  }
}

/// Paints a vintage compass rose with cardinal/intercardinal points.
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── Outer ring ──────────────────────────────────────────
    final outerPaint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.92, outerPaint);

    // ── Inner ring ──────────────────────────────────────────
    final innerPaint = Paint()
      ..color = AppColors.outlineVariant.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius * 0.78, innerPaint);

    // ── Tick marks (every 30°) ──────────────────────────────
    final tickPaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1.2;
    final smallTickPaint = Paint()
      ..color = AppColors.outlineVariant.withOpacity(0.4)
      ..strokeWidth = 0.6;

    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final isCardinal = i % 3 == 0;
      final paint = isCardinal ? tickPaint : smallTickPaint;
      final outerR = radius * 0.91;
      final innerR = isCardinal ? radius * 0.82 : radius * 0.86;

      canvas.drawLine(
        Offset(
          center.dx + innerR * sin(angle),
          center.dy - innerR * cos(angle),
        ),
        Offset(
          center.dx + outerR * sin(angle),
          center.dy - outerR * cos(angle),
        ),
        paint,
      );
    }

    // ── Cardinal direction diamond points (N/S/E/W) ─────────
    _drawDiamondPoint(
      canvas,
      center,
      radius * 0.72,
      0, // North — primary color, larger
      AppColors.primary,
      AppColors.primary.withOpacity(0.15),
      radius * 0.28,
    );

    _drawDiamondPoint(
      canvas,
      center,
      radius * 0.55,
      pi, // South
      AppColors.outline,
      AppColors.outline.withOpacity(0.08),
      radius * 0.18,
    );

    _drawDiamondPoint(
      canvas,
      center,
      radius * 0.55,
      pi / 2, // East
      AppColors.tertiary,
      AppColors.tertiary.withOpacity(0.08),
      radius * 0.18,
    );

    _drawDiamondPoint(
      canvas,
      center,
      radius * 0.55,
      -pi / 2, // West
      AppColors.tertiary,
      AppColors.tertiary.withOpacity(0.08),
      radius * 0.18,
    );

    // ── Intercardinal thin lines (NE/SE/SW/NW) ──────────────
    final interPaint = Paint()
      ..color = AppColors.outlineVariant.withOpacity(0.5)
      ..strokeWidth = 0.8;

    for (var i = 0; i < 4; i++) {
      final angle = pi / 4 + i * pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.5 * sin(angle),
          center.dy - radius * 0.5 * cos(angle),
        ),
        interPaint,
      );
    }

    // ── Center dot ──────────────────────────────────────────
    final centerDotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.05, centerDotPaint);

    final centerRingPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.08, centerRingPaint);

    // ── North indicator (small triangle at top) ─────────────
    final northPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - radius * 0.96);
    northPath.lineTo(center.dx - radius * 0.03, center.dy - radius * 0.91);
    northPath.lineTo(center.dx + radius * 0.03, center.dy - radius * 0.91);
    northPath.close();
    canvas.drawPath(northPath, northPaint);
  }

  /// Draws a diamond/rhombus pointer in a given direction.
  void _drawDiamondPoint(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    Color color,
    Color fillColor,
    double halfWidth,
  ) {
    final tip = Offset(
      center.dx + length * sin(angle),
      center.dy - length * cos(angle),
    );

    final perpAngle1 = angle + pi / 2;
    final perpAngle2 = angle - pi / 2;
    final backAngle = angle + pi;

    final left = Offset(
      center.dx + halfWidth * sin(perpAngle1),
      center.dy - halfWidth * cos(perpAngle1),
    );
    final right = Offset(
      center.dx + halfWidth * sin(perpAngle2),
      center.dy - halfWidth * cos(perpAngle2),
    );
    final back = Offset(
      center.dx + length * 0.15 * sin(backAngle),
      center.dy - length * 0.15 * cos(backAngle),
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(back.dx, back.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = fillColor..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}