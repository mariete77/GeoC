import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GeoC Design System — Editorial Authority typography.
///
/// Plus Jakarta Sans = "Competitive" voice (display/headlines).
/// Work Sans = "Educational" voice (body/labels).
class AppTextStyles {
  AppTextStyles._();

  // ── Display (Plus Jakarta Sans) ──────────────────────────
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w900,
        color: AppColors.onSurface,
        height: 1.12,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMd => GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        height: 1.16,
      );

  static TextStyle get displaySm => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        height: 1.22,
      );

  // ── Headlines (Plus Jakarta Sans) ────────────────────────
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.onSurface,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.33,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.4,
      );

  // ── Body (Work Sans) ─────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.43,
      );

  static TextStyle get bodySmall => GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.33,
      );

  // ── Buttons ──────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimary,
        height: 1.25,
      );

  static TextStyle get buttonSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        height: 1.43,
      );

  // ── Timer (editorial, large) ─────────────────────────────
  static TextStyle get timer => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: AppColors.error,
        height: 1,
      );

  // ── Score / ELO ──────────────────────────────────────────
  static TextStyle get score => GoogleFonts.plusJakartaSans(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        height: 1,
        letterSpacing: -1,
      );

  static TextStyle get elo => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        height: 1.2,
      );

  // ── Labels (Work Sans) ───────────────────────────────────
  static TextStyle get label => GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.workSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        height: 1.6,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.33,
      );
}