import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BirthdayCard — confetti burst, rising balloons, flickering candle,
// shimmering title, breathing glow border, elastic entry, tap-to-celebrate.
// ─────────────────────────────────────────────────────────────────────────────

class _BirthdayColors {
  static const hotPink = Color(0xFFEC4899);
  static const rose = Color(0xFFFF5C8A);
  static const violet = Color(0xFFA855F7);
  static const gold = Color(0xFFFFC857);

  static const gradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), rose, hotPink, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.68, 1.0],
  );
}

class _Confetti {
  final double x, startY, size, speed, phase;
  final Color color;
  final bool isCircle;
  static const _colors = [
    _BirthdayColors.gold,
    Colors.white,
    Color(0xFFFFE0EC),
    _BirthdayColors.violet,
    Color(0xFF7DD3FC),
  ];
  _Confetti({required math.Random rng})
      : x = rng.nextDouble(),
        startY = -rng.nextDouble() * 0.6,
        size = 4 + rng.nextDouble() * 5,
        speed = 0.55 + rng.nextDouble() * 0.45,
        phase = rng.nextDouble() * 2 * math.pi,
        isCircle = rng.nextBool(),
        color = _colors[rng.nextInt(_colors.length)];
}

class _Balloon {
  final double xFrac, offset, size, phase;
  final String emoji;
  static const _pool = ['🎈', '🎈', '✨', '⭐'];
  _Balloon({required math.Random rng})
      : xFrac = rng.nextDouble(),
        offset = rng.nextDouble(),
        size = 14 + rng.nextDouble() * 12,
        phase = rng.nextDouble() * 2 * math.pi,
        emoji = _pool[rng.nextInt(_pool.length)];
}

class BirthdayCard extends StatefulWidget {
  final String name;
  const BirthdayCard({super.key, required this.name});

  @override
  State<BirthdayCard> createState() => _BirthdayCardState();
}

