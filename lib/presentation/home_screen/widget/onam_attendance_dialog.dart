import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnamRegistrationWindow — shared cutoff for the popup + card CTA
// ─────────────────────────────────────────────────────────────────────────────

class OnamRegistrationWindow {
  /// Last day attendance registration is open. Inclusive — the popup and CTA
  /// still show on Aug 17 2026 itself, and disappear from Aug 18 onward.
  static final DateTime deadline = DateTime(2026, 8, 17, 23, 59, 59);

  static bool get isOpen => !DateTime.now().isAfter(deadline);
}

// ─────────────────────────────────────────────────────────────────────────────
// OnamAttendanceDialogHelper — decides whether to show the popup
// ─────────────────────────────────────────────────────────────────────────────

class OnamAttendanceDialogHelper {
  static const String _prefsKey = 'onam_attendance_dialog_shown';

  /// Shows the attendance popup at most once ever, and never after the
  /// registration deadline has passed.
  static Future<void> maybeShow(BuildContext context) async {
    if (!OnamRegistrationWindow.isOpen) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) == true) return;
    await prefs.setBool(_prefsKey, true);

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const OnamAttendanceDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onam palette (matches the dashboard's Onam notice card)
// ─────────────────────────────────────────────────────────────────────────────

class _DialogColors {
  static const deepSaffron = Color(0xFF6D1A00);
  static const saffron = Color(0xFFBF360C);
  static const orange = Color(0xFFE64A19);
  static const amber = Color(0xFFFF6F00);
  static const gold = Color(0xFFFFB300);
  static const cream = Color(0xFFFFF8E1);

  static const gradient = LinearGradient(
    colors: [deepSaffron, saffron, orange, amber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.65, 1.0],
  );
}

const String _attendanceUrl = 'https://student.luminartechnolab.com/onam';

// ─────────────────────────────────────────────────────────────────────────────
// OnamAttendanceDialog
// ─────────────────────────────────────────────────────────────────────────────

class OnamAttendanceDialog extends StatefulWidget {
  const OnamAttendanceDialog({super.key});

  @override
  State<OnamAttendanceDialog> createState() => _OnamAttendanceDialogState();
}

class _OnamAttendanceDialogState extends State<OnamAttendanceDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final _rng = math.Random(7);
  late final List<_Petal> _petals;

  bool _launching = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _petals = List.generate(10, (_) => _Petal(rng: _rng));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _markPresence() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final uri = Uri.parse(_attendanceUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(scale: _scaleAnim, child: _buildCard()),
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _DialogColors.amber
                  .withOpacity(0.35 + 0.2 * _glowCtrl.value),
              blurRadius: 26 + 12 * _glowCtrl.value,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: _DialogColors.gradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _DialogColors.gold.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // Floating petals background
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) => LayoutBuilder(
                builder: (_, c) {
                  const h = 260.0;
                  return SizedBox(
                    width: c.maxWidth,
                    height: h,
                    child: Stack(
                      children: _petals.map((p) {
                        final t = (_floatCtrl.value + p.offset) % 1.0;
                        final x = p.xFrac * c.maxWidth;
                        final y = h - (h + 30) * t;
                        final op =
                            math.sin(t * math.pi).clamp(0.0, 1.0) * 0.5;
                        return Positioned(
                          left: x + math.sin(t * 2 * math.pi + p.phase) * 12,
                          top: y,
                          child: Opacity(
                            opacity: op,
                            child: Text(
                              p.emoji,
                              style: TextStyle(fontSize: p.size),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              right: -20,
              top: -20,
              child: Text(
                '🌺',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: _CloseButton(onTap: () => Navigator.of(context).pop()),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _rotateCtrl,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFE082), Color(0xFFFF6F00)],
                          center: Alignment(0, -0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _DialogColors.gold.withOpacity(0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🌺', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Onam Celebration 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join us in celebrating the festival of joy, prosperity, '
                    'and togetherness. Register your attendance now!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _DialogColors.cream.withOpacity(0.92),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GlowingPresenceButton(
                    glowCtrl: _glowCtrl,
                    loading: _launching,
                    onTap: _markPresence,
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

// ─────────────────────────────────────────────────────────────────────────────
// Close button
// ─────────────────────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing "Mark Your Presence" button — reusable so the dashboard's Onam
// notice card can render the same control (see onam_event_card.dart).
// ─────────────────────────────────────────────────────────────────────────────

class _GlowingPresenceButton extends StatelessWidget {
  final AnimationController glowCtrl;
  final bool loading;
  final VoidCallback onTap;

  const _GlowingPresenceButton({
    required this.glowCtrl,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _DialogColors.gold.withOpacity(0.45 + 0.4 * glowCtrl.value),
              blurRadius: 14 + 14 * glowCtrl.value,
              spreadRadius: 1 * glowCtrl.value,
            ),
          ],
        ),
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFF6D1A00),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF6D1A00),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mark Your Presence',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6D1A00),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Petal data
// ─────────────────────────────────────────────────────────────────────────────

class _Petal {
  final double xFrac;
  final double offset;
  final double size;
  final double phase;
  final String emoji;

  static const _emojis = ['🌸', '🌺', '🌼', '🪷', '✨'];

  _Petal({required math.Random rng})
      : xFrac = rng.nextDouble(),
        offset = rng.nextDouble(),
        size = 10 + rng.nextDouble() * 8,
        phase = rng.nextDouble() * 2 * math.pi,
        emoji = _emojis[rng.nextInt(_emojis.length)];
}
