import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/chat_screen/chat_screen.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/home_screen.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/more_menu/more_menu.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollments.dart';
import 'package:luminar_std/presentation/scan_screen/scan_screen.dart';
import 'package:provider/provider.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late EnrollmentProvider enrollmentProvider; // This is fine
  int _currentIndex = 0;

  List<Widget> _pages = [
    const StudentDashboard(),
    const EnrollmentScreen(),
    const ScannerApp(),
    const ContactListScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // DON'T try to access enrollmentProvider here yet
    // Just schedule the post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Now it's safe to access Provider
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
          enrollmentProvider.enrollmentDataRes!.enrollments.isEmpty
              ? const EnrollmentScreen()
              : const EnrollmentDetailsScreen(
                  index: 0,
                  enrollmentId: "fc383b4e-5e24-4563-96c6-8f79a1ac5310",
                ),
          const ScannerApp(),
          const ContactListScreen(),
          const MoreScreen(),
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
