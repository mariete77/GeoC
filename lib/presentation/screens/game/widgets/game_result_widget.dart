import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class GameResultWidget extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final double averageTime;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;
  final String? opponentName;
  final int? eloChange;
  final bool isVictory;

  const GameResultWidget({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageTime,
    required this.onPlayAgain,
    required this.onGoHome,
    this.opponentName,
    this.eloChange,
    this.isVictory = true,
  });

  @override
  State<GameResultWidget> createState() => _GameResultWidgetState();
}

class _GameResultWidgetState extends State<GameResultWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    final accuracy =
        widget.totalQuestions > 0
            ? (widget.correctAnswers / widget.totalQuestions) * 100
            : 0.0;
    final hasOpponent = widget.opponentName != null;

    return Container(
      color: AppColors.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(_controller),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Victory / Defeat Banner ────────────────────
                _buildResultBanner(),
                const SizedBox(height: 32),

                // ── Bento Grid: Stats + ELO ────────────────────
                _buildBentoRow(accuracy),
                const SizedBox(height: 16),

                // ── Detail Cards Row ───────────────────────────
                if (hasOpponent) ...[
                  _buildDetailCards(),
                  const SizedBox(height: 16),
                ],

                // ── Performance Message ────────────────────────
                _buildPerformanceMessage(accuracy),
                const SizedBox(height: 32),

                // ── Action Buttons ─────────────────────────────
                _buildActionButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VICTORY / DEFEAT BANNER
  // ═══════════════════════════════════════════════════════════

  Widget _buildResultBanner() {
    final resultText = widget.isVictory ? 'Victoria' : 'Derrota';
    final resultBg =
        widget.isVictory
            ? AppColors.primaryContainer
            : AppColors.error.withOpacity(0.15);
    final resultFg =
        widget.isVictory
            ? AppColors.onPrimaryContainer
            : AppColors.error;
    final bgText = widget.isVictory ? 'VICTORIA' : 'DERROTA';

    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Large background text
          Positioned(
            left: -8,
            top: -10,
            child: Text(
              bgText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: AppColors.surfaceContainerHigh,
                height: 1,
                letterSpacing: -4,
              ),
            ),
          ),
          // Foreground banner pill
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.only(
                left: 32,
                right: 48,
                top: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: resultBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9999),
                  bottomLeft: Radius.circular(9999),
                  topRight: Radius.circular(9999),
                  bottomRight: Radius.circular(9999),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isVictory ? AppColors.primary : AppColors.error)
                        .withOpacity(0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resultText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: resultFg,
                      letterSpacing: -1,
                    ),
                  ),
                  if (widget.opponentName != null)
                    Text(
                      'vs. ${widget.opponentName}',
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        color: AppColors.inversePrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BENTO GRID: STATS CARD + ELO CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildBentoRow(double accuracy) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: Key Stats Card ─────────────────────
          Expanded(
            flex: 5,
            child: _buildAmbientCard(
              color: AppColors.surfaceContainerLowest,
              child: Stack(
                children: [
                  // Decorative corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.highlight.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(80),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen del Duelo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Correct answers
                        _buildStatBlock(
                          label: 'Preguntas Correctas',
                          value: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${widget.correctAnswers}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: '/${widget.totalQuestions}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Points
                        _buildStatBlock(
                          label: 'Puntos Obtenidos',
                          value: Text(
                            '+${widget.score}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.tertiaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Accuracy & Time
                        Row(
                          children: [
                            _buildMiniStat(
                              icon: Icons.percent,
                              value:
                                  '${accuracy.toStringAsFixed(0)}%',
                              label: 'Precisión',
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 16),
                            _buildMiniStat(
                              icon: Icons.timer_outlined,
                              value:
                                  '${(widget.averageTime / 1000).toStringAsFixed(1)}s',
                              label: 'Tiempo medio',
                              color: AppColors.tertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Right: ELO Card ──────────────────────────
          Expanded(
            flex: 7,
            child: _buildAmbientCard(
              color: AppColors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progresión ELO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rango: ${_getRank()}',
                                style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.eloChange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '${widget.eloChange! > 0 ? "+" : ""}${widget.eloChange} ELO',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSecondaryContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ELO Graph (fixed height to avoid IntrinsicHeight + Expanded conflict)
                    SizedBox(
                      height: 120,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildEloGraph(constraints);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEloGraph(BoxConstraints constraints) {
    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      painter: _EloGraphPainter(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DETAIL CARDS (opponent / best answer)
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailCards() {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Best Answer Card
          Expanded(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surfaceContainerHighest,
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'MEJOR ACIERTO',
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Sigue jugando!',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Opponent Card
          Expanded(
            child: _buildAmbientCard(
              color: AppColors.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OPONENTE',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.opponentName ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (widget.eloChange != null)
                                Text(
                                  'ELO: ${widget.eloChange! > 0 ? "+" : ""}${widget.eloChange}',
                                  style: GoogleFonts.workSans(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PERFORMANCE MESSAGE
  // ═══════════════════════════════════════════════════════════

  Widget _buildPerformanceMessage(double accuracy) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getPerformanceMessage(accuracy),
          style: GoogleFonts.workSans(
            color: AppColors.onSurface,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Volver al Inicio (outline)
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onGoHome,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(
                'Volver al Inicio',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Revancha / Jugar de nuevo (filled)
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onPlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryContainer,
                foregroundColor: AppColors.onTertiaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.replay, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.opponentName != null ? 'Revancha' : 'Jugar de Nuevo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAmbientCard({required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1B).withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatBlock({required String label, required Widget value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRank() {
    final s = widget.score;
    if (s >= 1500) return 'Cartógrafo Maestro';
    if (s >= 1200) return 'Explorador Experto';
    if (s >= 900) return 'Viajero Hábil';
    if (s >= 600) return 'Aprendiz Navegante';
    return 'Novato';
  }

  String _getPerformanceMessage(double accuracy) {
    if (accuracy >= 90) return '🎯 ¡Increíble! ¡Eres un maestro de la geografía!';
    if (accuracy >= 80) return '🌟 ¡Gran trabajo! ¡Sigue así!';
    if (accuracy >= 70) return '👏 ¡Bien! ¡Cada vez mejor!';
    if (accuracy >= 60) return '💪 ¡Buen esfuerzo! ¡La práctica hace al maestro!';
    return '📚 ¡Sigue aprendiendo! ¡Cada partida cuenta!';
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTER: ELO Graph
// ═══════════════════════════════════════════════════════════════

class _EloGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.outlineVariant.withOpacity(0.2)
          ..strokeWidth = 1;

    // Grid lines
    for (int i = 0; i < 4; i++) {
      final y = (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // ELO curve
    final linePaint =
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.2),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    // Simulated ELO data points
    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.15, size.height * 0.78),
      Offset(size.width * 0.25, size.height * 0.70),
      Offset(size.width * 0.40, size.height * 0.62),
      Offset(size.width * 0.55, size.height * 0.68),
      Offset(size.width * 0.70, size.height * 0.42),
      Offset(size.width * 0.85, size.height * 0.28),
      Offset(size.width, size.height * 0.12),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      path.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
      fillPath.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, linePaint);

    // Fill area under curve
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Endpoint dot
    final dotPaint =
        Paint()
          ..color = AppColors.primary;
    canvas.drawCircle(points.last, 4, dotPaint);

    // White inner dot
    final innerDotPaint =
        Paint()
          ..color = AppColors.background;
    canvas.drawCircle(points.last, 2, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}