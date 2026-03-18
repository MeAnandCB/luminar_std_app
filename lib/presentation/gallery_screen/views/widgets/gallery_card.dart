// widgets/gallery_card.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_screen/models/gellery_res_model.dart';
import 'package:luminar_std/core/theme/app_colors.dart'; // Import your AppColors

class GalleryCard extends StatelessWidget {
  final Gallery gallery;
  final VoidCallback onTap;

  const GalleryCard({Key? key, required this.gallery, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if assignedBatches is a String or List
    String batchInfo = '';
    if (gallery.assignedBatches is String) {
      batchInfo = gallery.assignedBatches;
    } else if (gallery.assignedBatches is List && gallery.assignedBatches.isNotEmpty) {
      final batches = gallery.assignedBatches as List;
      batchInfo = '${batches.length} ${batches.length == 1 ? 'batch' : 'batches'}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient overlay for visual interest
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary.withOpacity(0.05), Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gallery Icon/Thumbnail Placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(child: Icon(Icons.photo_library_outlined, color: AppColors.white, size: 24)),
                    ),
                    const SizedBox(width: 12),

                    // Gallery Info
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (gallery.isCommon) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient1,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Common',
                                    style: TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (gallery.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              gallery.description,
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (batchInfo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.groups_rounded, size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  batchInfo,
                                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatChip(
                  icon: Icons.videocam_rounded,
                  count: gallery.videosCount,
                  label: 'video',
                  color: AppColors.statsBlue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.folder_rounded,
                  count: gallery.foldersCount,
                  label: 'folder',
                  color: AppColors.statsPurple,
                ),
              ],
            ),
          ),

          // Divider with gradient
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, AppColors.borderColor, Colors.transparent]),
              ),
            ),
          ),

          // Date and Button Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date with icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(gallery.createdAt),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Open Gallery Button
                _buildOpenButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required int count, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          if (count != 1) const Text('s'),
        ],
      ),
    );
  }

  Widget _buildOpenButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primary.withOpacity(0.2),
        highlightColor: AppColors.primary.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Open Gallery',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
