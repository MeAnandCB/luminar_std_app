// widgets/gallery_card.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_screen/models/gellery_res_model.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class GalleryCard extends StatelessWidget {
  final Gallery gallery;
  final VoidCallback onTap;

  const GalleryCard({Key? key, required this.gallery, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if assignedBatches is a String or List
    String batchInfo = '';
    if (gallery.assignedBatches is String) {
      batchInfo = gallery.assignedBatches;
    } else if (gallery.assignedBatches is List &&
        gallery.assignedBatches.isNotEmpty) {
      final batches = gallery.assignedBatches as List;
      batchInfo =
          '${batches.length} ${batches.length == 1 ? 'batch' : 'batches'}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Compact Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                      if (gallery.isCommon)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Content Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              gallery.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (gallery.isCommon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient1,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatItem(
                            icon: Icons.videocam_rounded,
                            count: gallery.videosCount,
                            label: 'videos',
                          ),
                          const SizedBox(width: 12),
                          _buildStatItem(
                            icon: Icons.folder_rounded,
                            count: gallery.foldersCount,
                            label: 'folders',
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Description and Date Row
                      Row(
                        children: [
                          if (gallery.description.isNotEmpty)
                            Expanded(
                              child: Text(
                                gallery.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (gallery.description.isNotEmpty)
                            const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (batchInfo.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _buildBatchInfo(batchInfo),
                      ],
                    ],
                  ),
                ),

                // Arrow Indicator
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }

  Widget _buildBatchInfo(String batchInfo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.groups_rounded, size: 12, color: AppColors.textHint),
        const SizedBox(width: 2),
        Text(
          batchInfo,
          style: TextStyle(fontSize: 11, color: AppColors.textHint),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference d';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
