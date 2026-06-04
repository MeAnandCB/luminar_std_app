import 'package:luminar_std/core/constants/app_config.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/chat_list_screen/chat_list_screen.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/home_screen/home_screen.dart';
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

class _BottomNavScreenState extends State<BottomNavScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _currentIndex;
  late ChatProvider _chatProvider;
  bool _chatInitialized = false;

  // Animation controller for FAB press feedback
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
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

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _loadData();
      // Handle notifications after the navigator is mounted
      FCMService().processPendingNavigation();
      FCMService().handleInitialMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh dashboard when app comes back to foreground so
      // new exams / jobs added on the backend are reflected immediately
      Provider.of<DashboardController>(context, listen: false)
          .getDashboardData(context: context, forceRefresh: true);
    }
  }

  Future<void> _loadData() async {
    final dashboardController = Provider.of<DashboardController>(context, listen: false);
    await dashboardController.getDashboardData(context: context);
    await dashboardController.getNactetStatus();
    // Show badge count without loading full chat list
    _chatProvider.fetchUnreadCountOnly();
    if (mounted) setState(() {});
  }

  void _navigateToScanner() async {
    await _fabController.forward();
    await _fabController.reverse();
    if (!mounted) return;

    final dashboardController = Provider.of<DashboardController>(context, listen: false);
    final enrollments = dashboardController.dashboard?.enrollmentDetails?.enrollments ?? [];
    final bool accessDenied = enrollments.isNotEmpty &&
        enrollments.every((e) => e.basicInfo?.crmAccess == false);

    if (accessDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 8),
              const Text('Access Denied'),
            ],
          ),
          content: const Text(
            'Your access was denied. Please contact your academic counselor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
  }

  // Cached pages — built once so initState is not re-triggered on every rebuild
  List<Widget>? _cachedPages;
  bool _showPaymentScreen = false;

  List<Widget> _getPages() {
    if (_cachedPages != null) return _cachedPages!;
    _cachedPages = [
      const StudentDashboard(),
      _showPaymentScreen ? EnrollmentDetailsScreen(index: 0, backbuttonValue: false) : const EnrollmentScreen(),
      const ChatListScreen(),
      const MoreEnrollmentScreen(),
    ];
    return _cachedPages!;
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    context.watch<ThemeProvider>();
    final unreadCount = chatProv.totalUnreadCount;
    final unreadExams = context.select<DashboardController, int>((c) => c.unreadExamsCount);
    final unviewedJobs = context.select<DashboardController, int>((c) => c.unviewedJobNotificationsCount);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Use dashboard enrollment status — no separate enrollment API call needed
    final dashEnrollments = context.select<DashboardController, List>(
      (c) => c.dashboard?.enrollmentDetails?.enrollments ?? [],
    );
    if (dashEnrollments.isNotEmpty) {
      LoggerUtils.debug(dashEnrollments.length.toString(), tag: 'BottomNav');
      final status = dashEnrollments[0].status?.value ?? '';
      final isPaymentPending = status == 'not_set' || status == 'demo_expired' || status == 'admission_fee_paid';
      final newShowPayment = isPaymentPending && !AppConfig.hidePayments;
      if (newShowPayment != _showPaymentScreen) {
        _showPaymentScreen = newShowPayment;
        _cachedPages = null;
      }
    }

    final pages = _getPages();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ★ Creative FAB — larger, with ring glow
      floatingActionButton: isKeyboardOpen ? null : ScaleTransition(
        scale: _fabScale,
        child: GestureDetector(
          onTap: _navigateToScanner,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha:0.95), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // Double ring effect
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha:0.45),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha:0.15),
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
      bottomNavigationBar: _buildBottomNav(unreadCount, unreadExams, unviewedJobs),
    );
  }

  Widget _buildBottomNav(int unreadCount, int unreadExams, int unviewedJobs) {
    return Container(
      // ★ Smaller height than default BottomAppBar
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 20, offset: const Offset(0, -4))],
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
              child: Container(height: 0.5, color: AppColors.borderColor.withValues(alpha:0.4)),
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
                        _buildNavItem(3, Icons.menu_rounded, 'More', badgeCount: unreadExams + unviewedJobs),
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
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 2) {
          if (!_chatInitialized) {
            _chatInitialized = true;
            _chatProvider.init();
          } else {
            _chatProvider.loadChats(showLoading: false);
          }
        }
        // Refresh dashboard counts when switching to More tab
        // so new exams/jobs from the backend are reflected immediately
        if (index == 3) {
          Provider.of<DashboardController>(context, listen: false)
              .getDashboardData(context: context, forceRefresh: true);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha:0.10) : Colors.transparent,
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
