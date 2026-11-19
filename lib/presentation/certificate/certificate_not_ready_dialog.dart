import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/certificate/certificate_tile.dart';

/// Shown when a student taps Certificates for a course that is still running.
/// It is information, not an error: nothing is wrong, the certificate simply
/// does not exist until the course is completed.
Future<void> showCertificateNotReadyDialog(
  BuildContext context, {
  String courseName = '',
  String batchName = '',

  /// When the batch is expected to finish. Only mentioned if it is still in
  /// the future — a past date on a not-yet-completed batch would just confuse.
  DateTime? expectedEnd,
}) {
  final showEnd = expectedEnd != null && expectedEnd.isAfter(DateTime.now());
  final course = [
    if (courseName.trim().isNotEmpty) courseName.trim(),
    if (batchName.trim().isNotEmpty) 'Batch ${batchName.trim()}',
  ].join(' · ');

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: certificatePendingColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 34,
              color: certificatePendingColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Certificate not ready yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your certificate will be generated after you complete the course.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (course.isNotEmpty || showEnd) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.isNotEmpty)
                    Text(
                      course,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (course.isNotEmpty && showEnd) const SizedBox(height: 4),
                  if (showEnd)
                    Text(
                      'Expected to finish on '
                      '${DateFormat('d MMM yyyy').format(expectedEnd)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );
}
