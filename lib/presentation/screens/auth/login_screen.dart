import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../splash/widgets/animated_compass.dart';

/// Login screen — adapted from "Login" mockup.
/// Clean card design with gradient CTA, decorative background elements.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp) {
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _displayNameController.text.trim(),
          );
    } else {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Navigate on successful auth
    ref.listen(authNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Decorative skewed background ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              color: AppColors.surfaceContainerLow,
              transform: Matrix4.skewY(-0.08),
              transformAlignment: Alignment.topLeft,
            ),
          ),

          // ── Decorative blur circle (bottom-right) ────
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiaryContainer.withOpacity(0.10),
              ),
            ),
          ),

          // ── Main card content ─────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1C1B).withOpacity(0.06),
                      blurRadius: 64,
                      offset: const Offset(0, 32),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ────────────────────────
                        _buildHeader(),
                        const SizedBox(height: 40),

                        // ── Display Name (sign up only) ───
                        if (_isSignUp) ...[
                          _buildTextField(
                            controller: _displayNameController,
                            label: 'Nombre',
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Introduce tu nombre'
                                    : null,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Email ─────────────────────────
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Introduce tu email';
                            }
                            if (!v.contains('@')) return 'Email no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── Password ──────────────────────
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.outline,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Introduce tu contraseña';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // ── CTA Button ────────────────────
                        _buildGradientButton(authState),
                        const SizedBox(height: 24),

                        // ── Toggle sign up / sign in ──────
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignUp
                                      ? '¿Ya tienes cuenta? '
                                      : '¿No tienes cuenta? ',
                                ),
                                TextSpan(
                                  text: _isSignUp
                                      ? 'Inicia sesión'
                                      : 'Crea una cuenta',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Divider ───────────────────────
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: AppColors.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o continúa con',
                                style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: AppColors.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Social Buttons / Loading ──────
                        if (authState.isLoading)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: const AnimatedCompass(size: 80),
                            ),
                          )
                        else ...[
                          _buildGoogleButton(),
                          const SizedBox(height: 12),
                          _buildAppleButton(),
                        ],

                        // ── Error ─────────────────────────
                        if (authState.hasError) ...[
                          const SizedBox(height: 16),
                          _buildErrorCard(authState.error!),
                        ],

                        const SizedBox(height: 16),

                        // ── Terms ─────────────────────────
                        Text(
                          'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Builders ──────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ).createShader(bounds),
          child: Text(
            'GeoC',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The Digital Cartographer',
          style: GoogleFonts.workSans(
            fontSize: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(AsyncValue authState) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: authState.isLoading ? null : _submit,
            child: Center(
              child: authState.isLoading
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: const AnimatedCompass(size: 28),
                    )
                  : Text(
                      _isSignUp ? 'Crear cuenta' : 'Begin Journey',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.workSans(
        fontSize: 16,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.outline),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceVariant.withOpacity(0.5),
        labelStyle: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () =>
            ref.read(authNotifierProvider.notifier).signInWithGoogle(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLowest,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
          ),
        ),
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: Text(
          'Continuar con Google',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () =>
            ref.read(authNotifierProvider.notifier).signInWithApple(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onSurface,
          foregroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.apple, size: 20),
        label: Text(
          'Continuar con Apple',
          style: GoogleFonts.workSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ref.read(authNotifierProvider.notifier).getErrorMessage(error),
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}