import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.light.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.light.primary,
        secondary: AppColors.light.accent,
        surface: AppColors.light.surface,
        error: AppColors.light.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.light.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: AppTypography.h1.copyWith(
              color: AppColors.light.textPrimary,
            ),
            displayMedium: AppTypography.h2.copyWith(
              color: AppColors.light.textPrimary,
            ),
            displaySmall: AppTypography.h3.copyWith(
              color: AppColors.light.textPrimary,
            ),
            headlineMedium: AppTypography.h4.copyWith(
              color: AppColors.light.textPrimary,
            ),
            titleLarge: AppTypography.h5.copyWith(
              color: AppColors.light.textPrimary,
            ),
            titleMedium: AppTypography.h6.copyWith(
              color: AppColors.light.textPrimary,
            ),
            bodyLarge: AppTypography.bodyLg.copyWith(
              color: AppColors.light.textPrimary,
            ),
            bodyMedium: AppTypography.bodyMd.copyWith(
              color: AppColors.light.textPrimary,
            ),
            bodySmall: AppTypography.bodySm.copyWith(
              color: AppColors.light.textSecondary,
            ),
            labelLarge: AppTypography.button,
            labelSmall: AppTypography.caption.copyWith(
              color: AppColors.light.textMuted,
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.light.textPrimary,
          side: BorderSide(color: AppColors.light.borderStrong),
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.surface,
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.light.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.error),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.light.textPrimary),
        titleTextStyle: AppTypography.h5.copyWith(
          color: AppColors.light.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.light.surface,
        selectedItemColor: AppColors.light.primary,
        unselectedItemColor: AppColors.light.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      extensions: [AppColors.light],
    );
  }
}
