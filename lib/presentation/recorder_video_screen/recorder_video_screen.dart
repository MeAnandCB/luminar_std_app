import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// VideoGallery model class - MUST be defined before using it
class VideoGallery {
  final String title;
  final String subtitle;
  final int videoCount;
  final int folderCount;
  final DateTime date;
  final String thumbnail;
  final String videoId;

  VideoGallery({
    required this.title,
    required this.subtitle,
    required this.videoCount,
    required this.folderCount,
    required this.date,
    required this.thumbnail,
    required this.videoId,
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
      title: 'ggf - Videos',
      subtitle: 'Video gallery for ggf',
      videoCount: 1,
      folderCount: 0,
      date: DateTime(2026, 2, 28),
      thumbnail: 'https://img.youtube.com/vi/kzpS-A3QJqE/0.jpg',
      videoId: 'kzpS-A3QJqE',
    ),
    VideoGallery(
      title: 'common gallery',
      subtitle: 'Video gallery for common',
      videoCount: 5,
      folderCount: 0,
      date: DateTime(2025, 11, 27),
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg',
      videoId: 'dQw4w9WgXcQ',
    ),
    VideoGallery(
      title: 'Angular Tutorials',
      subtitle: 'Complete Angular course',
      videoCount: 12,
      folderCount: 3,
      date: DateTime(2026, 3, 1),
      thumbnail: 'https://img.youtube.com/vi/3qBXWUpoPHo/0.jpg',
      videoId: '3qBXWUpoPHo',
    ),
    VideoGallery(
      title: 'ASP.NET Core',
      subtitle: 'Backend development',
      videoCount: 8,
      folderCount: 2,
      date: DateTime(2026, 2, 25),
      thumbnail: 'https://img.youtube.com/vi/8jcL7Hn2KPI/0.jpg',
      videoId: '8jcL7Hn2KPI',
    ),
    VideoGallery(
      title: 'Flutter Tutorial',
      subtitle: 'Learn Flutter development',
      videoCount: 15,
      folderCount: 4,
      date: DateTime(2026, 3, 5),
      thumbnail: 'https://img.youtube.com/vi/1ukSR1GRtMU/0.jpg',
      videoId: '1ukSR1GRtMU',
    ),
  ];

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _openVideoPlayer(String videoId, String title) {
    // Add a smooth transition to video player
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: const Color(0xFF6C5CE7),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Video Recordings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3436),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF6C5CE7),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search videos...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
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
                    '${_galleries.length} Galleries',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Video Galleries - List View
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _galleries.length,
                itemBuilder: (context, index) {
                  final gallery = _galleries[index];
                  return _buildVideoCard(gallery);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoGallery gallery) {
    return GestureDetector(
      onTap: () {
        _openVideoPlayer(gallery.videoId, gallery.title);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail with Play Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      gallery.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              size: 50,
                              color: const Color(0xFF6C5CE7).withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                // Duration badge (example - you might want to fetch actual duration)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '15:30',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Video Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gallery.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${gallery.videoCount} videos',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gallery.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gallery.folderCount} folders',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(gallery.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Watch button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openVideoPlayer(gallery.videoId, gallery.title);
                      },
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 18,
                      ),
                      label: const Text('Watch Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String videoTitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lock to portrait initially
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        hideControls: false,
        useHybridComposition: true,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_listener);
  }

  void _listener() {
    if (_controller.value.isReady && !_isPlayerReady) {
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
        });
      }
    }

    // Detect fullscreen changes
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });

      if (_controller.value.isFullScreen) {
        // Enter fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Exit fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause video when app is minimized
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_listener);
    _controller.dispose();

    // Reset to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If in fullscreen, exit fullscreen first
        if (_isFullScreen) {
          _controller.toggleFullScreenMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(
                  widget.videoTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                elevation: 0,
              ),
        body: SafeArea(
          top: !_isFullScreen,
          bottom: !_isFullScreen,
          child: Column(
            children: [
              // Video Player
              Expanded(
                child: YoutubePlayerBuilder(
                  onExitFullScreen: () {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ]);
                  },
                  onEnterFullScreen: () {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                  },
                  player: YoutubePlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    onReady: () {
                      print('Player is ready');
                    },
                    onEnded: (metaData) {
                      print('Video ended');
                      // Optional: Show a dialog or navigate back
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video ended'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    actionsPadding: const EdgeInsets.all(8),
                    bottomActions: [
                      CurrentPosition(),
                      const SizedBox(width: 10),
                      ProgressBar(
                        isExpanded: true,
                        colors: const ProgressBarColors(
                          playedColor: Color(0xFF6C5CE7),
                          handleColor: Color(0xFF6C5CE7),
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      RemainingDuration(),
                      const PlaybackSpeedButton(),
                      FullScreenButton(),
                    ],
                  ),
                  builder: (context, player) {
                    return Container(
                      color: Colors.black,
                      child: Stack(
                        children: [
                          Center(child: player),
                          if (!_isPlayerReady)
                            Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
