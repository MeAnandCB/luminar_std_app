import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = false;
  static bool get isDark => _isDark;

  static void updateTheme(bool dark) {
    _isDark = dark;
  }

  // Base Colors
  static Color get white => _isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get black => _isDark ? Colors.white : Colors.black;

  // Primary Palette (Luminar Purple)
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7BF2);
  static const Color primaryLighter = Color(0xFFA29BFE);

  // Background / Surface
  static Color get scaffoldBackground => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FF);
  static Color get cardBackground => _isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get surface => _isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F5F5);
  static Color get borderColor => _isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0);
  static Color get avatarBackground => _isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0);

  // Status Colors
  static const Color statusActive = Color(0xFF00B894);
  static Color get statusActiveBackground => _isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9);

  // Stats Colors
  static const Color statsBlue = Color(0xFF0984E3);
  static const Color statsGreen = Color(0xFF00B894);
  static const Color statsOrange = Color(0xFFF39C12);
  static const Color statsPurple = Color(0xFF6C5CE7);

  // Text Colors
  static Color get textPrimary => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF2D3436);
  static Color get textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF636E72);
  static Color get textHint => _isDark ? const Color(0xFF64748B) : const Color(0xFFB2BEC3);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7BF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient1 = LinearGradient(
    colors: [Color(0xFF8B7BF2), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> splashGradient = [Color(0xFF6C5CE7), Color(0xFF8B7BF2), Color(0xFFA29BFE)];

  static Color get info => const Color(0xFF0984E3);
  static Color get notificationGlow => const Color(0xFF6C5CE7);
  static Color get notificationIcon => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF2D3436);

  // Shadows
  static Color get shadowLight => _isDark ? Colors.black26 : const Color(0x1A000000);
  static const Color shadowSuccess = Color(0x4D00B09B);

  // Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Bottom Navigation Bar Colors
  static Color get bottomNavBackground => _isDark ? const Color(0xFF1E293B) : Colors.white;
  static const Color bottomNavSelected = Color(0xFF6C5CE7);
  static Color get bottomNavUnselected => _isDark ? const Color(0xFF64748B) : const Color(0xFFB2BEC3);

  // White Variants (methods to maintain compatibility)
  static Color get whiteWithOpacity10 => white.withOpacity(0.1);
  static Color get whiteWithOpacity20 => white.withOpacity(0.2);
  static Color get whiteWithOpacity30 => white.withOpacity(0.3);
  static Color get whiteWithOpacity50 => white.withOpacity(0.5);
  static Color get whiteWithOpacity70 => white.withOpacity(0.7);
  static Color get whiteWithOpacity80 => white.withOpacity(0.8);
  static Color get whiteWithOpacity90 => white.withOpacity(0.9);

  // Background Shapes
  static Color shapeBackground(double opacity) {
    return white.withOpacity(opacity);
  }

  // Particle Colors
  static Color get particle => white.withOpacity(0.3);

  // Loading Indicator
  static Color get loadingBackground => white.withOpacity(0.2);
  static Color get loadingProgress => white;
  static Color get loadingShadow => white.withOpacity(0.5);

  // Border Colors
  static Color get borderLight => white.withOpacity(0.3);
  static Color get borderLighter => white.withOpacity(0.5);

  // Version Text
  static Color get versionText => white.withOpacity(0.5);

  static const Color error = Color(0xFFD32F2F);

  // Dark Mode Colors (Keeping for backward compatibility if needed, though getters are better)
  static const Color darkScaffoldBackground = Color(0xFF0F172A);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorderColor = Color(0xFF334155);
  static const Color darkSurface = Color(0xFF1E293B);
}
