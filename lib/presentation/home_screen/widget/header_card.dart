import 'package:avatar_glow/avatar_glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/notification_screen/notification_screen.dart';
import 'package:luminar_std/presentation/profile_screen/profile_screen.dart';
import 'package:provider/provider.dart';

class HeaderWidget extends StatelessWidget {
  final String studentName;
  final DashboardController provider;
  final String courseName;

  const HeaderWidget({
    super.key,
    required this.studentName,
    required this.provider,
    required this.courseName,
  });

  String _getFirstLetter() {
    return studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
  }

  bool _shouldShowAvatarImage() {
    return studentName != 'Guest' &&
        studentName != 'Loading...' &&
        studentName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    LoggerUtils.debug(
      '🖼️ Building header with name: "$studentName"',
      tag: 'Dashboard',
    );

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

        Row(
          children: [
            _buildThemeToggle(context),
            const SizedBox(width: 4),
            _buildNotificationIcon(context),
          ],
        ),
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
                  courseName,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.avatarBackground,
            child: ClipOval(
              child: _shouldShowAvatarImage()
                  ? CachedNetworkImage(
                      imageUrl:
                          provider
                              .dashboard
                              ?.studentDetails
                              ?.basicInfo
                              ?.profilePicture ??
                          "",
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary,
                        child: Center(
                          child: Text(
                            _getFirstLetter(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 46,
                      height: 46,
                      color: AppColors.primary,
                      child: Center(
                        child: Text(
                          _getFirstLetter(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
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
          width: MediaQuery.sizeOf(context).width * .40,
          child: Text(
            studentName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 17),
          ),
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * .40,
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

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount =
        provider.dashboard?.notificationsSummary?.summary?.unreadCount ?? 0;
    final hasNotifications = unreadCount > 0;

    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          hasNotifications
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined,
          color: AppColors.notificationIcon,
          size: 24,
        ),
        if (hasNotifications)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
              child: Text(
                '1+',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

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
        child: hasNotifications
            ? AvatarGlow(
                glowColor: AppColors.notificationGlow,
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: iconWidget,
                ),
              )
            : iconWidget,
      ),
    );
  }
}
