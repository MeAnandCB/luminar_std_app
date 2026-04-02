import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:luminar_std/presentation/home_screen/widget/natet_certificate.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/home_screen/widget/header_card.dart';
import 'package:luminar_std/presentation/home_screen/widget/top_status_card.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/instagram_view_screen.dart';
import 'package:luminar_std/presentation/nactet_registration/view/nactet_registration_screen.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _displayName = 'Loading...';
  late EnrollmentProvider _enrollmentProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final dashboardProvider = Provider.of<DashboardController>(
        context,
        listen: false,
      );
      await dashboardProvider.getDashboardData(context: context);
      await dashboardProvider.getNactetStatus();
      _loadUserName();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enrollmentProvider = Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      );
      _loadData();
    });
  }

  Future<void> _loadUserName() async {
    // Add a small delay to ensure provider is ready
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final name = authProvider.studentData?.profile.fullName ?? 'Guest';
      setState(() {
        _displayName = name;
      });
      LoggerUtils.info('📝 Name loaded: $_displayName', tag: 'Dashboard');
    }
  }

  String _formatCurrency(int? amount) {
    if (amount == null) return '₹0';
    return '₹${NumberFormat('#,##,###').format(amount)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _loadData() async {
    await _enrollmentProvider.fetchEnrollData(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardController>(context);
    final dashboard = dashboardProvider.dashboard;
    final provider = Provider.of<EnrollmentProvider>(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Get student name from provider
        final studentName = authProvider.studentData?.profile.fullName ?? '';

        // Update display name if different
        if (studentName.isNotEmpty && studentName != _displayName) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _displayName = studentName;
            });
          });
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: dashboardProvider.isLoading
              ? const DashboardShimmer()
              : dashboardProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppUtils.friendlyError(
                                dashboardProvider.error!,
                              ).contains('internet')
                              ? Icons.wifi_off_rounded
                              : Icons.error_outline_rounded,
                          size: 72,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppUtils.friendlyError(
                                dashboardProvider.error!,
                              ).contains('internet')
                              ? 'No Internet Connection'
                              : 'Something Went Wrong',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headerName.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppUtils.friendlyError(dashboardProvider.error!),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.activitySubtitle,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => dashboardProvider.refreshDashboard(
                            context: context,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(180, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderWidget(
                        enrolldata: provider,
                        studentName: studentName,
                        provider: dashboardProvider,
                      ),
                      const SizedBox(height: 12),
                      StatusCard(
                        status:
                            dashboard
                                ?.studentDetails
                                ?.statusInfo
                                ?.currentStatus
                                ?.name ??
                            'Active',
                      ),
                      const SizedBox(height: 28),
                      _buildSectionHeading(
                        'My Courses',
                        'Your active enrollments',
                      ),
                      const SizedBox(height: 14),
                      if (dashboard != null) ...[
                        _buildCourseCard(dashboard, provider),
                        if (dashboardProvider.shouldShowNactetBanner) ...[
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            'NACTET Registration',
                            'Complete your registration below',
                          ),
                          const SizedBox(height: 14),
                          NactetBanner(
                            pendingCount: dashboardProvider.pendingNactetCount,
                            onFormTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NactetRegistrationScreen(),
                                ),
                              );
                            },
                          ),
                        ] else if (dashboardProvider.nactetStatusReason !=
                            null) ...[
                          const SizedBox(height: 28),
                          _buildSectionHeading('NACTET Status', null),
                          const SizedBox(height: 14),
                          _buildNactetStatusCard(
                            dashboardProvider.nactetStatusReason!,
                          ),
                        ],
                        const SizedBox(height: 28),
                        _buildSectionHeading(
                          'Financial Overview',
                          'Fees & payment summary',
                        ),
                        const SizedBox(height: 14),
                        _buildQuickStatsGrid(dashboard),
                        const SizedBox(height: 28),
                        _buildSectionHeading(
                          'Latest Updates',
                          'News & announcements',
                        ),
                        const SizedBox(height: 14),
                        const AdvancedInstaCarousel(),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ============== COURSE CARD SECTION ==============

  Widget _buildCourseCard(Dashboard dashboard, EnrollmentProvider enrollments) {
    final enrollmentsList = dashboard.enrollmentDetails?.enrollments ?? [];

    if (enrollmentsList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CURRENT ENROLLMENT', style: AppTextStyles.courseCardLabel),
            const SizedBox(height: 8),
            Text('No Course Enrolled', style: AppTextStyles.courseCardTitle),
          ],
        ),
      );
    }

    return _EnrollmentCardStack(
      enrollments: enrollmentsList,
      provider: enrollments,
      studentName: _displayName,
    );
  }

  // ============== EXISTING METHODS (KEPT EXACTLY AS THEY WERE) ==============

  Widget _buildQuickStatsGrid(Dashboard dashboard) {
    final financial = dashboard.financialSummary?.overview;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              "Total Fees",
              _formatCurrency(financial?.totalFeesAmount),
              Icons.account_balance_wallet,
              AppColors.statsBlue,
            ),
            _buildStatCard(
              "Paid",
              _formatCurrency(financial?.totalFeesPaid),
              Icons.check_circle,
              AppColors.statsGreen,
            ),
            _buildStatCard(
              "Pending",
              _formatCurrency(financial?.totalFeesPending),
              Icons.pending_actions,
              AppColors.statsOrange,
            ),
            _buildStatCard(
              "Progress",
              "${financial?.paymentCompletionPercentage ?? 0}%",
              Icons.speed,
              AppColors.statsPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.statLabel),
              Text(value, style: AppTextStyles.statValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, [String? subtitle]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: subtitle != null ? 42 : 26,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActivityList(Dashboard dashboard) {
    final activities = dashboard.recentActivities?.recentActivities ?? [];

    if (activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No recent activities',
            style: AppTextStyles.activitySubtitle,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 4 ? 4 : activities.length,
      separatorBuilder: (context, index) =>
          Divider(color: AppColors.borderColor.withOpacity(0.5)),
      itemBuilder: (context, index) {
        final item = activities[index];

        IconData getIconForType(String? type) {
          switch (type) {
            case 'payment':
              return Icons.payment;
            case 'enrollment':
              return Icons.app_registration;
            case 'academic':
              return Icons.school;
            default:
              return Icons.notifications_none;
          }
        }

        Color getColorForPriority(String? priority) {
          switch (priority?.toLowerCase()) {
            case 'high':
              return Colors.red;
            case 'medium':
              return Colors.orange;
            case 'low':
              return Colors.green;
            default:
              return AppColors.info;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: getColorForPriority(
                item.priority?.toString(),
              ).withOpacity(0.1),
              child: Icon(
                getIconForType(item.type),
                color: getColorForPriority(item.priority?.toString()),
                size: 20,
              ),
            ),
            title: Text(
              item.title ?? 'Activity',
              style: AppTextStyles.activityTitle.copyWith(fontSize: 14),
            ),
            subtitle: Text(
              item.description ?? '',
              style: AppTextStyles.activitySubtitle.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.amount != null)
                  Text(
                    _formatCurrency(item.amount),
                    style: AppTextStyles.statValue.copyWith(
                      fontSize: 12,
                      color: AppColors.statsGreen,
                    ),
                  ),
                Text(
                  _formatDateForActivity(item.date),
                  style: AppTextStyles.activityTime,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateForActivity(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildNactetStatusCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_rounded, color: AppColors.info, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NACTET Update',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Horizontal Swipe Credit-Card Enrollment Widget
// ============================================================

class _EnrollmentCardStack extends StatefulWidget {
  final List enrollments;
  final EnrollmentProvider provider;
  final String studentName;

  const _EnrollmentCardStack({
    required this.enrollments,
    required this.provider,
    required this.studentName,
  });

  @override
  State<_EnrollmentCardStack> createState() => _EnrollmentCardStackState();
}

class _EnrollmentCardStackState extends State<_EnrollmentCardStack>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Per-card tap ripple controllers
  final Map<int, AnimationController> _rippleControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onScroll);
  }

  AnimationController _getRipple(int index) {
    return _rippleControllers.putIfAbsent(
      index,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onScroll() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage && mounted) {
      setState(() => _currentPage = newPage);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    for (final c in _rippleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card PageView ─────────────────────────────────────
        SizedBox(
          height: 310,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.enrollments.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (ctx, child) {
                  double offset = 0.0;
                  if (_pageController.position.haveDimensions) {
                    offset = _pageController.page! - index;
                  }
                  // Active card full size; side cards shrink + drop
                  final scale = (1.0 - offset.abs() * 0.06).clamp(0.88, 1.0);
                  final translateY = offset.abs() * 12;
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: child,
                    ),
                  );
                },
                child: _buildEnrollmentCard(context, index),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── Bottom row: count + dots + swipe hint ─────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} of ${widget.enrollments.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // Animated pill dots
              if (widget.enrollments.length > 1)
                Row(
                  children: List.generate(
                    widget.enrollments.length.clamp(0, 6),
                    (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),

              // Swipe hint
              Row(
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'swipe',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Enrollment Card  (premium redesign)
  // ════════════════════════════════════════════════════════════

  Widget _buildEnrollmentCard(BuildContext context, int index) {
    final enrollment = widget.enrollments[index];
    final provider = widget.provider;

    const cardPalettes = [
      [
        Color(0xFF3D1FA3),
        Color(0xFF6C5CE7),
        Color(0xFF9B8FFF),
      ], // Luminar Purple
      [Color(0xFF0A3D62), Color(0xFF1565C0), Color(0xFF42A5F5)], // Royal Blue
      [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF26A69A)], // Teal
      [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)], // Violet
      [Color(0xFF7B1A1A), Color(0xFFC62828), Color(0xFFEF5350)], // Crimson
    ];
    final palette = cardPalettes[index % cardPalettes.length];
    final accentColor = palette[2];

    final courseName =
        enrollment?.courseInfo?.courseName ?? 'No Course Enrolled';
    final batchName = enrollment?.batchInfo?.batchName ?? 'N/A';
    final startDate = enrollment?.batchInfo?.startDate;
    final enrollCount = provider.enrollmentDataRes?.enrollments.length ?? 0;
    final status = enrollCount > index
        ? provider.enrollmentDataRes!.enrollments[index].status
        : null;
    final isNavigatable =
        status?.value == 'admission_fee_paid' ||
        status?.value == 'not_set' ||
        status?.value == 'demo_expired';

    final ripple = _getRipple(index);

    void navigate() {
      ripple.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (isNavigatable) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EnrollmentDetailsScreen(index: index, backbuttonValue: true),
            ),
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BottomNavScreen(initialIndex: 3)),
            (route) => false,
          );
        }
      });
    }

    return GestureDetector(
      onTap: navigate,
      child: AnimatedBuilder(
        animation: ripple,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - ripple.value * 0.016, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: palette[0].withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Decorative blobs ──────────────────────────
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // ── Main content ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header: logo + brand + status ────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://d3eqn3hw2x95rk.cloudfront.net/seo/og_images/logo_without_divide_page-0001.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.school_rounded,
                                  color: palette[0],
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LUMINAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Training Institute',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    status.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Gradient divider ──────────────────────
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Course row ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COURSE',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  courseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Batch + Start date ────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _cardInfoTile(
                              icon: Icons.group_outlined,
                              label: 'BATCH',
                              value: batchName,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _cardInfoTile(
                              icon: Icons.calendar_month_outlined,
                              label: 'STARTS',
                              value: startDate != null
                                  ? '${_monthName(startDate.month)} ${startDate.year}'
                                  : 'N/A',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Continue button ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: navigate,
                          icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Continue Learning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: palette[0],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
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

  // ── Helpers ───────────────────────────────────────────────

  Widget _cardInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

// ── CustomPainters ────────────────────────────────────────────

/// Gold chip circuit lines
class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC09000).withValues(alpha: 0.5)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.82,
        height: size.height * 0.78,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rRect, paint);
    // Vertical centre line
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.39),
      Offset(cx, cy + size.height * 0.39),
      paint,
    );
    // Two horizontal lines
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy - size.height * 0.12),
      Offset(cx + size.width * 0.35, cy - size.height * 0.12),
      paint,
    );
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy + size.height * 0.12),
      Offset(cx + size.width * 0.35, cy + size.height * 0.12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Subtle dot-grid texture for card background
