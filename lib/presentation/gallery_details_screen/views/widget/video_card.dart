// widgets/video_card.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:luminar_std/core/theme/app_colors.dart'; // Import your AppColors

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onWatch;

  const VideoCard({Key? key, required this.video, required this.onWatch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine video duration display
    final String durationText = video.duration?.toString() ?? '00:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onWatch,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Title and Duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Thumbnail Placeholder
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_circle_filled, size: 30, color: AppColors.primary.withOpacity(0.8)),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                durationText,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (video.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              video.description,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Uploader and date row
                Row(
                  children: [
                    // Uploader info with verified badge
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: AppColors.statsGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.statsGreen),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        video.uploadedByName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(video.createdAt),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Divider with gradient
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, AppColors.borderColor, Colors.transparent]),
                  ),
                ),

                const SizedBox(height: 12),

                // Watch button and additional metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Watch Button
                    _buildWatchButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onWatch,
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primary.withOpacity(0.2),
        highlightColor: AppColors.primary.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.white),
              SizedBox(width: 4),
              Text(
                'Watch',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
              ),
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

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$views ${views == 1 ? 'view' : 'views'}';
    }
  }
}
