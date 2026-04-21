import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/animated_compass.dart';

/// Splash screen — "PantallaCarga" design.
/// Vintage explorer aesthetic with segmented loading gauge.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAuthAndNavigate();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    ref.listenManual(authStateChangesProvider, (previous, next) {
      if (!mounted) return;
      next.whenData((user) {
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      });
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      },
      loading: () {},
      error: (_, __) {
        context.go('/login');
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Vintage warmth overlay ──────────────────────
          Positioned.fill(
            child: Container(
              color: AppColors.tertiaryFixed.withOpacity(0.10),
            ),
          ),

          // ── Central brand canvas ────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Icon — Animated compass rose
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const AnimatedCompass(size: 130),
                        ),
                        const SizedBox(height: 24),

                        // Brand Typography
                        Text(
                          'GeoC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 96,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -3,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Educational Subtitle
                        Text(
                          'THE DIGITAL CARTOGRAPHER',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surfaceTint,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom loading gauge ─────────────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CALIBRATING INSTRUMENTS',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Segmented gauge (5 bars, 3 filled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: _LoadingGauge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated segmented loading gauge matching the mockup.
class _LoadingGauge extends StatefulWidget {
  @override
  State<_LoadingGauge> createState() => _LoadingGaugeState();
}

class _LoadingGaugeState extends State<_LoadingGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _filledSegments = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _animController.addListener(() {
      final progress = _animController.value;
      final segments = (progress * 5).floor().clamp(0, 5);
      if (segments != _filledSegments) {
        setState(() => _filledSegments = segments);
      }
    });

    // Repeat animation cycle
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _animController.forward(from: 0);
    });
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < _filledSegments;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == 4 ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}