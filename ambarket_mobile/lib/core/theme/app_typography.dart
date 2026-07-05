import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme getLightTextTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme getDarkTextTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        color: AppColors.textPrimaryDark,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.inter(
        color: AppColors.textPrimaryDark,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        color: AppColors.textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
