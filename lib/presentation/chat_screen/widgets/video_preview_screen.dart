import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen in-app video preview for chat video messages — tap-to-play,
/// scrub, fullscreen, WhatsApp-style, with a download action in the app bar.
class VideoPreviewScreen extends StatefulWidget {
  final String url;
  final String? fileName;
  final Future<void> Function()? onDownload;
  final bool isDownloading;

  const VideoPreviewScreen({
    super.key,
    required this.url,
    this.fileName,
    this.onDownload,
    this.isDownloading = false,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoController
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController,
              autoPlay: true,
              looping: false,
              allowFullScreen: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: const Color(0xFF7B9FD4),
                handleColor: const Color(0xFF7B9FD4),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
              placeholder: Container(color: Colors.black),
              errorBuilder: (context, errorMessage) => Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            );
          });
        })
        .catchError((e) {
          if (mounted) setState(() => _error = 'Could not play this video');
        });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.fileName ?? 'Video',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          if (widget.onDownload != null)
            IconButton(
              icon: widget.isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: widget.isDownloading ? null : widget.onDownload,
            ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.white54)),
                ],
              )
            : _chewieController != null
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
