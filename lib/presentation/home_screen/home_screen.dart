import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/notification_screen/notification_screen.dart';
import 'package:luminar_std/presentation/profile_screen/profile_screen.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(context),
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildCourseCard(),
            const SizedBox(height: 24),
            _buildQuickStatsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle("Recent Activities"),
            const SizedBox(height: 12),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.statusActiveBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Status: Active",
            style: AppTextStyles.welcomeStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
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
              "₹29,000",
              Icons.account_balance_wallet,
              AppColors.statsBlue,
            ),
            _buildStatCard(
              "Paid",
              "₹1,000",
              Icons.check_circle,
              AppColors.statsGreen,
            ),
            _buildStatCard(
              "Pending",
              "₹28,000",
              Icons.pending_actions,
              AppColors.statsOrange,
            ),
            _buildStatCard(
              "Progress",
              "3.45%",
              Icons.speed,
              AppColors.statsPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCourseCard() {
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
          const Text(
            "Asp.net MVC with Angular - Full Stack",
            style: AppTextStyles.courseCardTitle,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseInfoItem("Batch", "ggf"),
              _buildCourseInfoItem("Starts", "Mar 12, 2026"),
              _buildCourseInfoItem("Mode", "Hybrid"),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            minHeight: 8,
            value: 0.345,
            backgroundColor: AppColors.whiteWithOpacity20,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Progress: 34.5%',
            style: AppTextStyles.courseCardProgress,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
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

  Widget _buildActivityList() {
    final activities = [
      {
        "title": "Profile Updated",
        "desc": "WhatsApp number changed",
        "time": "1 day ago",
        "icon": Icons.person_outline,
      },
      {
        "title": "Receipt Generated",
        "desc": "ADM2026030001 - ₹1000",
        "time": "1 day ago",
        "icon": Icons.receipt_long,
      },
      {
        "title": "Payment Received",
        "desc": "Manual payment of ₹1000",
        "time": "1 day ago",
        "icon": Icons.payment,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = activities[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.info.withOpacity(0.1),
              child: Icon(
                item['icon'] as IconData,
                color: AppColors.info,
                size: 20,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: AppTextStyles.activityTitle,
            ),
            subtitle: Text(
              item['desc'] as String,
              style: AppTextStyles.activitySubtitle,
            ),
            trailing: Text(
              item['time'] as String,
              style: AppTextStyles.activityTime,
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.avatarBackground,
            child: const CircleAvatar(
              radius: 23,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello 👋 ANAND!", style: AppTextStyles.headerName),
            Text("Welcome Back", style: AppTextStyles.headerSubtitle),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: AvatarGlow(
              glowColor: AppColors.notificationGlow,
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.notificationIcon,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
