import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { dark, cream, lime }

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color bgCard;
  final Color bgCardLight;
  final Color neonGreen;
  final Color neonRed;
  final Color neonPurple;
  final Color neonYellow;
  final Color electricBlue;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;

  // Performance Colors
  final Color perfLegendary;
  final Color perfOverdrive;
  final Color perfTarget;
  final Color perfAlmost;
  final Color perfBelowTarget;
  final Color perfWeak;
  final Color perfCritical;

  const AppThemeColors({
    required this.bg,
    required this.bgCard,
    required this.bgCardLight,
    required this.neonGreen,
    required this.neonRed,
    required this.neonPurple,
    required this.neonYellow,
    required this.electricBlue,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.perfLegendary,
    required this.perfOverdrive,
    required this.perfTarget,
    required this.perfAlmost,
    required this.perfBelowTarget,
    required this.perfWeak,
    required this.perfCritical,
  });

  static const dark = AppThemeColors(
    bg: Color(0xFF0D0D11),
    bgCard: Color(0xFF15151D),
    bgCardLight: Color(0xFF1E1E28),
    neonGreen: Color(0xFF00FF9D),
    neonRed: Color(0xFFFF2A5F),
    neonPurple: Color(0xFFB026FF),
    neonYellow: Color(0xFFFFD700),
    electricBlue: Color(0xFF00D4FF),
    gold: Color(0xFFFFB800),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0B0),
    textMuted: Color(0xFF606070),
    borderSubtle: Color(0xFF2A2A35),
    perfLegendary: Color(0xFFFFB800),
    perfOverdrive: Color(0xFFB026FF),
    perfTarget: Color(0xFF00FF9D),
    perfAlmost: Color(0xFF00D4FF),
    perfBelowTarget: Color(0xFFFFD700),
    perfWeak: Color(0xFFFF8A00),
    perfCritical: Color(0xFFFF2A5F),
  );

  static const light = AppThemeColors(
    bg: Color(0xFFF7F5EB), // Creamish color
    bgCard: Color(0xFFFFFFFF),
    bgCardLight: Color(0xFFF0EFE6),
    neonGreen: Color(0xFF00A86B), // Darker for light mode
    neonRed: Color(0xFFE5003F), // Deeper red
    neonPurple: Color(0xFF8A00E6), // Deeper purple
    neonYellow: Color(0xFFD4B100),
    electricBlue: Color(0xFF008CC9), // Deeper blue
    gold: Color(0xFFD49A00),
    textPrimary: Color(0xFF1A1A24),
    textSecondary: Color(0xFF5A5A6A),
    textMuted: Color(0xFF8A8A9A),
    borderSubtle: Color(0xFFE0DFD5),
    perfLegendary: Color(0xFFD49A00),
    perfOverdrive: Color(0xFF8A00E6),
    perfTarget: Color(0xFF00A86B),
    perfAlmost: Color(0xFF008CC9),
    perfBelowTarget: Color(0xFFD4B100),
    perfWeak: Color(0xFFD46A00),
    perfCritical: Color(0xFFE5003F),
  );

  static const lime = AppThemeColors(
    bg: Color(0xFFF4F9F1), // Soft pale lime
    bgCard: Color(0xFFFFFFFF),
    bgCardLight: Color(0xFFE9F5E1),
    neonGreen: Color(0xFF2E7D32),
    neonRed: Color(0xFFD32F2F),
    neonPurple: Color(0xFF7B1FA2),
    neonYellow: Color(0xFFFBC02D),
    electricBlue: Color(0xFF0277BD),
    gold: Color(0xFFF9A825),
    textPrimary: Color(0xFF1B5E20),
    textSecondary: Color(0xFF388E3C),
    textMuted: Color(0xFF81C784),
    borderSubtle: Color(0xFFC8E6C9),
    perfLegendary: Color(0xFFF9A825),
    perfOverdrive: Color(0xFF7B1FA2),
    perfTarget: Color(0xFF2E7D32),
    perfAlmost: Color(0xFF0277BD),
    perfBelowTarget: Color(0xFFFBC02D),
    perfWeak: Color(0xFFF57C00),
    perfCritical: Color(0xFFD32F2F),
  );

  @override
  ThemeExtension<AppThemeColors> copyWith() => this;

  @override
  ThemeExtension<AppThemeColors> lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardLight: Color.lerp(bgCardLight, other.bgCardLight, t)!,
      neonGreen: Color.lerp(neonGreen, other.neonGreen, t)!,
      neonRed: Color.lerp(neonRed, other.neonRed, t)!,
      neonPurple: Color.lerp(neonPurple, other.neonPurple, t)!,
      neonYellow: Color.lerp(neonYellow, other.neonYellow, t)!,
      electricBlue: Color.lerp(electricBlue, other.electricBlue, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      perfLegendary: Color.lerp(perfLegendary, other.perfLegendary, t)!,
      perfOverdrive: Color.lerp(perfOverdrive, other.perfOverdrive, t)!,
      perfTarget: Color.lerp(perfTarget, other.perfTarget, t)!,
      perfAlmost: Color.lerp(perfAlmost, other.perfAlmost, t)!,
      perfBelowTarget: Color.lerp(perfBelowTarget, other.perfBelowTarget, t)!,
      perfWeak: Color.lerp(perfWeak, other.perfWeak, t)!,
      perfCritical: Color.lerp(perfCritical, other.perfCritical, t)!,
    );
  }
}

