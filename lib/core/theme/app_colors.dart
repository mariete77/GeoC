import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  // Primary
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Secondary
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFF57C00);

  // Game
  static const Color correct = Color(0xFF4CAF50);
  static const Color incorrect = Color(0xFFF44336);
  static const Color timerNormal = Color(0xFF4CAF50);
  static const Color timerWarning = Color(0xFFFF9800);
  static const Color timerDanger = Color(0xFFF44336);

  // Ranks
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFFE5E4E2);
  static const Color rankDiamond = Color(0xFFB9F2FF);

  // Background
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Shadow
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.2);

  // Divider
  static const Color divider = Color(0xFFE0E0E0);
}
