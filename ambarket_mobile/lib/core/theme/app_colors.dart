import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color backgroundDarker;
  final Color primary;
  final Color primaryDark;
  final Color accent;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color surface;
  final Color surfaceHighlight;

  final Color border;
  final Color borderStrong;

  final Color error;
  final Color warning;
  final Color success;
  final Color info;

  const AppColorsExtension({
    required this.background,
    required this.backgroundDarker,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.surface,
    required this.surfaceHighlight,
    required this.border,
    required this.borderStrong,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? backgroundDarker,
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? surface,
    Color? surfaceHighlight,
    Color? border,
    Color? borderStrong,
    Color? error,
    Color? warning,
    Color? success,
    Color? info,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      backgroundDarker: backgroundDarker ?? this.backgroundDarker,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      surface: surface ?? this.surface,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      backgroundDarker: Color.lerp(
        backgroundDarker,
        other.backgroundDarker,
        t,
      )!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHighlight: Color.lerp(
        surfaceHighlight,
        other.surfaceHighlight,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

class AppColors {
  static const light = AppColorsExtension(
    background: Color(0xFFF8FAFC), // Slate 50
    backgroundDarker: Color(0xFFF1F5F9), // Slate 100
    primary: Color(0xFF10B981), // Emerald 500
    primaryDark: Color(0xFF059669), // Emerald 600
    accent: Color(0xFF14B8A6), // Teal 500
    textPrimary: Color(0xFF0F172A), // Slate 900
    textSecondary: Color(0xFF475569), // Slate 600
    textMuted: Color(0xFF94A3B8), // Slate 400
    surface: Color(0xFFFFFFFF), // White
    surfaceHighlight: Color(0xFFF8FAFC), // Slate 50
    border: Color(0xFFE2E8F0), // Slate 200
    borderStrong: Color(0xFFCBD5E1), // Slate 300
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    success: Color(0xFF10B981),
    info: Color(0xFF3B82F6),
  );
}

extension AppThemeExtension on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColors.light;
}
