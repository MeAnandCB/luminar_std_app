// widgets/folder_card.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:luminar_std/core/theme/app_colors.dart'; // Import your AppColors

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final bool showOpenButton;

  const FolderCard({Key? key, required this.folder, required this.onTap, this.showOpenButton = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Folder Icon with Gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.folder_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),

                // Folder Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Folder Name
                      Text(
                        folder.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Folder Description (if available)
                      if (folder.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          folder.description,
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.videocam_rounded,
                            count: folder.videosCount,
                            label: 'video',
                            color: AppColors.statsBlue,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            icon: Icons.folder_rounded,
                            count: folder.subfoldersCount,
                            label: 'subfolder',
                            color: AppColors.statsPurple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Open Button (if enabled)
                if (showOpenButton) ...[const SizedBox(width: 8), _buildOpenButton()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required int count, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          if (count != 1) Text('s', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                'Open',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
