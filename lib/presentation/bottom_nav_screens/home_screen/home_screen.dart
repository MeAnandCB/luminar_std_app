import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardController>(context);
    final dashboard = dashboardProvider.dashboard;

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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        _buildCourseCard(dashboard),
                        const SizedBox(height: 24),
                        _buildQuickStatsGrid(dashboard),
                        const SizedBox(height: 20),
                        Center(
                          child: _buildSectionTitle("Our  Success Stories"),
                        ),
                        const SizedBox(height: 10),
                        InstaCarousel(),
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

  Widget _buildQuickStatsGrid(Dashboard dashboard) {
    final financial = dashboard.financialSummary?.overview;
    final academic = dashboard.quickStats?.academic;

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

  Widget _buildCourseCard(Dashboard dashboard) {
    final enrollment =
        dashboard.enrollmentDetails?.enrollments?.isNotEmpty == true
        ? dashboard.enrollmentDetails!.enrollments!.first
        : null;

    final courseName =
        enrollment?.courseInfo?.courseName ??
        dashboard.courseDetails?.toString() ??
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
            value:
                dashboard
                    .academicProgress
                    ?.overallMetrics
                    ?.averageCompletionPercentage
                    ?.toDouble() ??
                0,
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
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BottomNavScreen(initialIndex: 4),
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
      itemCount: activities.length > 4
          ? 4
          : activities.length, // Show max 5 activities
      separatorBuilder: (context, index) =>
          Divider(color: const Color.fromARGB(255, 239, 239, 239)),
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
