import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/chat_list_screen/chat_list_screen.dart';
import 'package:luminar_std/presentation/home_screen/home_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollments.dart';
import 'package:luminar_std/presentation/more_enrollment_screen_bottom/more_entrollment_bottom.dart';
import 'package:luminar_std/presentation/scan_screen/scan_screen.dart';
import 'package:provider/provider.dart';

class BottomNavScreen extends StatefulWidget {
  final int initialIndex;

  const BottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late EnrollmentProvider enrollmentProvider;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await enrollmentProvider.fetchEnrollData(context: context);
    if (mounted) setState(() {});
  }

  void _navigateToScanner() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerApp()));
  }

  /// Pages are built here (not stored as state) so every build() call
  /// picks up the freshly-read AppColors after a theme change.
  List<Widget> _buildPages(EnrollmentProvider provider) {
    if (provider.enrollmentDataRes == null) {
      return [
        StudentDashboard(),
        EnrollmentScreen(),
        ChatListScreen(),
        MoreEnrollmentScreen(),
      ];
    }

    final status = provider.enrollmentDataRes!.enrollments[0].status.value;
    final isPaymentPending =
        status == 'not_set' || status == 'demo_expired' || status == 'admission_fee_paid';

    return [
      StudentDashboard(),
      isPaymentPending
          ? EnrollmentDetailsScreen(index: 0, backbuttonValue: false)
          : EnrollmentScreen(),
      ChatListScreen(),
      MoreEnrollmentScreen(),
    ];
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textHint,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentProvider>(context);
    // Subscribe to theme changes so the entire widget rebuilds with fresh AppColors
    context.watch<ThemeProvider>();

    if (provider.enrollmentDataRes != null) {
      LoggerUtils.debug(
        provider.enrollmentDataRes!.enrollments.length.toString(),
        tag: 'BottomNav',
      );
    }

    final pages = _buildPages(provider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(child: pages[_currentIndex]),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScanner,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),

      bottomNavigationBar: BottomAppBar(
        color: AppColors.cardBackground,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, 0, Icons.home, "Home"),
                      _buildNavItem(context, 1, Icons.grid_view_rounded, "Course"),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, 2, Icons.wechat_rounded, "Chat"),
                      _buildNavItem(context, 3, Icons.menu_outlined, "More"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
