import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

/// Login screen
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                _buildLogo(context),

                const SizedBox(height: 48),

                // Title
                Text(
                  'GeoQuiz Battle',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Compite con jugadores de todo el mundo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 64),

                // Loading state
                if (authState.isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Iniciando sesión...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ] else ...[
                  // Google Sign-In button
                  _buildGoogleSignInButton(context, ref, authState),

                  const SizedBox(height: 16),

                  // Apple Sign-In button
                  _buildAppleSignInButton(context, ref, authState),

                  const SizedBox(height: 32),

                  // Error message
                  if (authState.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .getErrorMessage(authState.error!),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 32),

                // Terms and Privacy
                Text(
                  'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.public,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: authState.isLoading
            ? null
            : () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.divider),
          ),
        ),
        icon: Image.asset(
          'assets/images/google_logo.png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.g_mobiledata, color: AppColors.textSecondary);
          },
        ),
        label: Text(
          'Continuar con Google',
          style: AppTextStyles.button.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: authState.isLoading
            ? null
            : () => ref.read(authNotifierProvider.notifier).signInWithApple(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.apple, size: 24),
        label: Text(
          'Continuar con Apple',
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}
