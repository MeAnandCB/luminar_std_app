import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_images.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_sizing.dart';
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
    Center(child: StudentDashboard()),
    Center(child: CourseDetailsScreen()),

    Center(child: ScannerApp()),
    Center(child: ContactListScreen()),
    Center(child: MoreScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppSizing.verticalSpacing12,
            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: 16.0,
            //     vertical: 10,
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Container(
            //         height: 70,
            //         width: MediaQuery.sizeOf(context).width * 0.4,
            //         child: Image.asset(AppImages.logo1, fit: BoxFit.fitWidth),
            //       ),
            //       Row(
            //         children: [
            //           IconButton(
            //             icon: Icon(
            //               color: Theme.of(context).colorScheme.onBackground,
            //               themeProvider.isDarkMode
            //                   ? Icons.light_mode
            //                   : Icons.dark_mode,
            //             ),
            //             onPressed: () {
            //               themeProvider.toggleTheme();
            //             },
            //           ),

            //           CircleAvatar(
            //             backgroundColor: Colors.grey.shade300,
            //             child: Icon(
            //               Icons.person,
            //               color: Theme.of(context).primaryColor,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
    );
  }
}
