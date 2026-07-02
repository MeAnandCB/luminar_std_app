import 'package:luminar_std/core/utils/logger_utils.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:provider/provider.dart';

String _formatBatchTime(String time) {
  if (time.isEmpty) return 'N/A';
  try {
    final parts = time.split(RegExp(r'\s*-\s*'));
    if (parts.length == 2) {
      return '${_to12h(parts[0].trim())} – ${_to12h(parts[1].trim())}';
    }
    return _to12h(time.trim());
  } catch (_) {
    return time;
  }
}

String _to12h(String t) {
  final normalized = t.replaceAll('.', ':');
  final parts = normalized.split(':');
  if (parts.length >= 2) {
    final h = int.parse(parts[0]);
    final m = parts[1].padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$display:$m $period';
  }
  return t;
}

// Per-index card palettes – first entry tracks the app theme primary colour
List<List<Color>> _kPalettes() => [
  [AppColors.primaryDark, AppColors.primary],
  [const Color(0xFF0A3D62), const Color(0xFF1565C0)],
  [const Color(0xFF00695C), const Color(0xFF26A69A)],
  [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
  [const Color(0xFF7B1A1A), const Color(0xFFC62828)],
];

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
    context.watch<ThemeProvider>();
    final dateFormat = DateFormat('dd MMM yyyy');
    LoggerUtils.debug(
      enrollment.progress.completionPercentage.toString(),
      tag: 'Enrollment',
    );

    final palettes = _kPalettes();
    final palette = palettes[index % palettes.length];
    final gradStart = palette[0];
    final gradEnd = palette[1];
    final statusColor = getStatusColor(enrollment.status.color);

    final attendanceMode = enrollment.attendanceMode.value;
    final modeIcon = switch (attendanceMode) {
      'online' => Icons.computer_rounded,
      'offline' => Icons.location_on_rounded,
      'hybrid' => Icons.sync_alt_rounded,
      'recording' => Icons.video_library_rounded,
      _ => Icons.help_outline_rounded,
    };
    final modeColor = switch (attendanceMode) {
      'online' => const Color(0xFF1565C0),
      'offline' => const Color(0xFF2E7D32),
      'hybrid' => const Color(0xFFE65100),
      'recording' => const Color(0xFF6A1B9A),
      _ => AppColors.textHint,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradStart.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Header ────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradStart, gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circle blob
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Row(
                        children: [
                          // Index badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Enrollment ID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enrollment ID',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  enrollment.enrollmentNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  enrollment.status.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── White body ─────────────────────────────────────
              Container(
                color: AppColors.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Course row ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon box with gradient
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradStart.withValues(alpha: 0.12),
                                  gradEnd.withValues(alpha: 0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: gradStart.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: gradStart,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enrollment.course.courseName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Mode + date chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _chip(
                                      icon: modeIcon,
                                      label: enrollment.attendanceMode.name,
                                      iconColor: modeColor,
                                      bgColor: modeColor.withValues(alpha: 0.09),
                                      textColor: modeColor,
                                    ),
                                    _chip(
                                      icon: Icons.calendar_today_rounded,
                                      label: dateFormat.format(enrollment.enrollmentDate),
                                      iconColor: AppColors.textSecondary,
                                      bgColor: AppColors.surface,
                                      textColor: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.borderColor.withValues(alpha: 0.0),
                              AppColors.borderColor,
                              AppColors.borderColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Batch row ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.statsOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.group_rounded,
                              size: 20,
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
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range_rounded,
                                      size: 12,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${dateFormat.format(enrollment.batch.startDate)} – ${dateFormat.format(enrollment.batch.endDate)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (enrollment.batch.time.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.statsOrange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.statsOrange.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 12,
                                          color: AppColors.statsOrange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatBatchTime(enrollment.batch.time),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.statsOrange,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Join button
                          if (enrollment.batch.joinUrl.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [gradStart, gradEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradStart.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.video_call_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
