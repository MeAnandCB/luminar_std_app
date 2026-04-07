import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/chat_list_screen/chat_list_screen.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/home_screen/home_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollments.dart';
import 'package:luminar_std/presentation/more_enrollment_screen_bottom/more_entrollment_bottom.dart';
import 'package:luminar_std/presentation/scan_screen/scan_screen.dart';
import 'package:luminar_std/repository/FCM/fcm_service.dart';
import 'package:provider/provider.dart';

class BottomNavScreen extends StatefulWidget {
  final int initialIndex;

  const BottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> with SingleTickerProviderStateMixin {
  late EnrollmentProvider enrollmentProvider;
  late ChatProvider chatProvider;
  late int _currentIndex;

  // Animation controller for FAB press feedback
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    // 1. Handle terminated state FCM deep-linking
    FCMService().handleInitialMessage();
    _currentIndex = widget.initialIndex;

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
      chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _loadData();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await enrollmentProvider.fetchEnrollData(context: context);
    chatProvider.init();
    if (mounted) setState(() {});
  }

  void _navigateToScanner() async {
    await _fabController.forward();
    await _fabController.reverse();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
  }

  List<Widget> _buildPages(EnrollmentProvider provider) {
    if (provider.enrollmentDataRes == null) {
      return [StudentDashboard(), EnrollmentScreen(), ChatListScreen(), MoreEnrollmentScreen()];
    }

    final status = provider.enrollmentDataRes!.enrollments[0].status.value;
    final isPaymentPending = status == 'not_set' || status == 'demo_expired' || status == 'admission_fee_paid';

    return [
      StudentDashboard(),
      isPaymentPending ? EnrollmentDetailsScreen(index: 0, backbuttonValue: false) : EnrollmentScreen(),
      ChatListScreen(),
      MoreEnrollmentScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentProvider>(context);
    final chatProv = context.watch<ChatProvider>();
    context.watch<ThemeProvider>();
    final unreadCount = chatProv.totalUnreadCount;

    if (provider.enrollmentDataRes != null) {
      LoggerUtils.debug(provider.enrollmentDataRes!.enrollments.length.toString(), tag: 'BottomNav');
    }

    final pages = _buildPages(provider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(child: pages[_currentIndex]),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ★ Creative FAB — larger, with ring glow
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: GestureDetector(
          onTap: _navigateToScanner,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.95), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // Double ring effect
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 0,
                  spreadRadius: 6,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),

      // ★ Creative bottom nav — compact, pill highlights, no Divider
      bottomNavigationBar: _buildBottomNav(unreadCount),
    );
  }

  Widget _buildBottomNav(int unreadCount) {
    return Container(
      // ★ Smaller height than default BottomAppBar
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          children: [
            // Subtle top separator line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 0.5, color: AppColors.borderColor.withOpacity(0.4)),
            ),

            // Nav row with notch gap in center
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left two items
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, 'Home'),
                        _buildNavItem(1, Icons.grid_view_rounded, 'Course'),
                      ],
                    ),
                  ),

                  // Center gap for FAB
                  const SizedBox(width: 64),

                  // Right two items
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(2, Icons.wechat_rounded, 'Chat', badgeCount: unreadCount),
                        _buildNavItem(3, Icons.menu_rounded, 'More'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ Creative nav item — active state gets a pill background + coloured icon
  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;

    final iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: Icon(
        icon,
        key: ValueKey(isSelected),
        color: isSelected ? AppColors.primary : AppColors.textHint,
        size: 22,
      ),
    );

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                iconWidget,
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textHint,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
