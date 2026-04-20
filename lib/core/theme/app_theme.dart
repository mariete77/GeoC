import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// GeoC Design System — Material 3 theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        shadow: Color(0x0F1A1C1B),
        scrim: AppColors.onBackground,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ─────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Buttons ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryContainer;
            }
            return AppColors.primary;
          }),
          foregroundColor:
              WidgetStateProperty.all(AppColors.onPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: AppColors.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
          foregroundColor: AppColors.primary,
        ),
      ),

      // ── Cards ──────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
        ),
      ),

      // ── Input Fields ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Bottom Navigation ──────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Progress Indicator ─────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryFixed,
      ),

      // ── Divider (ghost) ────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withOpacity(0.15),
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // ── Chip ───────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        selectedColor: AppColors.secondaryContainer,
        labelStyle: const TextStyle(color: AppColors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),

      // ── Floating Action Button ─────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.inversePrimary,
        onPrimary: AppColors.onPrimaryFixed,
        primaryContainer: AppColors.primaryFixedDim,
        onPrimaryContainer: AppColors.onPrimaryFixedVariant,
        secondary: AppColors.secondaryFixedDim,
        onSecondary: AppColors.onSecondaryFixed,
        secondaryContainer: AppColors.onSecondaryFixedVariant,
        onSecondaryContainer: AppColors.secondaryFixed,
        tertiary: AppColors.tertiaryFixedDim,
        onTertiary: AppColors.onTertiaryFixed,
        tertiaryContainer: AppColors.onTertiaryFixedVariant,
        onTertiaryContainer: AppColors.tertiaryFixed,
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        errorContainer: const Color(0xFF93000A),
        onErrorContainer: const Color(0xFFFFDAD6),
        surface: const Color(0xFF1A1C1B),
        onSurface: AppColors.inverseOnSurface,
        surfaceContainerHighest: const Color(0xFF323432),
        surfaceContainerHigh: const Color(0xFF2C2E2C),
        surfaceContainer: const Color(0xFF262826),
        surfaceContainerLow: const Color(0xFF202222),
        surfaceContainerLowest: const Color(0xFF141615),
        surfaceVariant: const Color(0xFF424841),
        onSurfaceVariant: const Color(0xFFC2C8BF),
        outline: const Color(0xFF8C938A),
        outlineVariant: const Color(0xFF424841),
        inverseSurface: AppColors.surface,
        onInverseSurface: AppColors.onSurface,
        shadow: Color(0x4D000000),
        scrim: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF141615),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF141615),
        foregroundColor: AppColors.inverseOnSurface,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}