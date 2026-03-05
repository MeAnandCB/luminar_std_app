import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/video_player_screen/video_player_screen.dart';

// VideoGallery model class - MUST be defined before using it
class VideoGallery {
  final String title;
  final String subtitle;
  final int videoCount;
  final int folderCount;
  final DateTime date;
  final String thumbnail;
  final String videoId;
  final String duration;
  final String views;
  final String uploadTime;

  VideoGallery({
    required this.title,
    required this.subtitle,
    required this.videoCount,
    required this.folderCount,
    required this.date,
    required this.thumbnail,
    required this.videoId,
    this.duration = '15:30',
    this.views = '1.2K',
    this.uploadTime = '2 days ago',
  });
}

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  // Dummy video gallery data with YouTube video IDs
  final List<VideoGallery> _galleries = [
    VideoGallery(
      title: 'Getting Started with Flutter',
      subtitle: 'Complete beginner tutorial for Flutter development',
      videoCount: 12,
      folderCount: 2,
      date: DateTime(2026, 3, 5),
      thumbnail: 'https://img.youtube.com/vi/1ukSR1GRtMU/0.jpg',
      videoId: '1ukSR1GRtMU',
      duration: '25:30',
      views: '15K',
      uploadTime: '3 days ago',
    ),
    VideoGallery(
      title: 'Advanced Angular Concepts',
      subtitle: 'Deep dive into Angular architecture',
      videoCount: 8,
      folderCount: 1,
      date: DateTime(2026, 3, 1),
      thumbnail: 'https://img.youtube.com/vi/3qBXWUpoPHo/0.jpg',
      videoId: '3qBXWUpoPHo',
      duration: '42:15',
      views: '8.5K',
      uploadTime: '1 week ago',
    ),
    VideoGallery(
      title: 'ASP.NET Core Web API',
      subtitle: 'Build RESTful APIs with .NET Core',
      videoCount: 15,
      folderCount: 3,
      date: DateTime(2026, 2, 25),
      thumbnail: 'https://img.youtube.com/vi/8jcL7Hn2KPI/0.jpg',
      videoId: '8jcL7Hn2KPI',
      duration: '38:20',
      views: '12K',
      uploadTime: '2 weeks ago',
    ),
    VideoGallery(
      title: 'JavaScript ES6 Tutorial',
      subtitle: 'Modern JavaScript features explained',
      videoCount: 10,
      folderCount: 2,
      date: DateTime(2026, 2, 28),
      thumbnail: 'https://img.youtube.com/vi/kzpS-A3QJqE/0.jpg',
      videoId: 'kzpS-A3QJqE',
      duration: '32:45',
      views: '9.2K',
      uploadTime: '5 days ago',
    ),
    VideoGallery(
      title: 'React Native Basics',
      subtitle: 'Cross-platform mobile development',
      videoCount: 20,
      folderCount: 4,
      date: DateTime(2026, 2, 20),
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg',
      videoId: 'dQw4w9WgXcQ',
      duration: '45:10',
      views: '21K',
      uploadTime: '1 month ago',
    ),
    VideoGallery(
      title: 'Python for Beginners',
      subtitle: 'Learn Python programming from scratch',
      videoCount: 25,
      folderCount: 5,
      date: DateTime(2026, 3, 2),
      thumbnail: 'https://img.youtube.com/vi/1ukSR1GRtMU/0.jpg',
      videoId: '1ukSR1GRtMU',
      duration: '28:15',
      views: '34K',
      uploadTime: '4 days ago',
    ),
    VideoGallery(
      title: 'Docker Masterclass',
      subtitle: 'Containerization fundamentals',
      videoCount: 14,
      folderCount: 2,
      date: DateTime(2026, 2, 15),
      thumbnail: 'https://img.youtube.com/vi/3qBXWUpoPHo/0.jpg',
      videoId: '3qBXWUpoPHo',
      duration: '52:30',
      views: '6.8K',
      uploadTime: '3 weeks ago',
    ),
    VideoGallery(
      title: 'Kubernetes Guide',
      subtitle: 'Orchestration made easy',
      videoCount: 18,
      folderCount: 3,
      date: DateTime(2026, 2, 10),
      thumbnail: 'https://img.youtube.com/vi/8jcL7Hn2KPI/0.jpg',
      videoId: '8jcL7Hn2KPI',
      duration: '41:20',
      views: '5.2K',
      uploadTime: '1 month ago',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false; // Toggle between grid and list view

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _openVideoPlayer(String videoId, String title) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerScreen(videoId: videoId, videoTitle: title),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showBottomSheet(VideoGallery gallery) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.download_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Download', style: AppTextStyles.bodyText),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.share_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Share', style: AppTextStyles.bodyText),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Details', style: AppTextStyles.bodyText),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Simple Header with back button, title, and view toggle
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Video Library',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // View toggle button (Grid/List)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search videos...',
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: AppColors.textHint,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Gallery count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_galleries.length} videos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isGridView ? 'Grid View' : 'List View',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Video List/Grid
            Expanded(child: _isGridView ? _buildGridView() : _buildListView()),
          ],
        ),
      ),
    );
  }

  // List View Builder
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _galleries.length,
      itemBuilder: (context, index) {
        final gallery = _galleries[index];
        return _buildListVideoCard(gallery);
      },
    );
  }

  // Grid View Builder - Responsive
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns for all screen sizes
        childAspectRatio: 0.75, // Height relative to width
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _galleries.length,
      itemBuilder: (context, index) {
        final gallery = _galleries[index];
        return _buildGridVideoCard(gallery);
      },
    );
  }

  // List View Card (existing design)
  Widget _buildListVideoCard(VideoGallery gallery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openVideoPlayer(gallery.videoId, gallery.title),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 90,
                    color: Colors.grey[200],
                    child: Image.network(
                      gallery.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              size: 30,
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Play icon overlay
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  // Duration
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gallery.duration,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Video Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      gallery.title,
                      style: AppTextStyles.activityTitle.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      gallery.subtitle,
                      style: AppTextStyles.activitySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.remove_red_eye_outlined,
                          gallery.views,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.access_time_outlined,
                          gallery.uploadTime,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.video_library_outlined,
                          '${gallery.videoCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid View Card - New Design
  Widget _buildGridVideoCard(VideoGallery gallery) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openVideoPlayer(gallery.videoId, gallery.title),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Image.network(
                      gallery.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              size: 30,
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Play icon overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        color: AppColors.white,
                        size: 35,
                      ),
                    ),
                  ),
                ),
                // Duration
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(gallery.duration),
                  ),
                ),
              ],
            ),
            // Video Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    gallery.title,
                    style: AppTextStyles.activityTitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subtitle (truncated)
                  Text(
                    gallery.subtitle,
                    style: AppTextStyles.activitySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 10,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gallery.views,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_outlined,
                        size: 10,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gallery.uploadTime,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Video count
                  Row(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 10,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${gallery.videoCount} videos',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // More options button
                      GestureDetector(
                        onTap: () => _showBottomSheet(gallery),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
