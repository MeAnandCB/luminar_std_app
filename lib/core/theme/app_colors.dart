import 'package:flutter/material.dart';

class AppColors {
  // White Color
  static const Color white = Colors.white;

  // Splash Screen Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7BF2);
  static const Color primaryLighter = Color(0xFFA29BFE);

  // Dashboard Colors
  static const Color scaffoldBackground = Color.fromARGB(255, 255, 255, 255);
  static const Color cardBackground = Colors.white;
  static const Color avatarBackground = Color(0xFFE0E0E0);

  // Status Colors
  static const Color statusActive = Color(0xFF00B894);
  static const Color statusActiveBackground = Color(0xFFE8F5E9);

  // Stats Colors
  static const Color statsBlue = Color(0xFF0984E3);
  static const Color statsGreen = Color(0xFF00B894);
  static const Color statsOrange = Color(0xFFF39C12);
  static const Color statsPurple = Color(0xFF6C5CE7);

  // Info Colors
  static const Color info = Color(0xFF0984E3);

  // Notification Colors
  static const Color notificationGlow = Color(0xFF6C5CE7);
  static const Color notificationIcon = Color(0xFF2D3436);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7BF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const List<Color> splashGradient = [
    Color(0xFF6C5CE7),
    Color(0xFF8B7BF2),
    Color(0xFFA29BFE),
  ];

  // Shadows
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowSuccess = Color(0x4D00B09B);

  // Bottom Navigation Bar Colors
  static const Color bottomNavBackground = Colors.white;
  static const Color bottomNavSelected = Color(0xFF6C5CE7);
  static const Color bottomNavUnselected = Color(0xFFB2BEC3);

  // White Variants (methods to maintain compatibility)
  static Color whiteWithOpacity10 = Colors.white.withOpacity(0.1);
  static Color whiteWithOpacity20 = Colors.white.withOpacity(0.2);
  static Color whiteWithOpacity30 = Colors.white.withOpacity(0.3);
  static Color whiteWithOpacity50 = Colors.white.withOpacity(0.5);
  static Color whiteWithOpacity70 = Colors.white.withOpacity(0.7);
  static Color whiteWithOpacity80 = Colors.white.withOpacity(0.8);
  static Color whiteWithOpacity90 = Colors.white.withOpacity(0.9);

  // Background Shapes
  static Color shapeBackground(double opacity) {
    return Colors.white.withOpacity(opacity);
  }

  // Particle Colors
  static Color particle = Colors.white.withOpacity(0.3);

  // Loading Indicator
  static Color loadingBackground = Colors.white.withOpacity(0.2);
  static Color loadingProgress = Colors.white;
  static Color loadingShadow = Colors.white.withOpacity(0.5);

  // Border Colors
  static Color borderLight = Colors.white.withOpacity(0.3);
  static Color borderLighter = Colors.white.withOpacity(0.5);

  // Version Text
  static Color versionText = Colors.white.withOpacity(0.5);

  // Add these to your existing AppColors class
  static const Color surface = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);

  static const Color error = Color(0xFFD32F2F);
}
