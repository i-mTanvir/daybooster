import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base
  static const Color bg = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF0F0F1A);
  static const Color bgCardLight = Color(0xFF141428);
  static const Color bgCardMid = Color(0xFF12121F);

  // Accents
  static const Color electricBlue = Color(0xFF00D4FF);
  static const Color neonPurple = Color(0xFF9B59FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonOrange = Color(0xFFFF8C00);
  static const Color neonRed = Color(0xFFFF3B3B);
  static const Color neonYellow = Color(0xFFF5D300);

  // Text
  static const Color textPrimary = Color(0xFFE8E8FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF44445A);

  // Borders
  static const Color borderGlow = Color(0xFF00D4FF);
  static const Color borderSubtle = Color(0xFF1E1E35);

  // Performance Colors
  static const Color perfCritical = Color(0xFFFF3B3B);
  static const Color perfWeak = Color(0xFFFF8C00);
  static const Color perfBelowTarget = Color(0xFFF5D300);
  static const Color perfAlmost = Color(0xFF00AAFF);
  static const Color perfTarget = Color(0xFF00E676);
  static const Color perfOverdrive = Color(0xFFC77DFF);
  static const Color perfLegendary = Color(0xFFFFD700);

  static Color getPerformanceColor(double percentage) {
    if (percentage < 40) return perfCritical;
    if (percentage < 60) return perfWeak;
    if (percentage < 80) return perfBelowTarget;
    if (percentage < 90) return perfAlmost;
    if (percentage <= 110) return perfTarget;
    if (percentage <= 130) return perfOverdrive;
    return perfLegendary;
  }

  static String getPerformanceLabel(double percentage) {
    if (percentage < 40) return 'CRITICAL FAIL';
    if (percentage < 60) return 'WEAK';
    if (percentage < 80) return 'BELOW TARGET';
    if (percentage < 90) return 'ALMOST';
    if (percentage <= 110) return 'TARGET HIT ✅';
    if (percentage <= 130) return 'OVERDRIVE';
    return 'LEGENDARY ⭐';
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.neonPurple,
        tertiary: AppColors.gold,
        surface: AppColors.bgCard,
        error: AppColors.neonRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        titleSmall: GoogleFonts.orbitron(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        bodyLarge: GoogleFonts.shareTechMono(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.shareTechMono(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.shareTechMono(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.orbitron(
          color: AppColors.electricBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      useMaterial3: true,
    );
  }
}
