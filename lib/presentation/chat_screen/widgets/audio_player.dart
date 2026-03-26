import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Audio bubble player.
///
/// Fixes Android MEDIA_ERROR_SYSTEM with .m4a CloudFront URLs by downloading
/// the file to a temp path first, then playing from DeviceFileSource.
/// This bypasses Android's MediaPlayer HTTPS/codec issues with certain CDNs.
class AudioMessagePlayer extends StatefulWidget {
  final String url;
  final String? fileName;
  final bool isMe;
  final bool isUploading;
  final double uploadProgress;

  const AudioMessagePlayer({
    super.key,
    required this.url,
    this.fileName,
    required this.isMe,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // download state
  bool _isDownloading = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _localPath; // cached local file path after download

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
      if (s == PlayerState.completed) {
        setState(() => _position = Duration.zero);
      }
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  bool get _isPlaying => _playerState == PlayerState.playing;

  // ── Download to temp then play ─────────────────────────────────────────────
  Future<String?> _ensureLocalFile() async {
    if (_localPath != null) {
      if (await File(_localPath!).exists()) return _localPath;
    }

    setState(() => _isDownloading = true);
    try {
      final response = await http
          .get(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      // Derive a safe filename
      final ext = widget.url.contains('.')
          ? widget.url.split('.').last.split('?').first
          : 'm4a';
      final safeName = 'audio_${widget.url.hashCode.abs()}.$ext';
      final path = '${dir.path}/$safeName';

      await File(path).writeAsBytes(response.bodyBytes, flush: true);
      _localPath = path;
      debugPrint('[AudioPlayer] downloaded → $path');
      return path;
    } catch (e) {
      debugPrint('[AudioPlayer] download error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _togglePlay() async {
    if (widget.isUploading || widget.url.isEmpty) return;
    if (_hasError) {
      // Allow retry on tap
      setState(() => _hasError = false);
    }

    try {
      if (_isPlaying) {
        await _player.pause();
        return;
      }

      if (_playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }

      // Stopped or completed — need to (re)load
      setState(() => _isLoading = true);

      final localPath = await _ensureLocalFile();
      if (!mounted) return;

      if (localPath == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      await _player.play(DeviceFileSource(localPath));
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[AudioPlayer] play error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _seekTo(double ratio) async {
    if (_duration == Duration.zero) return;
    final ms = (ratio * _duration.inMilliseconds).round().clamp(
      0,
      _duration.inMilliseconds,
    );
    await _player.seek(Duration(milliseconds: ms));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isMe
        ? const Color(0xFF4A7FA5)
        : const Color(0xFF7B9FD4);
    final bgColor = widget.isMe
        ? const Color(0xFFC5D8EF).withOpacity(0.5)
        : Colors.grey.shade100;

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final displayProgress = widget.isUploading
        ? (widget.uploadProgress > 0 ? widget.uploadProgress : 0.0)
        : progress;

    final timeLabel = widget.isUploading
        ? 'Uploading…'
        : _isDownloading
        ? 'Loading…'
        : _duration > Duration.zero
        ? '${_fmt(_position)} / ${_fmt(_duration)}'
        : '--:--';

    final bool isBusy = widget.isUploading || _isDownloading || _isLoading;

    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Play / Pause / Spinner / Error ───────────────────────────
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isBusy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: widget.isUploading && widget.uploadProgress > 0
                              ? widget.uploadProgress
                              : null,
                          strokeWidth: 2.5,
                          color: accent,
                        ),
                      )
                    : _hasError
                    ? Tooltip(
                        message: 'Tap to retry',
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.red.shade400,
                          size: 22,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: accent,
                        size: 26,
                      ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Progress bar + labels ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seekable bar
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final barW = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _seekTo(d.localPosition.dx / barW),
                      onHorizontalDragUpdate: (d) =>
                          _seekTo(d.localPosition.dx / barW),
                      child: SizedBox(
                        height: 20,
                        child: Align(
                          alignment: Alignment.center,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Track
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Fill
                              FractionallySizedBox(
                                widthFactor: displayProgress,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Thumb
                              if (!widget.isUploading)
                                Positioned(
                                  left: (displayProgress * barW - 5).clamp(
                                    0.0,
                                    barW - 10,
                                  ),
                                  top: -4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.fileName ?? 'Voice message',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _hasError ? Colors.red.shade400 : accent,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
