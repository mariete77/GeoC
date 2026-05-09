import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class HowToPlayModal extends StatefulWidget {
  const HowToPlayModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HowToPlayModal(),
    );
  }

  @override
  State<HowToPlayModal> createState() => _HowToPlayModalState();
}

class _HowToPlayModalState extends State<HowToPlayModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ambientShadow(),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with icon ──────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.explore_outlined,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cómo Jugar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Domina la geografía, un duelo a la vez',
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
          const SizedBox(height: 28),

          // ── Section: Modos de Juego ───────────────────────────
          _buildSection('MODOS DE JUEGO'),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.bolt,
            color: AppColors.primary,
            title: 'Partida Rápida',
            description:
                '10 preguntas de opción múltiple. Sin presión, ideal para aprender y practicar.',
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            icon: Icons.military_tech,
            color: AppColors.tertiary,
            title: 'Multijugador',
            description:
                'Enfréntate a otros jugadores en tiempo real. Gana puntos ELO y asciende en el ranking global.',
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            icon: Icons.history_edu,
            color: AppColors.secondary,
            title: 'Fantasma',
            description:
                'Compite contra tus mejores partidas pasadas o las de tus amigos. Mejora tu propio récord.',
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            icon: Icons.edit,
            color: AppColors.tertiaryContainer,
            title: 'Escribe la Respuesta',
            description:
                'Pon a prueba tu conocimiento real escribiendo la respuesta. Gana más puntos por precisión y velocidad.',
          ),
          const SizedBox(height: 24),

          // ── Section: Tipos de Pregunta ────────────────────────
          _buildSection('TIPOS DE PREGUNTA'),
          const SizedBox(height: 12),
          _buildTypeGrid(),
          const SizedBox(height: 24),

          // ── Section: Sistema de Puntuación ────────────────────
          _buildSection('SISTEMA DE PUNTUACIÓN'),
          const SizedBox(height: 12),
          _buildAmbientCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildScoreRow(Icons.star, AppColors.primary, 'Acierto base',
                      '100 pts'),
                  const SizedBox(height: 12),
                  _buildScoreRow(Icons.timer_outlined, AppColors.secondary,
                      'Bonus de velocidad', '10 pts × segundos restantes'),
                  const SizedBox(height: 12),
                  _buildScoreRow(Icons.local_fire_department,
                      AppColors.tertiary, 'Bonus de racha', '50 pts × nivel'),
                  const SizedBox(height: 12),
                  _buildScoreRow(Icons.edit, AppColors.tertiaryContainer,
                      'Modo escribir', '150 pts base × precisión'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.tertiary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Máximo teórico: ~1000 puntos por partida perfecta (10/10, sin streak inicial)',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section: Cómo ganar ───────────────────────────────
          _buildSection('CÓMO GANAR'),
          const SizedBox(height: 12),
          _buildAmbientCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(
                      '1', 'Responde rápido', 'Cada segundo cuenta. Más velocidad = más puntos.'),
                  const SizedBox(height: 16),
                  _buildStep(
                      '2', 'Mantén la racha', 'Respuestas correctas consecutivas multiplican tu puntuación.'),
                  const SizedBox(height: 16),
                  _buildStep('3', 'Sé preciso',
                      'En modo escritura, la precisión importa. Una respuesta parcial da puntos parciales.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Section: ELO ──────────────────────────────────────
          _buildSection('RANKING ELO'),
          const SizedBox(height: 12),
          _buildAmbientCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildEloRow('Bronce', '0-1199', AppColors.rankBronze),
                  const SizedBox(height: 10),
                  _buildEloRow('Silver', '1200-1399', AppColors.rankSilver),
                  const SizedBox(height: 10),
                  _buildEloRow('Gold', '1400-1599', AppColors.rankGold),
                  const SizedBox(height: 10),
                  _buildEloRow(
                      'Platinum', '1600-1799', AppColors.rankPlatinum),
                  const SizedBox(height: 10),
                  _buildEloRow('Diamond', '1800+', AppColors.rankDiamond),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── CTA Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      '¡A JUGAR!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return _buildAmbientCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeGrid() {
    final types = [
      ('Bandera', Icons.flag_outlined, AppColors.primary),
      ('Capital', Icons.location_city_outlined, AppColors.secondary),
      ('Población', Icons.people_outline, AppColors.tertiary),
      ('Extensión', Icons.straighten, AppColors.primaryContainer),
      ('Río', Icons.water_drop_outlined, AppColors.secondaryContainer),
      ('Silueta', Icons.map_outlined, AppColors.tertiaryContainer),
      ('Moneda', Icons.monetization_on_outlined, AppColors.primary),
      ('Idioma', Icons.translate, AppColors.secondary),
      ('Región', Icons.public, AppColors.tertiary),
      ('Frontera', Icons.border_style, AppColors.primaryContainer),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.$3.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.$2, size: 16, color: t.$3),
              const SizedBox(width: 8),
              Text(
                t.$1,
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreRow(
      IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 13,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEloRow(String rank, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            rank,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Text(
          range,
          style: GoogleFonts.workSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow(),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
