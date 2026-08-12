import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shows a real frame from a network video as its preview — initializes a
/// paused VideoPlayerController and renders its first decoded frame. Uses
/// the same playback pipeline as the in-app player (video_player), so it
/// doesn't depend on the separate native thumbnail generator that kept
/// failing on some video URLs.
class VideoThumbnailPreview extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const VideoThumbnailPreview({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<VideoThumbnailPreview> createState() => _VideoThumbnailPreviewState();
}

class _VideoThumbnailPreviewState extends State<VideoThumbnailPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      await controller.setVolume(0);
      await controller.pause();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final size = controller.value.size;
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: _failed
            ? Icon(
                Icons.movie_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 48,
              )
            : const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              ),
      ),
    );
  }
}
