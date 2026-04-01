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
                          AppUtils.friendlyError(dashboardProvider.error!).contains('internet')
                              ? Icons.wifi_off_rounded
                              : Icons.error_outline_rounded,
                          size: 72,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppUtils.friendlyError(dashboardProvider.error!).contains('internet')
                              ? 'No Internet Connection'
                              : 'Something Went Wrong',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headerName.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppUtils.friendlyError(dashboardProvider.error!),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.activitySubtitle,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => dashboardProvider.refreshDashboard(context: context),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(180, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ============== COURSE CARD SECTION WITH MULTIPLE ENROLLMENTS ==============

  Widget _buildCourseCard(Dashboard dashboard, EnrollmentProvider enrollments) {
    final enrollmentsList = dashboard.enrollmentDetails?.enrollments ?? [];

    if (enrollmentsList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("CURRENT ENROLLMENT", style: AppTextStyles.courseCardLabel),
            SizedBox(height: 8),
            Text('No Course Enrolled', style: AppTextStyles.courseCardTitle),
          ],
        ),
      );
    }

    // If only one enrollment, show single card (original design)
    if (enrollmentsList.length == 1) {
      final enrollment = enrollmentsList.first;
      return _buildSingleEnrollmentCard(enrollment, enrollments, 0);
    }

    // Multiple enrollments - show horizontal scrollable list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "YOUR ENROLLMENTS (${enrollmentsList.length})",
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
              ),
              // Scroll indicator dots
              Row(
                children: List.generate(
                  enrollmentsList.length > 3 ? 3 : enrollmentsList.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal scrollable list of enrollment cards
        SizedBox(
          height: 330, // Fixed height for horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: enrollmentsList.length,
            itemBuilder: (context, index) {
              final enrollment = enrollmentsList[index];
              return _buildEnrollmentCard(enrollment, index, enrollments);
            },
          ),
        ),
      ],
    );
  }

  // Single enrollment card — modern redesign
  Widget _buildSingleEnrollmentCard(
    enrollment,
    EnrollmentProvider provider,
    int index,
  ) {
    final enrollmentData = provider.enrollmentData;
    if (enrollmentData == null) return const SizedBox.shrink();

    final enrollments = enrollmentData.enrollments;
    if (index >= enrollments.length) return const SizedBox.shrink();

    final courseName =
        enrollment?.courseInfo?.courseName ??
        enrollment?.courseDetails?.toString() ??
        'No Course Enrolled';

    final batchName = enrollment?.batchInfo?.batchName ?? 'N/A';
    final startDate = enrollment?.batchInfo?.startDate;
    final attendanceMode = enrollment?.attendanceMode?.name ?? 'Hybrid';
    final attendanceModeValue = enrollment?.attendanceMode?.value ?? '';
    final progress = enrollment?.academicProgress?.completionPercentage ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5548D9), Color(0xFF6C5CE7), Color(0xFF9C8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background shapes
          Positioned(
            top: -30,
            right: -25,
            child: _buildDecorCircle(130, 0.08),
          ),
          Positioned(
            bottom: -40,
            left: -35,
            child: _buildDecorCircle(170, 0.06),
          ),
          Positioned(
            top: 65,
            right: 75,
            child: _buildDecorCircle(55, 0.07),
          ),
          Positioned(
            bottom: 35,
            right: 25,
            child: _buildDecorCircle(38, 0.05),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: label + mode badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabelChip('CURRENT ENROLLMENT'),
                    _buildModeBadge(attendanceModeValue, attendanceMode),
                  ],
                ),
                const SizedBox(height: 18),
                // Course icon + name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildCardInfoChip(Icons.group_rounded, batchName),
                    _buildCardInfoChip(
                      Icons.calendar_today_rounded,
                      _formatDate(startDate),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 14),
                // Progress row: label + bar + percentage badge
                Row(
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: progress / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$progress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom row: remaining chip + action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${100 - progress}% remaining',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap:
                          (enrollments[index].status.value ==
                                  "admission_fee_paid" ||
                              enrollments[index].status.value == "not_set" ||
                              enrollments[index].status.value == "demo_expired")
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnrollmentDetailsScreen(
                                    index: index,
                                    backbuttonValue: true,
                                  ),
                                ),
                              );
                            }
                          : () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BottomNavScreen(initialIndex: 3),
                                ),
                                (route) => false,
                              );
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Multiple enrollment card — modern redesign with index-based gradients
  Widget _buildEnrollmentCard(
    dynamic enrollment,
    int index,
    EnrollmentProvider enrollments,
  ) {
    final courseName =
        enrollment?.courseInfo?.courseName ??
        enrollment?.courseDetails?.toString() ??
        'No Course Enrolled';

    final batchName = enrollment?.batchInfo?.batchName ?? 'N/A';
    final startDate = enrollment?.batchInfo?.startDate;
    final attendanceMode = enrollment?.attendanceMode?.name ?? 'Hybrid';
    final attendanceModeValue = enrollment?.attendanceMode?.value ?? '';
    final progress = enrollment?.academicProgress?.completionPercentage ?? 0;

    final status =
        enrollments.enrollmentDataRes?.enrollments[index].status.value ?? "";
    final statusName =
        enrollments.enrollmentDataRes?.enrollments[index].status.name ?? "";

    // Index-based gradient palette
    const gradientSets = [
      [Color(0xFF5548D9), Color(0xFF8B7BF2)],
      [Color(0xFF0870C7), Color(0xFF3A9BD5)],
      [Color(0xFF00967A), Color(0xFF00C9A7)],
      [Color(0xFFB83280), Color(0xFFE91E8C)],
    ];
    final colors = gradientSets[index % gradientSets.length];

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -25, right: -20, child: _buildDecorCircle(110, 0.08)),
          Positioned(
            bottom: -30,
            left: -25,
            child: _buildDecorCircle(140, 0.06),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: # badge + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (statusName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
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
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(status),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Course icon + name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildCardInfoChip(Icons.group_rounded, batchName),
                    _buildCardInfoChip(
                      Icons.calendar_today_rounded,
                      _formatDate(startDate),
                    ),
                    _buildModeBadge(attendanceModeValue, attendanceMode),
                  ],
                ),
                const Spacer(),
                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$progress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap:
                          (enrollments
                                      .enrollmentDataRes
                                      ?.enrollments[index]
                                      .status
                                      .value ==
                                  "admission_fee_paid" ||
                              enrollments
                                      .enrollmentDataRes
                                      ?.enrollments[index]
                                      .status
                                      .value ==
                                  "not_set" ||
                              enrollments
                                      .enrollmentDataRes
                                      ?.enrollments[index]
                                      .status
                                      .value ==
                                  "demo_expired")
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnrollmentDetailsScreen(
                                    index: index,
                                    backbuttonValue: true,
                                  ),
                                ),
                              );
                            }
                          : () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BottomNavScreen(initialIndex: 3),
                                ),
                                (route) => false,
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: colors[0],
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: colors[0],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'admission_fee_paid':
        return AppColors.statsGreen;
      case 'pending':
      case 'not_set':
        return AppColors.statsOrange;
      case 'completed':
        return AppColors.statsBlue;
      case 'expired':
      case 'demo_expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  // ============== CARD HELPER WIDGETS ==============

  Widget _buildDecorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildModeBadge(String modeValue, String modeName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getAttendanceModeIcon(modeValue), size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            modeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAttendanceModeIcon(String value) {
    switch (value) {
      case 'online':
        return Icons.computer_rounded;
      case 'offline':
        return Icons.location_on_rounded;
      case 'hybrid':
        return Icons.sync_alt_rounded;
      case 'recording':
        return Icons.video_library_rounded;
      default:
        return Icons.school_rounded;
    }
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

  Widget _buildCourseInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 2, style: AppTextStyles.courseCardLabel),
        Text(value, style: AppTextStyles.courseCardValue),
      ],
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
