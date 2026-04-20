import 'package:flutter/material.dart';

/// GeoC Design System — "Modern Explorer's Journal" palette.
///
/// Tonal depth, earth-toned organic spectrum. No 1px borders.
/// Boundaries defined solely through background color shifts.
class AppColors {
  AppColors._();

  // ── Primary (Forest Green) ───────────────────────────────
  static const Color primary = Color(0xFF426445);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF5A7D5C);
  static const Color onPrimaryContainer = Color(0xFFF7FFF2);
  static const Color primaryFixed = Color(0xFFC5EDC5);
  static const Color primaryFixedDim = Color(0xFFAAD0AA);
  static const Color onPrimaryFixed = Color(0xFF002109);
  static const Color onPrimaryFixedVariant = Color(0xFF2D4E31);

  // ── Secondary (Sage Green) ───────────────────────────────
  static const Color secondary = Color(0xFF49654B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC8E8C6);
  static const Color onSecondaryContainer = Color(0xFF4D694F);
  static const Color secondaryFixed = Color(0xFFCBEBC9);
  static const Color secondaryFixedDim = Color(0xFFAFCFAE);
  static const Color onSecondaryFixed = Color(0xFF06210C);
  static const Color onSecondaryFixedVariant = Color(0xFF324D34);

  // ── Tertiary (Warm Tan) ──────────────────────────────────
  static const Color tertiary = Color(0xFF705837);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8B704D);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color tertiaryFixed = Color(0xFFFFDDB4);
  static const Color tertiaryFixedDim = Color(0xFFE2C199);
  static const Color onTertiaryFixed = Color(0xFF291801);
  static const Color onTertiaryFixedVariant = Color(0xFF594324);

  // ── Error ────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Surfaces (Tonal Layering) ────────────────────────────
  static const Color background = Color(0xFFF9F9F7);
  static const Color onBackground = Color(0xFF1A1C1B);
  static const Color surface = Color(0xFFF9F9F7);
  static const Color onSurface = Color(0xFF1A1C1B);
  static const Color surfaceVariant = Color(0xFFE2E3E1);
  static const Color onSurfaceVariant = Color(0xFF424841);
  static const Color surfaceTint = Color(0xFF446647);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F4F2);
  static const Color surfaceContainer = Color(0xFFEEEEEC);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E6);
  static const Color surfaceContainerHighest = Color(0xFFE2E3E1);

  static const Color surfaceDim = Color(0xFFDADAD8);
  static const Color surfaceBright = Color(0xFFF9F9F7);

  // ── Inverse ──────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color inverseOnSurface = Color(0xFFF1F1EF);
  static const Color inversePrimary = Color(0xFFAAD0AA);

  // ── Outlines ─────────────────────────────────────────────
  static const Color outline = Color(0xFF727970);
  static const Color outlineVariant = Color(0xFFC2C8BF);

  // ── Signature Gradient Colors ────────────────────────────
  /// 145° gradient from primary → primaryContainer (CTA "brushed silk")
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.6, -1.0),
    end: Alignment(0.6, 1.0),
    colors: [primary, primaryContainer],
  );

  // ── Highlight / Vintage Warmth ──────────────────────────
  static const Color highlight = Color(0xFFD9B991);

  // ── Shadows (tinted, never pure black) ──────────────────
  static Color ambientShadow({double opacity = 0.06}) =>
      const Color(0xFF1A1C1B).withOpacity(opacity);

  // ── Ghost Border (outlineVariant at 15%) ────────────────
  static Color get ghostBorder => outlineVariant.withOpacity(0.15);

  // ── Semantic / Game ─────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color correct = primaryContainer;
  static const Color incorrect = errorContainer;
  static const Color timerNormal = primary;
  static const Color timerWarning = tertiary;
  static const Color timerDanger = error;

  // ── Ranks ───────────────────────────────────────────────
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFFE5E4E2);
  static const Color rankDiamond = Color(0xFFB9F2FF);

  // ── Backward-compatible aliases (deprecated) ────────────
  @Deprecated('Use onSurface instead')
  static const Color textPrimary = onSurface;
  @Deprecated('Use onSurfaceVariant instead')
  static const Color textSecondary = onSurfaceVariant;
  @Deprecated('Use onPrimary instead')
  static const Color textOnPrimary = onPrimary;
  @Deprecated('Use onSecondary instead')
  static const Color textOnSecondary = onSecondary;
  @Deprecated('Use outlineVariant instead')
  static const Color divider = outlineVariant;
  @Deprecated('Use primaryContainer instead')
  static const Color primaryDark = primaryContainer;
  @Deprecated('Use primaryFixed instead')
  static const Color primaryLight = primaryFixed;
  @Deprecated('Use ambientShadow() instead')
  static Color get shadow => ambientShadow(opacity: 0.1);
  @Deprecated('Use ambientShadow() instead')
  static Color get shadowDark => ambientShadow(opacity: 0.2);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
