import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/widget/natet_certificate.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/widget/header_card.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/widget/top_status_card.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/instagram_view_screen.dart';
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
      await Provider.of<DashboardController>(
        context,
        listen: false,
      ).getDashboardData(context: context);
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
      print('📝 Name loaded: $_displayName');
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
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading dashboard',
                          style: AppTextStyles.headerName.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dashboardProvider.error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.activitySubtitle,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            dashboardProvider.refreshDashboard(
                              context: context,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 45),
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderWidget(
                        enrolldata: provider,
                        studentName: studentName,
                        provider: dashboardProvider,
                      ),
                      StatusCard(
                        status:
                            dashboard
                                ?.studentDetails
                                ?.statusInfo
                                ?.currentStatus
                                ?.name ??
                            'Active',
                      ),

                      const SizedBox(height: 20),
                      Center(child: _buildSectionTitle("Course Details")),

                      const SizedBox(height: 10),
                      if (dashboard != null) ...[
                        _buildCourseCard(dashboard, provider),
                        const SizedBox(height: 24),

                        _buildQuickStatsGrid(dashboard),
                        const SizedBox(height: 20),
                        Center(
                          child: _buildSectionTitle("NACTET Registration"),
                        ),
                        const SizedBox(height: 10),
                        const SimpleNactetListTile(),
                        const SizedBox(height: 10),

                        const AdvancedInstaCarousel(),
                        const SizedBox(height: 24),
                        // _buildSectionTitle("Recent Activities"),
                        // const SizedBox(height: 12),
                        // _buildActivityList(dashboard),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
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
          padding: const EdgeInsets.only(left: 4, bottom: 12),
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
                    margin: const EdgeInsets.only(right: 4),
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
          height: 280, // Fixed height for horizontal list
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

  // Original single enrollment card design (exactly as you had it)
  Widget _buildSingleEnrollmentCard(
    enrollment,
    EnrollmentProvider provider,
    int index,
  ) {
    final enrollments = provider.enrollmentData!.enrollments;
    final courseName =
        enrollment?.courseInfo?.courseName ??
        enrollment?.courseDetails?.toString() ??
        'No Course Enrolled';

    final batchName =
        enrollment?.batchInfo?.batchName?.toString().replaceAll(
          'BatchName.',
          '',
        ) ??
        'N/A';

    final startDate = enrollment?.batchInfo?.startDate;
    final attendanceMode = enrollment?.attendanceMode?.name ?? 'Hybrid';
    final progress = enrollment?.academicProgress?.completionPercentage ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CURRENT ENROLLMENT",
            style: AppTextStyles.courseCardLabel,
          ),
          const SizedBox(height: 8),
          Text(
            courseName,
            style: AppTextStyles.courseCardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseInfoItem("Batch", batchName),
              _buildCourseInfoItem("Starts", _formatDate(startDate)),
              _buildCourseInfoItem("Mode", attendanceMode),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            minHeight: 8,
            value: progress / 100,
            backgroundColor: AppColors.whiteWithOpacity20,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Progress: ${progress}%',
            style: AppTextStyles.courseCardProgress,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap:
                    (enrollments[index].status.value == "admission_fee_paid" ||
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSuccess,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.textWhite,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Continue Learning',
                        style: AppTextStyles.courseCardButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Multiple enrollment card design (keeping your original styling)
  Widget _buildEnrollmentCard(
    dynamic enrollment,
    int index,
    EnrollmentProvider enrollments,
  ) {
    // Show enrollments

    final courseName =
        enrollment?.courseInfo?.courseName ??
        enrollment?.courseDetails?.toString() ??
        'No Course Enrolled';

    final batchName =
        enrollment?.batchInfo?.batchName?.toString().replaceAll(
          'BatchName.',
          '',
        ) ??
        'N/A';

    final startDate = enrollment?.batchInfo?.startDate;
    final attendanceMode = enrollment?.attendanceMode?.name ?? 'Hybrid';
    final progress = enrollment?.academicProgress?.completionPercentage ?? 0;

    // Get enrollment status if available
    final status =
        enrollments.enrollmentDataRes?.enrollments[index].status.value ?? "";

    return Container(
      width: 300, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enrollment number indicator (subtle, not changing your design much)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.whiteWithOpacity20,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Optional status badge if available
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Keep your original course title styling
          Text(
            courseName,
            style: AppTextStyles.courseCardTitle.copyWith(
              fontSize: 16, // Slightly smaller for multiple cards
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Course details in row (keeping your layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseInfoItem("Batch", batchName),
              _buildCourseInfoItem("Starts", _formatDate(startDate)),
              _buildCourseInfoItem("Mode", attendanceMode),
            ],
          ),

          const Spacer(),

          // Progress section (keeping your styling)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                minHeight: 6,
                value: progress / 100,
                backgroundColor: AppColors.whiteWithOpacity20,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress: ${progress}%',
                style: AppTextStyles.courseCardProgress.copyWith(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 12),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSuccess,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.textWhite,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Continue Learning',
                        style: AppTextStyles.courseCardButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        return Colors.green;
      case 'pending':
      case 'not_set':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'expired':
      case 'demo_expired':
        return Colors.red;
      default:
        return Colors.grey;
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
      padding: const EdgeInsets.all(16),
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
        Text(label, style: AppTextStyles.courseCardLabel),
        Text(value, style: AppTextStyles.courseCardValue),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.sectionTitle);
  }

  Widget _buildActivityList(Dashboard dashboard) {
    final activities = dashboard.recentActivities?.recentActivities ?? [];

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
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
          const Divider(color: Color.fromARGB(255, 239, 239, 239)),
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
}
