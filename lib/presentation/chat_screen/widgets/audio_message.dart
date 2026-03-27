import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// ── Result ─────────────────────────────────────────────────────────────────────
class VoiceRecordingResult {
  final File file;
  final Duration duration;
  const VoiceRecordingResult({required this.file, required this.duration});
}

// ── Public API ─────────────────────────────────────────────────────────────────
Future<VoiceRecordingResult?> showVoiceRecorderSheet(BuildContext context) {
  return showModalBottomSheet<VoiceRecordingResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _VoiceRecorderSheet(),
  );
}

// ── Sheet widget ───────────────────────────────────────────────────────────────
class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet();
  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet>
    with SingleTickerProviderStateMixin {
  // ── Record ─────────────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasStopped = false;
  String? _filePath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // ── Amplitude / waveform ────────────────────────────────────────────────────
  final List<double> _bars = List.filled(36, 2.0);
  Timer? _ampTimer;
  final _rng = math.Random();

  // ── Blink animation for recording dot ──────────────────────────────────────
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blinkAnim = CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut);

    // Auto-start
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _timer?.cancel();
    _ampTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ── Controls ────────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.mic_off, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Microphone permission denied'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _elapsed = Duration.zero;
    });

    _startElapsedTimer();
    _startAmpSampler();
    HapticFeedback.mediumImpact();
  }

  Future<void> _pause() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    await _recorder.pause();
    if (mounted) setState(() => _isPaused = true);
    HapticFeedback.lightImpact();
  }

  Future<void> _resume() async {
    await _recorder.resume();
    if (!mounted) return;
    setState(() => _isPaused = false);
    _startElapsedTimer();
    _startAmpSampler();
    HapticFeedback.lightImpact();
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    if (_isRecording || _isPaused) await _recorder.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasStopped = true;
      });
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    if (_isRecording || _isPaused) await _recorder.stop();
    if (_filePath != null) {
      final f = File(_filePath!);
      if (await f.exists()) await f.delete();
    }
    if (mounted) Navigator.pop(context, null);
  }

  void _send() {
    if (_filePath == null) return;
    Navigator.pop(
      context,
      VoiceRecordingResult(file: File(_filePath!), duration: _elapsed),
    );
  }

  // ── Timers ───────────────────────────────────────────────────────────────────
  void _startElapsedTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _startAmpSampler() {
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!mounted) return;
      double h;
      try {
        final amp = await _recorder.getAmplitude();
        // amp.current is in dBFS (-160 to 0). Map to bar height 2..36
        final db = amp.current.clamp(-60.0, 0.0);
        final ratio = (db + 60.0) / 60.0; // 0..1
        h = 2.0 + ratio * 34.0;
        // Add jitter so it looks lively even at low amplitude
        h = (h + _rng.nextDouble() * 4 - 2).clamp(2.0, 36.0);
      } catch (_) {
        h = 2.0 + _rng.nextDouble() * 8;
      }
      if (!mounted) return;
      setState(() {
        _bars.removeAt(0);
        _bars.add(h);
      });
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isActive = _isRecording && !_isPaused;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),

          // ── Status row ─────────────────────────────────────────────────
          Row(
            children: [
              // Mic icon with coloured bg
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.red.shade50
                      : _hasStopped
                      ? const Color(0xFF7B9FD4).withOpacity(0.1)
                      : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive
                      ? Icons.mic_rounded
                      : _isPaused
                      ? Icons.pause_rounded
                      : _hasStopped
                      ? Icons.check_rounded
                      : Icons.mic_rounded,
                  color: isActive
                      ? Colors.red.shade500
                      : _isPaused
                      ? Colors.orange.shade600
                      : _hasStopped
                      ? const Color(0xFF7B9FD4)
                      : Colors.grey.shade400,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasStopped
                          ? 'Ready to send'
                          : _isPaused
                          ? 'Paused'
                          : 'Recording…',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Timer
                    Text(
                      _fmtDuration(_elapsed),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? Colors.red.shade500
                            : Colors.grey.shade700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Blinking dot when recording
              if (isActive)
                AnimatedBuilder(
                  animation: _blinkAnim,
                  builder: (_, __) => Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500.withOpacity(
                        0.3 + _blinkAnim.value * 0.7,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Waveform bars ───────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_bars.length, (i) {
                double h;
                Color barColor;
                if (_hasStopped || _isPaused) {
                  // Static "frozen" waveform
                  h = 4.0 + (_bars[i]).clamp(2.0, 36.0) * 0.5;
                  barColor = _hasStopped
                      ? const Color(0xFF7B9FD4).withOpacity(0.6)
                      : Colors.orange.shade300.withOpacity(0.7);
                } else {
                  h = _bars[i];
                  barColor = Colors.red.shade400;
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 32),

          // ── Buttons ─────────────────────────────────────────────────────
          if (!_hasStopped) ...[
            // ── Still recording ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Delete / cancel
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  iconColor: Colors.red.shade400,
                  bgColor: Colors.red.shade50,
                  onTap: _cancel,
                ),
                // Big stop button centre
                GestureDetector(
                  onTap: _stop,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade200,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                // Pause / Resume
                _ActionButton(
                  icon: _isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: _isPaused ? 'Resume' : 'Pause',
                  iconColor: Colors.orange.shade600,
                  bgColor: Colors.orange.shade50,
                  onTap: _isPaused ? _resume : _pause,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap ■ to stop and preview',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            // ── After stop: Delete + Send ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B9FD4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Send Voice',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small circular action button helper ───────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
