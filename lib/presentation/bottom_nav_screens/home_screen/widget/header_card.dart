import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/notification_screen/notification_screen.dart';
import 'package:luminar_std/presentation/profile_screen/profile_screen.dart';

class HeaderWidget extends StatelessWidget {
  final String studentName;
  final DashboardController provider;
  final EnrollmentProvider enrolldata;

  const HeaderWidget({
    super.key,
    required this.studentName,
    required this.provider,
    required this.enrolldata,
  });

  String _getFirstLetter() {
    return studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
  }

  bool _shouldShowAvatarImage() {
    return studentName != 'Guest' &&
        studentName != 'Loading...' &&
        studentName.isNotEmpty;
  }

  bool _shouldShowAvatarText() {
    return studentName == 'Guest' ||
        studentName == 'Loading...' ||
        studentName.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    print('🖼️ Building header with name: "$studentName"');

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildProfileAvatar(context),
              const SizedBox(width: 12),
              _buildUserInfo(context),
            ],
          ),
        ),

        Row(children: [_buildNotificationIcon(context)]),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              course:
                  enrolldata
                      .enrollmentDataRes
                      ?.enrollments[0]
                      .course
                      .courseName ??
                  "",
            ),
          ),
        );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.avatarBackground,
            child: CircleAvatar(
              backgroundColor: AppColors.white,
              radius: 23,
              backgroundImage: _shouldShowAvatarImage()
                  ? const NetworkImage(
                      'https://pbs.twimg.com/media/FO4RRcaWQAELKS7.jpg',
                    )
                  : null,
              child: _shouldShowAvatarText()
                  ? Text(
                      _getFirstLetter(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: AvatarGlow(
              child: CircleAvatar(
                radius: 6,
                backgroundColor: AppColors.statsGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headerName,
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * .50,
          child: Text(
            studentName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 17),
          ),
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * .50,
          child: Text(
            provider.dashboard?.studentDetails?.basicInfo?.studentId ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount =
        provider.dashboard?.notificationsSummary?.summary?.unreadCount;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: AvatarGlow(
          glowColor: AppColors.notificationGlow,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.notificationIcon,
                  size: 20,
                ),
                if (unreadCount != null && unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
