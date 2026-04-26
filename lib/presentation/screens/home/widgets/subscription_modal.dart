import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SubscriptionModal extends StatelessWidget {
  const SubscriptionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubscriptionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // ── Vintage Warmth Overlay ─────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                color: AppColors.highlight.withOpacity(0.03),
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────
          Column(
            children: [
              const SizedBox(height: 12),
              // Pull handle
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Editorial Header ────────────────
                      Text(
                        'MEMBRESÍA',
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explorador\nElite',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          height: 0.9,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text(
                        'Eleva tu experiencia geográfica con acceso extendido y funciones exclusivas de batalla.',
                        style: GoogleFonts.workSans(
                          fontSize: 18,
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 56),

                      // ── Benefits Section (Tonal Layering) ──
                      _buildBenefitItem(
                        icon: Icons.military_tech_outlined,
                        title: 'Modo Clasificatorio',
                        description: '5 Batallas diarias por ELO global.',
                      ),
                      const SizedBox(height: 24),
                      _buildBenefitItem(
                        icon: Icons.group_outlined,
                        title: 'Duelos con Amigos',
                        description: '5 Partidas directas contra tus contactos.',
                      ),
                      const SizedBox(height: 24),
                      _buildBenefitItem(
                        icon: Icons.bolt_outlined,
                        title: 'Partidas Rápidas',
                        description: '5 Sesiones de entrenamiento instantáneo.',
                      ),
                      const SizedBox(height: 24),
                      _buildBenefitItem(
                        icon: Icons.auto_stories_outlined,
                        title: 'Sin Interrupciones',
                        description: 'Experiencia fluida sin pausas obligatorias.',
                      ),

                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),

              // ── Footer CTA (Sticks to bottom) ────────────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ambientShadow(opacity: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL POR MES',
                              style: GoogleFonts.workSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1.99€',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'MEJOR VALOR',
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(9999),
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
                            onTap: () {
                              // TODO: Process subscription
                              Navigator.pop(context);
                            },
                            child: Center(
                              child: Text(
                                'Suscribirse Ahora',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Close Button ───────────────────────────────
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh.withOpacity(0.5),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 24, color: AppColors.primary),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
