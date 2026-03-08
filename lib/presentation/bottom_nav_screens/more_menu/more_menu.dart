import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

// Import your screens here
import 'package:luminar_std/presentation/attandance_screen/attandance_screen.dart';
import 'package:luminar_std/presentation/live_class/live_class.dart';
import 'package:luminar_std/presentation/payment_screen/payment_screen.dart';
import 'package:luminar_std/presentation/recorder_video_screen/recorder_video_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<MoreItem> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Navigation methods for each feature
  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceScreen(),
        settings: const RouteSettings(
          arguments: {
            'title': 'Attendance',
            'course': 'Asp.net MVC with Angular',
            'batch': 'ggf',
          },
        ),
      ),
    );
  }

  void _navigateToVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideosScreen(),
        settings: const RouteSettings(
          arguments: {
            'title': 'Videos',
            'course': 'Asp.net MVC with Angular',
            'batch': 'ggf',
            'videoCount': 24,
            'newVideos': 12,
          },
        ),
      ),
    );
  }

  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentsScreen(),
        settings: const RouteSettings(
          arguments: {
            'title': 'Payments',
            'amount': '₹27,000',
            'lastPayment': 'Mar 12, 2026',
            'status': 'Paid',
          },
        ),
      ),
    );
  }

  void _navigateToLiveClass() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveClassScreen(),
        settings: const RouteSettings(
          arguments: {
            'title': 'Live Class',
            'nextClass': 'Today 5:00 PM',
            'topic': 'ASP.NET MVC with Angular',
            'instructor': 'John Doe',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Simple Header without gradient and search
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Explore all features',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Main Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Quick Stats Row
                  // Removed as per your code, but keeping structure
                  const SizedBox(height: 28),

                  // Section Title
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance Card - Navigates to AttendanceScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.calendar_month,
                      title: 'Attendance',
                      subtitle: 'Track your daily attendance',
                      color: AppColors.primary,
                      badge: '85%',
                      stats: 'Present: 42 days',
                    ),
                    index: 0,
                    onTap: _navigateToAttendance,
                  ),

                  // Videos Card - Navigates to VideosScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.video_library_rounded,
                      title: 'Videos',
                      subtitle: 'Course recordings & lectures',
                      color: AppColors.statsGreen,
                      badge: '12 new',
                      stats: 'Total: 24 videos',
                    ),
                    index: 1,
                    onTap: _navigateToVideos,
                  ),

                  // Payments Card - Navigates to PaymentsScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.payment_rounded,
                      title: 'Payments',
                      subtitle: 'Fee details & transactions',
                      color: AppColors.statsOrange,
                      badge: 'Paid',
                      stats: 'Last: Mar 12, 2026',
                    ),
                    index: 2,
                    onTap: _navigateToPayments,
                  ),

                  // Live Class Card - Navigates to LiveClassScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.video_camera_front_rounded,
                      title: 'Live Class',
                      subtitle: 'Join ongoing sessions',
                      color: const Color(0xFFFF7675),
                      badge: 'LIVE NOW',
                      stats: 'Next: Today 5:00 PM',
                    ),
                    index: 3,
                    onTap: _navigateToLiveClass,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Function()? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.statValue.copyWith(fontSize: 14),
              ),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required MoreItem item,
    required int index,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _animationController.drive(
        CurveTween(curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color.withOpacity(0.2),
                          item.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.activityTitle,
                            ),
                            const SizedBox(width: 8),
                            if (item.badge.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.title == 'Live Class'
                                      ? const Color(0xFFFF7675)
                                      : item.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.badge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.title == 'Live Class'
                                        ? AppColors.white
                                        : item.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: AppTextStyles.activitySubtitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.stats,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(MoreItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 50),
              ),
              const SizedBox(height: 20),
              Text(item.title, style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'This feature is coming soon!',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening ${item.title}...'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.color,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badge;
  final String stats;

  MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badge,
    required this.stats,
  });
}
