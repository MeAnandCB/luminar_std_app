import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart'; // Added import
import 'package:luminar_std/presentation/chat_screen/chat_screen.dart';
import 'package:luminar_std/presentation/course_screen/course_screen.dart';
import 'package:luminar_std/presentation/home_screen/home_screen.dart';
import 'package:luminar_std/presentation/more_menu/more_menu.dart';
import 'package:luminar_std/presentation/scan_screen/scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    StudentDashboard(), // Removed Center widget since StudentDashboard already has its own structure
    CourseDetailsScreen(),
    ScannerApp(),
    ContactListScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
          selectedLabelStyle: AppTextStyles.caption, // Using text style
          unselectedLabelStyle: AppTextStyles.caption, // Using text style
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
