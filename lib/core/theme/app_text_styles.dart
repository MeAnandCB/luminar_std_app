import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class AppTextStyles {
  // Splash Screen Text Styles
  static TextStyle tagline = TextStyle(
    fontSize: 14,
    color: AppColors.whiteWithOpacity90,
    fontWeight: FontWeight.w500,
  );

  static TextStyle version = TextStyle(
    fontSize: 12,
    color: AppColors.versionText,
  );

  // Dashboard Header Styles
  static const TextStyle headerName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Welcome Status
  static const TextStyle welcomeStatus = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.statusActive,
  );

  // Course Card Styles
  static const TextStyle courseCardLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite70,
  );

  static const TextStyle courseCardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle courseCardValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const TextStyle courseCardProgress = TextStyle(
    fontSize: 12,
    color: AppColors.textWhite70,
  );

  static const TextStyle courseCardButton = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // Stats Card Styles
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Section Title
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Activity List Styles
  static const TextStyle activityTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle activitySubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle activityTime = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  // Common Text Styles (for future use)
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
