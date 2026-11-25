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

  // Text
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

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
}
