import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';

/// Circular timer with glassmorphism styling matching the Partida mockup.
/// Uses design-system colors: primary (safe), tertiary (warning), error (danger).
class TimerWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const TimerWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor(progress);

    return SizedBox(
      width: 96,
      height: 96,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CustomPaint(
            painter: _TimerPainter(progress: progress, timerColor: timerColor),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.20),
                ),
              ),
              child: Center(
                child: Text(
                  '${(progress * 10).ceil()}',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTimerColor(double progress) {
    if (progress > 0.5) {
      return AppColors.timerNormal; // primary
    } else if (progress > 0.25) {
      return AppColors.timerWarning; // tertiary
    } else {
      return AppColors.timerDanger; // error
    }
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color timerColor;

  _TimerPainter({required this.progress, required this.timerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle track
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = timerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}