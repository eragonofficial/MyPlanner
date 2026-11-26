import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkBgSecondary = Color(0xFF161B22);
  static const Color darkBgCard = Color(0xFF21262D);
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassSurfaceLight = Color(0x2EFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);

  // Strict High-Contrast Text Tokens (WCAG AAA compliant)
  // On Dark Surfaces (#0F172A, #1E293B, #161B22, #0D1117):
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp near-white
  static const Color textSecondary = Color(0xFFCBD5E1); // High-contrast slate
  static const Color textMuted = Color(0xFF94A3B8); // Sharp readable muted text

  // On Light or Bright Surfaces (#ECFDF5, Cyan/Emerald buttons):
  static const Color textOnLight = Color(0xFF0F172A); // Deep charcoal
  static const Color textOnLightSecondary = Color(0xFF334155); // Deep slate
  static const Color textOnLightMuted = Color(0xFF64748B);

  // Completed Task Specific Colors
  static const Color completedBgDark = Color(0x73064E3B); // #064E3B with alpha 0.45
  static const Color completedBgLight = Color(0xFFECFDF5); // Soft mint tint
  static const Color completedTextDark = Color(0xFFE2E8F0); // Crisp light slate
  static const Color completedTextLight = Color(0xFF065F46); // Deep forest green

  // Pomodoro Phase Colors
  static const Color focusColor = Color(0xFF10B981);
  static const Color breakColor = Color(0xFF06B6D4);

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient darkNatureGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A141D),
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF0D1B2A),
    ],
  );

  static const LinearGradient focusGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient breakGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
  );

  /// Helper to calculate automatic high-contrast text color based on background luminance
  static Color getContrastingTextColor(
    Color background, {
    Color? darkTextColor,
    Color? lightTextColor,
  }) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark
        ? (lightTextColor ?? textPrimary)
        : (darkTextColor ?? textOnLight);
  }

  /// Helper to get background color for completed task cards
  static Color getCompletedCardBg(bool isDark) {
    return isDark ? completedBgDark : completedBgLight;
  }

  /// Helper to get text color for completed task cards
  static Color getCompletedTextColor(bool isDark) {
    return isDark ? completedTextDark : completedTextLight;
  }
}
