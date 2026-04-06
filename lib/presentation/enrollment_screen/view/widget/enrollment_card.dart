import 'package:luminar_std/core/utils/logger_utils.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';

class EnrollmentCard extends StatelessWidget {
  final Enrollment enrollment;
  final int index;
  final VoidCallback onTap;
  final Color Function(double) getProgressColor;
  final Color Function(String) getStatusColor;

  const EnrollmentCard({
    Key? key,
    required this.enrollment,
    required this.index,
    required this.onTap,
    required this.getProgressColor,
    required this.getStatusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');
    LoggerUtils.debug(
      enrollment.progress.completionPercentage.toString(),
      tag: 'Enrollment',
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.cardBackground,
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with index and status
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Index badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Enrollment number
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enrollment ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                enrollment.enrollmentNumber,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              enrollment.status.color,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: getStatusColor(
                                enrollment.status.color,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getStatusColor(
                                    enrollment.status.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                enrollment.status.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: getStatusColor(
                                    enrollment.status.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Course section
                  Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        // Course icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Course details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                enrollment.course.courseName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormat.format(
                                      enrollment.enrollmentDate,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        switch (enrollment
                                            .attendanceMode
                                            .value) {
                                          'online' => Icons.computer,
                                          'offline' => Icons.location_on,
                                          'hybrid' => Icons.sync_alt,
                                          'recording' => Icons.video_library,
                                          _ => Icons.help_outline,
                                        },
                                        size: 12,
                                        color: switch (enrollment
                                            .attendanceMode
                                            .value) {
                                          'online' => AppColors.statsBlue,
                                          'offline' => AppColors.statsGreen,
                                          'hybrid' => AppColors.statsOrange,
                                          'recording' => AppColors.primary,
                                          _ => AppColors.textHint,
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        enrollment.attendanceMode.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: switch (enrollment
                                              .attendanceMode
                                              .value) {
                                            'online' => AppColors.statsBlue,
                                            'offline' => AppColors.statsGreen,
                                            'hybrid' => AppColors.statsOrange,
                                            'recording' => AppColors.primary,
                                            _ => AppColors.textHint,
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Batch info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statsOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.group,
                            size: 16,
                            color: AppColors.statsOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enrollment.batch.batchName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dateFormat.format(enrollment.batch.startDate)} - ${dateFormat.format(enrollment.batch.endDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (enrollment.batch.joinUrl.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.statsBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.video_call,
                              size: 16,
                              color: AppColors.statsBlue,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