extension ThemeColorsExt on BuildContext {
  AppThemeColors get themeColors => Theme.of(this).extension<AppThemeColors>()!;
}

// Keep a fallback AppColors for places where context isn't available immediately,
// though it will always return Dark mode colors.
class AppColors {
  static const Color bg = Color(0xFF0D0D11);
  static const Color bgCard = Color(0xFF15151D);
  static const Color bgCardLight = Color(0xFF1E1E28);
  static const Color neonGreen = Color(0xFF00FF9D);
  static const Color neonRed = Color(0xFFFF2A5F);
  static const Color neonPurple = Color(0xFFB026FF);
  static const Color neonYellow = Color(0xFFFFD700);
  static const Color electricBlue = Color(0xFF00D4FF);
  static const Color gold = Color(0xFFFFB800);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B0);
  static const Color textMuted = Color(0xFF606070);
  static const Color borderSubtle = Color(0xFF2A2A35);

  static const Color perfLegendary = Color(0xFFFFB800);
  static const Color perfOverdrive = Color(0xFFB026FF);
  static const Color perfTarget = Color(0xFF00FF9D);
  static const Color perfAlmost = Color(0xFF00D4FF);
  static const Color perfBelowTarget = Color(0xFFFFD700);
  static const Color perfWeak = Color(0xFFFF8A00);
  static const Color perfCritical = Color(0xFFFF2A5F);

  static Color getPerformanceColor(double percentage, AppThemeColors colors) {
    if (percentage >= 130) return colors.perfLegendary;
    if (percentage >= 110) return colors.perfOverdrive;
    if (percentage >= 90) return colors.perfTarget;
    if (percentage >= 70) return colors.perfAlmost;
    if (percentage >= 50) return colors.perfBelowTarget;
    if (percentage >= 30) return colors.perfWeak;
    return colors.perfCritical;
  }

  static String getPerformanceLabel(double percentage) {
    if (percentage >= 130) return 'LEGENDARY';
    if (percentage >= 110) return 'OVERDRIVE';
    if (percentage >= 90) return 'TARGET';
    if (percentage >= 70) return 'ALMOST';
    if (percentage >= 50) return 'STRUGGLING';
    if (percentage >= 30) return 'WEAK';
    return 'CRITICAL';
  }
}

class AppTheme {
  static final ValueNotifier<AppThemeType> themeNotifier = ValueNotifier(AppThemeType.dark);

  static ThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.cream:
        return _buildTheme(Brightness.light, AppThemeColors.light);
      case AppThemeType.lime:
        return _buildTheme(Brightness.light, AppThemeColors.lime);
      case AppThemeType.dark:
        return _buildTheme(Brightness.dark, AppThemeColors.dark);
    }
  }

  static ThemeData _buildTheme(Brightness brightness, AppThemeColors colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.neonGreen,
        brightness: brightness,
        primary: colors.electricBlue,
        secondary: colors.neonPurple,
        surface: colors.bgCard,
      ),
      textTheme: GoogleFonts.shareTechMonoTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
    );
  }
}
