import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  String _videoId = '';

  // Like functionality
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLiking = false;

  // Repository for API calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lock to portrait initially
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _extractVideoId();
    _initYoutubePlayer();
    // Fetch initial like status from API
  }

  void _extractVideoId() {
    // Extract YouTube video ID from various sources
    String? videoSource = widget.video.videoSource;
    String? videoUrl = widget.video.videoUrl;
    String? videoLink = widget.video.videoLink;
    String? embedCode = widget.video.embedCode;

    // Priority: videoSource (if it's an ID) > videoUrl > videoLink > embedCode
    if (videoSource != null && videoSource.isNotEmpty) {
      _videoId = _extractYoutubeId(videoSource);
      if (_videoId.isEmpty) {
        _videoId = videoSource;
      }
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoId = _extractYoutubeId(videoUrl);
    } else if (videoLink != null && videoLink.isNotEmpty) {
      _videoId = _extractYoutubeId(videoLink);
    } else if (embedCode != null && embedCode.isNotEmpty) {
      _videoId = _extractYoutubeId(embedCode);
    }

    debugPrint('Final video ID: $_videoId');
  }

  String _extractYoutubeId(String url) {
    // Handle different YouTube URL formats using regex
    final RegExp regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      String? id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }

    // If it's just the ID (11 characters)
    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    return '';
  }

  void _initYoutubePlayer() {
    if (_videoId.isEmpty) {
      debugPrint('Invalid video ID');
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: _videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
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

  // Dynamic like functionality with API integration
  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      // Optimistic update - update UI immediately
      final bool newLikeState = !_isLiked;
      final int newLikeCount = newLikeState ? _likeCount + 1 : _likeCount - 1;

      setState(() {
        _isLiked = newLikeState;
        _likeCount = newLikeCount;
      });

      // API Call - Replace with your actual endpoint
      final Map<String, dynamic> requestData = {
        'video_id': widget.video.videoLink,
        'action': newLikeState ? 'like' : 'unlike',
        'user_id': 'current_user_id', // Get from auth service
      };

      // Example API call structure:
      // final response = await _repository.toggleLikeVideo(widget.video.id, !_isLiked);
      //
      // If you have a dedicated like endpoint:
      // final Map<String, dynamic> response = await _repository.likeVideo(
      //   videoId: widget.video.id,
      //   isLiked: newLikeState,
      // );

      // Simulate API call (remove in production)
      await Future.delayed(const Duration(milliseconds: 300));

      // If API call fails, revert the optimistic update
      // Uncomment this section when you implement actual API
      /*
      if (!response['success']) {
        // Revert optimistic update
        setState(() {
          _isLiked = !newLikeState;
          _likeCount = newLikeState ? newLikeCount - 1 : newLikeCount + 1;
        });
        throw Exception(response['message'] ?? 'Failed to update like');
      }
      */

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'Liked!' : 'Removed like'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error liking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isLiked ? 'unlike' : 'like'} video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause video when app is minimized
    if (state == AppLifecycleState.paused && _controller.value.isReady) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller.value.isReady) {
      _controller.removeListener(_listener);
      _controller.dispose();
    }

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
                  widget.video.title,
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: _showVideoInfo,
                  ),
                ],
              ),
        body: SafeArea(
          top: !_isFullScreen,
          bottom: !_isFullScreen,
          child: Column(
            children: [
              // Video Player
              Expanded(
                flex: _isFullScreen ? 1 : 2,
                child: _videoId.isEmpty
                    ? _buildErrorView()
                    : YoutubePlayerBuilder(
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
                            debugPrint('Player is ready');
                          },
                          onEnded: (metaData) {
                            debugPrint('Video ended');
                            _showVideoEndedDialog();
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
              // Video Details Section (shown only when not in fullscreen)
              if (!_isFullScreen && _videoId.isNotEmpty) _buildVideoDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load video',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invalid video source: ${widget.video.videoSource ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            widget.video.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Like Button and Meta info row
          Row(
            children: [
              // Like Button
              _buildLikeButton(),
              const SizedBox(width: 12),
              // Meta chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMetaChip(
                        Icons.person_outline_rounded,
                        widget.video.uploadedByName,
                      ),
                      const SizedBox(width: 8),
                      if (widget.video.duration != null)
                        _buildMetaChip(
                          Icons.access_time_rounded,
                          _formatDuration(widget.video.duration!),
                        ),
                      const SizedBox(width: 8),
                      if (widget.video.fileSize != null)
                        _buildMetaChip(
                          Icons.storage_rounded,
                          _formatFileSize(widget.video.fileSize!),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          if (widget.video.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.video.description,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Additional info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Video Information',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gallery: ${widget.video.gallery}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (widget.video.folder != null &&
                    widget.video.folder!.isNotEmpty)
                  Text(
                    'Folder: ${widget.video.folder}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                Text(
                  'Uploaded: ${_formatDate(widget.video.createdAt)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  'Video ID: $_videoId',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: _handleLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isLiked
              ? const Color(0xFF6C5CE7).withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLiked
                ? const Color(0xFF6C5CE7)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLiking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C5CE7),
                    ),
                  )
                : Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? const Color(0xFF6C5CE7) : Colors.white70,
                    size: 18,
                  ),
            const SizedBox(width: 6),
            Text(
              _likeCount.toString(),
              style: TextStyle(
                color: _isLiked ? const Color(0xFF6C5CE7) : Colors.white70,
                fontSize: 13,
                fontWeight: _isLiked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final hours = twoDigits(duration.inHours);

    if (duration.inHours > 0) {
      return '$hours:$minutes:${twoDigits(duration.inSeconds.remainder(60))}';
    }
    return '$minutes:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Video Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${widget.video.title}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploaded by: ${widget.video.uploadedByName}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (widget.video.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(widget.video.duration!)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (widget.video.fileSize != null) ...[
              const SizedBox(height: 8),
              Text(
                'File Size: ${_formatFileSize(widget.video.fileSize!)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Uploaded: ${_formatDate(widget.video.createdAt)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Video ID: $_videoId',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Likes: $_likeCount',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoEndedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Video Ended', style: TextStyle(color: Colors.white)),
        content: const Text(
          'The video has finished playing. Would you like to replay it?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.seekTo(Duration.zero);
              _controller.play();
            },
            child: const Text(
              'Replay',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }
}
