// screens/course_screen.dart
import 'package:luminar_std/core/constants/app_config.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:provider/provider.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({
    Key? key,
    required this.institute,
    required this.courseName,
    required this.batchName,
    required this.enrollmentId,
    required this.startDate,
    required this.schedule,
    required this.batchTime,
    required this.attendanceMode,
    required this.progress,
    required this.attendance,
    required this.paymentCompleted,
    required this.amountPaid,
    required this.pendingAmount,
    required this.totalFee,
    required this.discount,
  }) : super(key: key);

  final String institute;
  final String courseName;
  final String batchName;
  final String enrollmentId;
  final String startDate;
  final String schedule;
  final String batchTime;
  final String attendanceMode;
  final int progress;
  final String attendance;
  final int paymentCompleted;
  final int amountPaid;
  final int pendingAmount;
  final int totalFee;
  final int discount;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LoggerUtils.debug({widget.paymentCompleted}.toString(), tag: 'Course');
    // Subscribe to theme changes
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Hero Institute Card
                        _buildEnhancedInstituteCard(),
                        const SizedBox(height: 20),

                        // Modern Stats Grid
                        _buildEnhancedStatsGrid(),
                        const SizedBox(height: 20),

                        // Course Info Card with Timeline
                        _buildEnhancedCourseInfoCard(),
                        const SizedBox(height: 20),

                        // Premium Payment Card (hidden on iOS)
                        if (!AppConfig.hidePayments) ...[
                          _buildEnhancedPaymentCard(),
                          const SizedBox(height: 20),
                        ],

                        // Action Buttons
                        _buildActionButtons(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF6B8DD6)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Course Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInstituteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.school_rounded, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.institute,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.courseName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              'ID: ${widget.enrollmentId.substring(0, 6)}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedStatItem(
              'Progress',
              '${widget.progress}%',
              Icons.trending_up_rounded,
              AppColors.statsBlue,
              widget.progress / 100,
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.borderColor),
          Expanded(
            child: _buildEnhancedStatItem(
              'Attendance',
              '${widget.attendance}%',
              Icons.calendar_month_rounded,
              AppColors.statsGreen,
              double.parse(widget.attendance) / 100,
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.borderColor),
          Expanded(
            child: _buildEnhancedStatItem(
              'Payment',
              '₹${widget.paymentCompleted}',
              Icons.payments_rounded,
              AppColors.statsPurple,
              widget.paymentCompleted / 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCourseInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_month_rounded,
                  'Start Date',
                  _formatDate(widget.startDate),
                  AppColors.statsBlue,
                ),
                // Padding(
                //   padding: EdgeInsets.symmetric(vertical: 8),
                //   child: Divider(
                //     height: 1,
                //     color: AppColors.borderColor.withOpacity(0.5),
                //   ),
                // ),
                // _buildInfoRow(
                //   Icons.access_time_rounded,
                //   'Schedule',
                //   _formatTimeDetailed(widget.schedule),
                //   AppColors.statsOrange,
                // ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                _buildInfoRow(
                  _getModeIcon(widget.attendanceMode),
                  'Mode',
                  widget.attendanceMode,
                  _getModeColor(widget.attendanceMode),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                _buildInfoRow(
                  Icons.group_rounded,
                  'Batch',
                  widget.batchName,
                  AppColors.statsPurple,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                _buildInfoRow(
                  Icons.schedule_rounded,
                  'Batch Timing',
                  _formatBatchTime(widget.batchTime),
                  AppColors.statsGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF6B8DD6), Color(0xFF8E6BEA)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '₹${widget.discount} Discount',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPaymentDetail(
                  'Total Fee',
                  '₹${_formatNumber(widget.totalFee)}',
                  Icons.currency_rupee_rounded,
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildPaymentDetail(
                  'Paid',
                  '₹${_formatNumber(widget.amountPaid)}',
                  Icons.check_circle_rounded,
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildPaymentDetail(
                  'Pending',
                  '₹${_formatNumber(widget.pendingAmount)}',
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.paymentCompleted / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Text(
                '${widget.paymentCompleted} Rupees Paid',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.statsGreen : AppColors.surface,
        border: Border.all(
          color: isActive
              ? AppColors.statsGreen.withOpacity(0.3)
              : AppColors.borderColor,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.statsGreen.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          isActive ? Icons.check_rounded : Icons.circle_rounded,
          color: isActive
              ? AppColors.white
              : AppColors.textSecondary.withOpacity(0.5),
          size: isActive ? 16 : 8,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Continue',
            icon: Icons.play_circle_fill_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BottomNavScreen(initialIndex: 3),
                ),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textWhite, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatBatchTime(String time) {
    if (time.isEmpty) return 'Not specified';
    try {
      // Handle range format like "09:00-11:00" or "09:00 - 11:00"
      final rangeSeparator = RegExp(r'\s*-\s*');
      final parts = time.split(rangeSeparator);
      if (parts.length == 2) {
        final start = _parseTimeTo12h(parts[0].trim());
        final end = _parseTimeTo12h(parts[1].trim());
        return '$start - $end';
      }
      return _parseTimeTo12h(time.trim());
    } catch (e) {
      return time;
    }
  }

  String _parseTimeTo12h(String time) {
    final normalized = time.replaceAll('.', ':');
    final parts = normalized.split(':');
    if (parts.length >= 2) {
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    return time;
  }

  String _formatTimeDetailed(String time) {
    try {
      final parts = time.replaceAll('.', ':').split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return Icons.computer_rounded;
      case 'offline':
        return Icons.location_on_rounded;
      case 'hybrid':
        return Icons.sync_alt_rounded;
      case 'recording':
        return Icons.video_library_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return AppColors.primary;
      case 'offline':
        return AppColors.statsGreen;
      case 'hybrid':
        return AppColors.statsOrange;
      case 'recording':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String date) {
    try {
      // Try to parse the date
      if (date.contains(RegExp(r'[A-Za-z]{3}\s\d{1,2},\s\d{4}'))) {
        // Handle format like "Mar 15, 2024"
        return date;
      }

      // Try parsing as DateTime
      final DateTime parsedDate = DateTime.parse(date);
      final List<String> months = [
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
      return '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
    } catch (e) {
      // If parsing fails, return the original date string
      return date;
    }
  }
}
