import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.status});

  final String status;
  @override
  Widget build(BuildContext context) {
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
          child: Text("Status: $status", style: AppTextStyles.welcomeStatus),
        ),
      ],
    );
  }
}
