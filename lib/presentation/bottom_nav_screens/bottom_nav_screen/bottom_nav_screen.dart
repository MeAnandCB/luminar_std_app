import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/chat_screen/chat_screen.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/home_screen.dart';

import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollments.dart';
import 'package:luminar_std/presentation/more_enrollment_screen_bottom/more_entrollment_bottom.dart';
import 'package:luminar_std/presentation/scan_screen/scan_screen.dart';
import 'package:provider/provider.dart';

class BottomNavScreen extends StatefulWidget {
  final int initialIndex; // Add this

  const BottomNavScreen({
    super.key,
    this.initialIndex = 0, // Default to 0
  });

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late EnrollmentProvider enrollmentProvider;
  late int _currentIndex; // Make it late

  List<Widget> _pages = [
    const StudentDashboard(),
    const EnrollmentScreen(),
    const ScannerApp(),
    const ContactListScreen(),
    MoreEnrollmentScreen(),
    // const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Set from widget

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enrollmentProvider = Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      );
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await enrollmentProvider.fetchEnrollData(context: context);
    if (mounted) {
      _updatePages();
    }
  }

  void _updatePages() {
    if (enrollmentProvider.enrollmentDataRes != null) {
      setState(() {
        _pages = [
          const StudentDashboard(),
          enrollmentProvider.enrollmentDataRes!.enrollments.length == 1
              ? EnrollmentDetailsScreen(index: 0, backbuttonValue: false)
              : const EnrollmentScreen(),
          const ScannerApp(),
          const ContactListScreen(),
          const MoreEnrollmentScreen(),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if enrollmentProvider is initialized before using it
    // In your build method, you should use Provider.of directly instead
    final provider = Provider.of<EnrollmentProvider>(context);

    // Log safely
    if (provider.enrollmentDataRes != null) {
      log(provider.enrollmentDataRes!.enrollments.length.toString());
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: AppTextStyles.caption,
          unselectedLabelStyle: AppTextStyles.caption,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: "Course",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: "Scan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wechat_rounded),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_outlined),
              label: "More",
            ),
          ],
        ),
      ),
    );
  }
}