class _BirthdayCardState extends State<BirthdayCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl; // elastic bounce entry
  late final AnimationController _glowCtrl; // breathing border glow
  late final AnimationController _shimmerCtrl; // title shimmer sweep
  late final AnimationController _flameCtrl; // candle flicker
  late final AnimationController _balloonCtrl; // rising balloons
  late final AnimationController _confettiCtrl; // idle confetti drift
  late final AnimationController _burstCtrl; // tap-triggered confetti burst

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final _rng = math.Random(7);
  late final List<_Confetti> _confetti;
  late final List<_Confetti> _burstConfetti;
  late final List<_Balloon> _balloons;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);

    _balloonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _confetti = List.generate(16, (_) => _Confetti(rng: _rng));
    _burstConfetti = List.generate(24, (_) => _Confetti(rng: _rng));
    _balloons = List.generate(7, (_) => _Balloon(rng: _rng));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _flameCtrl.dispose();
    _balloonCtrl.dispose();
    _confettiCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    _burstCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: _celebrate,
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: _BirthdayColors.hotPink
                        .withOpacity(0.32 + 0.2 * _glowCtrl.value),
                    blurRadius: 22 + 12 * _glowCtrl.value,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: _BirthdayColors.gradient,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _BirthdayColors.gold.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // ── Rising balloons (background) ─────────────────────
                  // Positioned.fill so these decorative layers never affect
                  // the Stack's intrinsic size — only the real content below
                  // should determine the card's height.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _balloonCtrl,
                      builder: (_, __) => LayoutBuilder(
                        builder: (_, c) {
                          final w = c.maxWidth;
                          final h = c.maxHeight;
                          return Stack(
                            children: _balloons.map((b) {
                              final t = (_balloonCtrl.value + b.offset) % 1.0;
                              final x = b.xFrac * w;
                              final y = h - (h + 30) * t;
                              final op =
                                  math.sin(t * math.pi).clamp(0.0, 1.0) * 0.32;
                              return Positioned(
                                left: x + math.sin(t * 2 * math.pi + b.phase) * 10,
                                top: y,
                                child: Opacity(
                                  opacity: op,
                                  child: Text(b.emoji,
                                      style: TextStyle(fontSize: b.size)),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Idle confetti drift ──────────────────────────────
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _confettiCtrl,
                      builder: (_, __) => LayoutBuilder(
                        builder: (_, c) {
                          final w = c.maxWidth;
                          final h = c.maxHeight;
                          return Stack(
                            children: _confetti.map((p) {
                              final t = (_confettiCtrl.value * p.speed +
                                      p.phase / (2 * math.pi)) %
                                  1.0;
                              final x = p.x * w;
                              final y = (p.startY + t) * h;
                              final op =
                                  math.sin(t * math.pi).clamp(0.0, 1.0) * 0.4;
                              return Positioned(
                                left: x + math.sin(t * 4 * math.pi + p.phase) * 8,
                                top: y,
                                child: Opacity(
                                  opacity: op,
                                  child: Container(
                                    width: p.size,
                                    height: p.size,
                                    decoration: BoxDecoration(
                                      color: p.color,
                                      shape: p.isCircle
                                          ? BoxShape.circle
                                          : BoxShape.rectangle,
                                      borderRadius: p.isCircle
                                          ? null
                                          : BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Tap-triggered confetti burst ─────────────────────
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _burstCtrl,
                      builder: (_, __) {
                        if (_burstCtrl.value == 0) return const SizedBox.shrink();
                        return LayoutBuilder(
                          builder: (_, c) {
                            final cx = c.maxWidth / 2;
                            const cy = 46.0;
                            return Stack(
                              children: _burstConfetti.map((p) {
                                final t = Curves.easeOut.transform(_burstCtrl.value);
                                final angle = p.phase;
                                final dist = 90 * p.speed * t;
                                final dx = math.cos(angle) * dist;
                                final dy = math.sin(angle) * dist - (40 * t * t);
                                final op = (1 - t).clamp(0.0, 1.0);
                                return Positioned(
                                  left: cx + dx,
                                  top: cy + dy,
                                  child: Opacity(
                                    opacity: op,
                                    child: Container(
                                      width: p.size + 2,
                                      height: p.size + 2,
                                      decoration: BoxDecoration(
                                        color: p.color,
                                        shape: p.isCircle
                                            ? BoxShape.circle
                                            : BoxShape.rectangle,
                                        borderRadius: p.isCircle
                                            ? null
                                            : BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Soft radial highlight ────────────────────────────
                  Positioned(
                    top: -40,
                    left: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x33FFFFFF), Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // ── Content ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCake(),
                        const SizedBox(width: 16),
                        Expanded(child: _buildText()),
                      ],
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

  // ── Cake with flickering candle ────────────────────────────────────────────

  Widget _buildCake() {
    return SizedBox(
      width: 64,
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFE0EC), Color(0xFFFF5C8A)],
                center: Alignment(0, -0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: _BirthdayColors.gold.withOpacity(0.45),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Text('🎂', style: TextStyle(fontSize: 34)),
          ),
          // Flickering flame glow, floating just above the cake's candle.
          Positioned(
            top: -6,
            child: AnimatedBuilder(
              animation: _flameCtrl,
              builder: (_, __) {
                final s = 0.85 + _flameCtrl.value * 0.3;
                final op = 0.55 + _flameCtrl.value * 0.45;
                return Transform.scale(
                  scale: s,
                  child: Opacity(
                    opacity: op,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFF9C4),
                            _BirthdayColors.gold,
                            Color(0x00FFC857),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _BirthdayColors.gold.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Text block ───────────────────────────────────────────────────────────

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: const Text(
            '🎉  It\'s Your Day!',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Shimmering title
        AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, __) {
            final p = _shimmerCtrl.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: const [
                  Colors.white,
                  _BirthdayColors.gold,
                  Colors.white,
                  Colors.white,
                ],
                stops: [
                  (p - 0.35).clamp(0.0, 1.0),
                  p.clamp(0.0, 1.0),
                  (p + 0.15).clamp(0.0, 1.0),
                  1.0,
                ],
              ).createShader(bounds),
              child: const Text(
                'Happy Birthday!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Wishing you an amazing day and a wonderful year ahead, ${widget.name}!',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap for confetti 🎊',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}
