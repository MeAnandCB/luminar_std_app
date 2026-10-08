import 'dart:async';

import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show UserScript, UserScriptInjectionTime;
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

  PlayerState _playerState = PlayerState.unknown;

  // Controls bar: always shown under the video. In fullscreen it only appears for
  // a few seconds after a tap, so it never covers a paused frame.
  bool _showFullScreenBar = false;
  Timer? _barTimer;

  // Horizontal drag to seek
  double _dragStartX = 0;
  Duration _dragBase = Duration.zero;
  Duration? _dragSeekTo;

  bool _youtubeUiHidden = false;

  // Double-tap seek indicators
  bool _showForwardIndicator = false;
  bool _showBackwardIndicator = false;

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
    String? vSource = widget.video.videoSource;
    String? vUrl = widget.video.videoUrl;
    String? vLink = widget.video.videoLink;
    String? eCode = widget.video.embedCode;

    debugPrint(
      '[Video] Sources — Source: $vSource | Url: $vUrl | Link: $vLink | Embed: $eCode',
    );

    // Priority: videoSource > videoUrl > videoLink > embedCode
    _videoId =
        _tryExtractIdFrom(vSource) ??
        _tryExtractIdFrom(vUrl) ??
        _tryExtractIdFrom(vLink) ??
        _tryExtractIdFrom(eCode) ??
        '';

    debugPrint('[Video] Final extracted ID: "$_videoId"');
  }

  String? _tryExtractIdFrom(String? source) {
    if (source == null || source.isEmpty) return null;

    // 1. Try built-in converter
    String? id = YoutubePlayer.convertUrlToId(source);
    if (id != null && id.length == 11) return id;

    // 2. If it's already an 11-char ID
    if (source.length == 11 &&
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(source)) {
      return source;
    }

    // 3. Fallback for Shorts if convertUrlToId missed it
    if (source.contains('/shorts/')) {
      final regExp = RegExp(r'shorts\/([a-zA-Z0-9_-]{11})');
      final match = regExp.firstMatch(source);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
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
        enableCaption: false,
        hideThumbnail: true,
        // The built-in controls draw a dark tint and a centre play icon over the
        // video, so the screen draws its own bar (see _buildControlsBar).
        hideControls: true,
        useHybridComposition: true,
        controlsVisibleAtStart: false,
      ),
    );

    _controller.addListener(_listener);
  }

  void _listener() {
    _hideYoutubeUi();

    if (_controller.value.isReady && !_isPlayerReady) {
      _disableCaptions();
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
        });
      }
    }

    // Rebuild when the player state changes (drives the buffering spinner)
    final state = _controller.value.playerState;
    if (state != _playerState && mounted) {
      setState(() => _playerState = state);
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

  // YouTube still shows captions with enableCaption: false (that flag only stops
  // forcing them on), and its captions module loads shortly *after* onReady, so
  // unloading it once at ready does nothing. This hook unloads the module on every
  // API/state change and polls for a few seconds in case an event was missed.
  static const String _noCaptionsJs = r'''
(function () {
  if (window.__noCaptions) return 'already';
  window.__noCaptions = true;
  window.__ccOff = function () {
    try { player.unloadModule('captions'); } catch (e) {}
    try { player.setOption('captions', 'track', {}); } catch (e) {}
  };
  player.addEventListener('onApiChange', '__ccOff');
  player.addEventListener('onStateChange', '__ccOff');
  window.__ccOff();
  var n = 0;
  var t = setInterval(function () {
    window.__ccOff();
    if (++n >= 20) clearInterval(t);
  }, 500);
  return 'installed';
})();
''';

  Future<void> _disableCaptions() async {
    final result = await _controller.value.webViewController
        ?.evaluateJavascript(source: _noCaptionsJs);
    debugPrint('[Video] captions hook: $result');
  }

  // YouTube draws its own paused screen (dark gradient, title, logo, share and a
  // play button) inside a cross-origin iframe, so the page cannot style it. A
  // document-start script limited to youtube.com runs inside that iframe instead.
  static const String _hideYoutubeUiJs = r'''
(function () {
  function add() {
    var root = document.head || document.documentElement;
    if (!root) return false;
    var s = document.createElement('style');
    s.textContent = '#player-controls, .ytp-chrome-top, .ytp-gradient-top, .ytp-gradient-bottom, .ytp-pause-overlay { display: none !important; }';
    root.appendChild(s);
    return true;
  }
  if (!add()) {
    var o = new MutationObserver(function () { if (add()) o.disconnect(); });
    o.observe(document, { childList: true });
  }
})();
''';

  void _hideYoutubeUi() {
    final web = _controller.value.webViewController;
    if (_youtubeUiHidden || web == null) return;
    _youtubeUiHidden = true;
    web
        .addUserScript(
          userScript: UserScript(
            source: _hideYoutubeUiJs,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: false,
            allowedOriginRules: {'https://www.youtube.com'},
          ),
        )
        .catchError(
          (Object e) => debugPrint('[Video] hide YouTube UI failed: $e'),
        );
  }

  // Tap anywhere on the video to play/pause (no icon is shown).
  void _togglePlayPause() {
    if (!_isPlayerReady) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _flashFullScreenBar();
  }

  void _flashFullScreenBar() {
    if (!_isFullScreen) return;
    _barTimer?.cancel();
    setState(() => _showFullScreenBar = true);
    _barTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showFullScreenBar = false);
    });
  }

  // Drag sideways to scrub (same behaviour as the player's built-in gesture).
  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragBase = _controller.value.position;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final deltaMs = ((details.globalPosition.dx - _dragStartX) * 1000).round();
    final target = _dragBase + Duration(milliseconds: deltaMs);
    setState(
      () => _dragSeekTo = target < Duration.zero ? Duration.zero : target,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final target = _dragSeekTo;
    if (target != null) _controller.seekTo(target);
    setState(() => _dragSeekTo = null);
    _flashFullScreenBar();
  }

  void _onDragCancel() {
    setState(() => _dragSeekTo = null);
  }

  String _formatClock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  void _seekForward() {
    if (!_isPlayerReady) return;
    final newPos = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPos);
    setState(() => _showForwardIndicator = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showForwardIndicator = false);
    });
  }

  void _seekBackward() {
    if (!_isPlayerReady) return;
    final current = _controller.value.position;
    final newPos = current.inSeconds > 10
        ? current - const Duration(seconds: 10)
        : Duration.zero;
    _controller.seekTo(newPos);
    setState(() => _showBackwardIndicator = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showBackwardIndicator = false);
    });
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
      /*
      final Map<String, dynamic> requestData = {
        'video_id': widget.video.videoLink,
        'action': newLikeState ? 'like' : 'unlike',
        'user_id': 'current_user_id', // Get from auth service
      };
      */

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
    _barTimer?.cancel();
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
    context.watch<ThemeProvider>();
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                flex: _isFullScreen ? 1 : 2,
                child: _videoId.isEmpty
                    ? _buildErrorView()
                    : Container(
                        color: Colors.black,
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildPlayerStack(constraints),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerStack(BoxConstraints constraints) {
    // In portrait the controls sit just under the video so they never cover the
    // picture; in fullscreen they overlay the bottom edge for a few seconds after
    // a tap.
    final videoHeight = constraints.maxWidth * 9 / 16;
    final barTop = (constraints.maxHeight + videoHeight) / 2;

    return Stack(
      children: [
        Center(
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
            onReady: () {
              debugPrint('Player is ready');
            },
            onEnded: (metaData) {
              debugPrint('Video ended');
              _showVideoEndedDialog();
            },
          ),
        ),
        // Tap anywhere to play/pause, double-tap to jump 10s, drag sideways to
        // scrub. Nothing is drawn over the video, so a paused frame stays readable.
        Positioned.fill(
          child: Row(
            children: [
              _buildTapZone(onDoubleTap: _seekBackward),
              _buildTapZone(onDoubleTap: _seekForward),
            ],
          ),
        ),
        // Backward indicator
        if (_showBackwardIndicator) _buildSeekIndicator(isForward: false),
        // Forward indicator
        if (_showForwardIndicator) _buildSeekIndicator(isForward: true),
        if (_playerState == PlayerState.buffering)
          const IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        if (_dragSeekTo != null)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatClock(_dragSeekTo!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_isFullScreen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showFullScreenBar,
              child: AnimatedOpacity(
                opacity: _showFullScreenBar ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: _buildControlsBar(),
                ),
              ),
            ),
          )
        else
          Positioned(
            top: barTop,
            left: 0,
            right: 0,
            child: _buildControlsBar(),
          ),
        if (!_isPlayerReady)
          Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildTapZone({required VoidCallback onDoubleTap}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _togglePlayPause,
        onDoubleTap: onDoubleTap,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildControlsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          CurrentPosition(controller: _controller),
          const SizedBox(width: 10),
          ProgressBar(
            controller: _controller,
            isExpanded: true,
            colors: ProgressBarColors(
              playedColor: AppColors.primary,
              handleColor: AppColors.primary,
              backgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          RemainingDuration(controller: _controller),
          PlaybackSpeedButton(controller: _controller),
          FullScreenButton(controller: _controller),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator({required bool isForward}) {
    return Positioned(
      left: isForward ? null : 0,
      right: isForward ? 0 : null,
      top: 0,
      bottom: 0,
      width: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: isForward
              ? const BorderRadius.horizontal(left: Radius.circular(60))
              : const BorderRadius.horizontal(right: Radius.circular(60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              isForward ? '+10s' : '-10s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Invalid video source: ${widget.video.videoSource.isNotEmpty ? widget.video.videoSource : widget.video.videoLink ?? widget.video.videoUrl ?? "Unknown"}',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_videoId.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Could not extract a valid YouTube ID.',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 11),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: _handleLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isLiked
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLiked
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLiking
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? AppColors.primary : Colors.white70,
                    size: 18,
                  ),
            const SizedBox(width: 6),
            Text(
              _likeCount.toString(),
              style: TextStyle(
                color: _isLiked ? AppColors.primary : Colors.white70,
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
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
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
            child: Text(
              'Replay',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
