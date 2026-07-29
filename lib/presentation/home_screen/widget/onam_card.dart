import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onam Festival Data
// ─────────────────────────────────────────────────────────────────────────────

class OnamDayInfo {
  final int dayNumber; // 1 = Atham … 10 = Thiruvonam, 0 = coming soon
  final String dayName;
  final String subtitle;
  final String emoji;

  const OnamDayInfo({
    required this.dayNumber,
    required this.dayName,
    required this.subtitle,
    required this.emoji,
  });
}

const List<OnamDayInfo> onamDays = [
  OnamDayInfo(dayNumber: 1,  dayName: 'Atham',       subtitle: 'The journey begins!',           emoji: '🌸'),
  OnamDayInfo(dayNumber: 2,  dayName: 'Chithira',    subtitle: 'Colours fill the air',           emoji: '🎨'),
  OnamDayInfo(dayNumber: 3,  dayName: 'Chodhi',      subtitle: 'Pookalam in full bloom',         emoji: '🪷'),
  OnamDayInfo(dayNumber: 4,  dayName: 'Vishakam',    subtitle: 'Community and joy',              emoji: '🤝'),
  OnamDayInfo(dayNumber: 5,  dayName: 'Anizham',     subtitle: 'Snake boat races begin',         emoji: '🚣'),
  OnamDayInfo(dayNumber: 6,  dayName: 'Thriketta',   subtitle: 'Legends and tales',              emoji: '📖'),
  OnamDayInfo(dayNumber: 7,  dayName: 'Moolam',      subtitle: 'Markets and festivities',        emoji: '🛍️'),
  OnamDayInfo(dayNumber: 8,  dayName: 'Pooradam',    subtitle: 'Preparations reach their peak',  emoji: '🌺'),
  OnamDayInfo(dayNumber: 9,  dayName: 'Uthradom',    subtitle: "Eve of Mahabali's arrival",      emoji: '👑'),
  OnamDayInfo(dayNumber: 10, dayName: 'Thiruvonam',  subtitle: 'Grand celebration!',             emoji: '🎉'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Date helper
// ─────────────────────────────────────────────────────────────────────────────

class OnamDateHelper {
  static OnamDayInfo getTodayOnamDay() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Onam 2025: Atham = Aug 22
    final atham2025 = DateTime(2025, 8, 22);
    // Onam 2026: Atham ≈ Sep 10 (update when official dates are confirmed)
    final atham2026 = DateTime(2026, 9, 10);

    DateTime atham;
    if (now.year <= 2025) {
      atham = atham2025;
    } else {
      atham = atham2026;
    }

    final diff = today.difference(atham).inDays;

    // Active festival days (Atham = 0, Thiruvonam = 9)
    if (diff >= 0 && diff < 10) return onamDays[diff];

    // After festival — next year teaser
    if (diff >= 10) {
      return const OnamDayInfo(
        dayNumber: 0,
        dayName:   'Onam Celebrations',
        subtitle:  'Onam is celebrated every year — stay tuned! 🌾',
        emoji:     '🌺',
      );
    }

    // Before Atham — countdown (always show)
    final daysLeft = -diff;
    if (daysLeft == 1) {
      return const OnamDayInfo(
        dayNumber: 0,
        dayName:   'Onam Starts Tomorrow!',
        subtitle:  'Get ready — Atham begins tomorrow! 🎊',
        emoji:     '🌸',
      );
    }
    return OnamDayInfo(
      dayNumber: 0,
      dayName:   'Onam is Coming!',
      subtitle:  '$daysLeft days to Atham — the harvest festival awaits! 🌾',
      emoji:     '🌼',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main animated card
// ─────────────────────────────────────────────────────────────────────────────

class OnamFestivalCard extends StatefulWidget {
  final OnamDayInfo dayInfo;
  const OnamFestivalCard({super.key, required this.dayInfo});

  @override
  State<OnamFestivalCard> createState() => _OnamFestivalCardState();
}

class _OnamFestivalCardState extends State<OnamFestivalCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<Offset> _slideAnim;
  late final Animation<double>  _fadeAnim;
  late final Animation<double>  _scaleAnim;
  late final Animation<double>  _pulseAnim;

  late final List<_Petal> _petals;
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.6)));
    _scaleAnim = Tween<double>(begin: 0.88, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));

    _floatCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulseAnim   = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _petals = List.generate(14, (_) => _Petal(rng: _rng));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final isThiruvonam = widget.dayInfo.dayNumber == 10;
    final isComingSoon = widget.dayInfo.dayNumber == 0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Gold shimmer top bar
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) {
              final sv = _shimmerCtrl.value;
              return Positioned(
                top: 0, left: 0, right: 0, height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFFFFC300),
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                        Color(0xFFFFD700),
                        Color(0xFFFFC300),
                      ],
                      stops: [
                        0.0,
                        (sv - 0.1).clamp(0.0, 1.0),
                        sv.clamp(0.0, 1.0),
                        (sv + 0.1).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating petals
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, __) => LayoutBuilder(
              builder: (_, constraints) {
                final w = constraints.maxWidth;
                final h = 220.0;
                return SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    children: _petals.map((p) {
                      final t = (_floatCtrl.value + p.offset) % 1.0;
                      final x = p.xFrac * w;
                      final y = h - (h + 30) * t;
                      final opacity = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.65;
                      return Positioned(
                        left: x + math.sin(t * 2 * math.pi + p.swayPhase) * 14,
                        top: y,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Big backdrop emojis
          Positioned(
            right: -18, top: -18,
            child: Text('🌺',
                style: TextStyle(fontSize: 110, color: Colors.white.withOpacity(0.07))),
          ),
          Positioned(
            left: -10, bottom: -10,
            child: Text('🦚',
                style: TextStyle(fontSize: 90, color: Colors.white.withOpacity(0.07))),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: const _PookkalamIcon(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBadge(isThiruvonam, isComingSoon),
                          const SizedBox(height: 6),
                          Text(
                            isComingSoon
                                ? widget.dayInfo.dayName
                                : 'Happy ${widget.dayInfo.dayName}!',
                            style: TextStyle(
                              fontSize: isThiruvonam ? 22 : 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(widget.dayInfo.emoji, style: const TextStyle(fontSize: 38)),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Subtitle ─────────────────────────────────────────
                Text(
                  widget.dayInfo.subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Day progress bar ─────────────────────────────────
                if (!isComingSoon) _buildDayProgressBar(),
                if (!isComingSoon) const SizedBox(height: 14),

                // ── Footer chip ──────────────────────────────────────
                _buildFooterChip(isThiruvonam, isComingSoon),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(bool isThiruvonam, bool isComingSoon) {
    String label;
    if (isComingSoon) {
      label = '🌼 Coming Soon';
    } else if (isThiruvonam) {
      label = '✨ Grand Finale — Day 10';
    } else {
      label = 'Day ${widget.dayInfo.dayNumber} of 10';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isComingSoon
            ? Colors.white.withOpacity(0.12)
            : const Color(0xFFFFD700).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: isComingSoon
            ? null
            : Border.all(
                color: const Color(0xFFFFD700).withOpacity(isThiruvonam ? 1.0 : 0.5),
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isComingSoon ? Colors.white : const Color(0xFFFFD700),
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildDayProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onam Journey',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(10, (i) {
            final dayNum = i + 1;
            final isPast   = dayNum < widget.dayInfo.dayNumber;
            final isToday  = dayNum == widget.dayInfo.dayNumber;

            return Expanded(
              child: Tooltip(
                message: onamDays[i].dayName,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + i * 60),
                  height: isToday ? 10 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFFFD700)
                        : isPast
                            ? const Color(0xFF95D5B2)
                            : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isToday
                      ? Center(
                          child: Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B4332),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Atham', style: TextStyle(fontSize: 9, color: Colors.white54)),
            Text('Thiruvonam', style: TextStyle(fontSize: 9, color: Colors.white54)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterChip(bool isThiruvonam, bool isComingSoon) {
    final text = isThiruvonam
        ? '🎊 Mahabali arrives today!'
        : isComingSoon
            ? '🌾 Harvest season is near'
            : '🌾 Onam Ashamsakal from Luminar!';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pookalam icon (CustomPainter)
// ─────────────────────────────────────────────────────────────────────────────

class _PookkalamIcon extends StatelessWidget {
  const _PookkalamIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(painter: _PookkalamPainter()),
    );
  }
}

class _PookkalamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    const petalColors = [
      Color(0xFFFFD700), Color(0xFFFF6B6B), Color(0xFFFF9F43),
      Color(0xFFA8E063), Color(0xFF48DBFB), Color(0xFFFF9FF3),
      Color(0xFFFFC0CB), Color(0xFFBDC3C7),
    ];

    for (int i = 0; i < 8; i++) {
      final angle = (2 * math.pi / 8) * i;
      final px = cx + math.cos(angle) * r * 0.52;
      final py = cy + math.sin(angle) * r * 0.52;
      canvas.drawCircle(
        Offset(px, py),
        r * 0.22,
        Paint()..color = petalColors[i],
      );
    }

    canvas.drawCircle(
      Offset(cx, cy), r * 0.28,
      Paint()..color = const Color(0xFFFFD700).withOpacity(0.55),
    );
    canvas.drawCircle(
      Offset(cx, cy), r * 0.14,
      Paint()..color = const Color(0xFFFFF3CD),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Petal data
// ─────────────────────────────────────────────────────────────────────────────

class _Petal {
  final double xFrac;
  final double offset;
  final double size;
  final double swayPhase;
  final String emoji;

  static const _emojis = ['🌸', '🌺', '🌼', '🪷', '🌻', '🍀'];

  _Petal({required math.Random rng})
      : xFrac     = rng.nextDouble(),
        offset    = rng.nextDouble(),
        size      = 10 + rng.nextDouble() * 10,
        swayPhase = rng.nextDouble() * 2 * math.pi,
        emoji     = _emojis[rng.nextInt(_emojis.length)];
}
