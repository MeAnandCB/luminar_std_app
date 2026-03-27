import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class AppTextStyles {
  // Splash Screen Text Styles
  static TextStyle get tagline => TextStyle(
        fontSize: 14,
        color: AppColors.whiteWithOpacity90,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get version => TextStyle(
        fontSize: 12,
        color: AppColors.versionText,
      );

  // Dashboard Header Styles
  static TextStyle get headerName => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get headerSubtitle => TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  // Welcome Status
  static TextStyle get welcomeStatus => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.statusActive,
      );

  // Course Card Styles
  static TextStyle get courseCardLabel => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textWhite70,
      );

  static TextStyle get courseCardTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      );

  static TextStyle get courseCardValue => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      );

  static TextStyle get courseCardProgress => TextStyle(
        fontSize: 12,
        color: AppColors.textWhite70,
      );

  static TextStyle get courseCardButton => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      );

  // Stats Card Styles
  static TextStyle get statLabel => TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get statValue => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  // Section Title
  static TextStyle get sectionTitle => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  // Activity List Styles
  static TextStyle get activityTitle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get activitySubtitle => TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get activityTime => TextStyle(
        fontSize: 12,
        color: AppColors.textHint,
      );

  // Common Text Styles
  static TextStyle get heading1 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyText => TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyText1 => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyText2 => TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get subtitle1 => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get hintText => TextStyle(
        fontSize: 14,
        color: AppColors.textHint,
      );

  static TextStyle get buttonText => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );
}
