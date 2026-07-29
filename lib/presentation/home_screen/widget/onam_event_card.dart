import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Branch Event Data
// ─────────────────────────────────────────────────────────────────────────────

enum LuminarBranch { kochi, calicut, thrissur, trivandrum, unknown }

class OnamEventInfo {
  final LuminarBranch branch;
  final String branchDisplayName;
  final String date;
  final String time;
  final String venue;
  final String venueShort;
  final List<String> programs;
  final Color accentColor;
  final String emoji;

  const OnamEventInfo({
    required this.branch,
    required this.branchDisplayName,
    required this.date,
    required this.time,
    required this.venue,
    required this.venueShort,
    required this.programs,
    required this.accentColor,
    required this.emoji,
  });
}

const _events = <LuminarBranch, OnamEventInfo>{
  LuminarBranch.kochi: OnamEventInfo(
    branch: LuminarBranch.kochi,
    branchDisplayName: 'Kochi Branch',
    date: '19 August 2026',
    time: '10:00 AM – 5:00 PM',
    venue: 'Community Hall, Trikkakara',
    venueShort: 'Trikkakara',
    programs: ['🎭 Cultural Programs', '🍛 Grand Sadhya', '🎵 Music Event'],
    accentColor: Color(0xFF29B6F6),
    emoji: '🌊',
  ),
  LuminarBranch.calicut: OnamEventInfo(
    branch: LuminarBranch.calicut,
    branchDisplayName: 'Calicut Branch',
    date: '20 August 2026',
    time: '9:00 AM – 4:00 PM',
    venue: 'City House Auditorium, Calicut',
    venueShort: 'City House Auditorium',
    programs: ['🎭 Cultural Programs', '🍛 Grand Sadhya', '🎵 Music Event'],
    accentColor: Color(0xFFCE93D8),
    emoji: '🏔️',
  ),
  LuminarBranch.thrissur: OnamEventInfo(
    branch: LuminarBranch.thrissur,
    branchDisplayName: 'Thrissur Branch',
    date: '18 August 2026',
    time: '10:00 AM – 4:00 PM',
    venue: 'Sreenivasa Kalyana Mandapam, Kolazhy, Thrissur',
    venueShort: 'Sreenivasa Kalyana Mandapam',
    programs: ['🎭 Cultural Programs', '🍛 Grand Sadhya', '🎵 Music Event'],
    accentColor: Color(0xFF80CBC4),
    emoji: '🌿',
  ),
  LuminarBranch.trivandrum: OnamEventInfo(
    branch: LuminarBranch.trivandrum,
    branchDisplayName: 'Trivandrum Branch',
    date: '21 August 2026',
    time: '10:00 AM – 3:00 PM',
    venue: 'Laith Mahal, West Fort, Trivandrum',
    venueShort: 'Laith Mahal',
    programs: ['🎭 Cultural Programs', '🍛 Grand Sadhya', '🎵 Music Event'],
    accentColor: Color(0xFFEF9A9A),
    emoji: '⚓',
  ),
};

// ── Branch detection ──────────────────────────────────────────────────────────

class OnamEventHelper {
  static LuminarBranch detectBranch(String? batchName) {
    if (batchName == null || batchName.isEmpty) return LuminarBranch.unknown;
    final lower = batchName.toLowerCase();

    // API location values (batch_info.location.value)
    if (lower == 'cochin' || lower == 'kochi' || lower == 'ernakulam' ||
        lower.contains('kochi') || lower.contains('ernakulam') ||
        lower.contains('cochin') || lower.contains('kml') ||
        lower.contains('kalamassery') || lower.contains('kakkanad') ||
        lower.contains('ekm')) {
      return LuminarBranch.kochi;
    }
    if (lower == 'calicut' || lower == 'kozhikode' ||
        lower.contains('calicut') || lower.contains('kozhikode') ||
        lower.contains('clt') || lower.contains('kozhi')) {
      return LuminarBranch.calicut;
    }
    if (lower == 'thrissur' || lower == 'trichur' ||
        lower.contains('thrissur') || lower.contains('trichur') ||
        lower.contains('tsr') || lower.contains('tcr')) {
      return LuminarBranch.thrissur;
    }
    if (lower == 'trivandrum' || lower == 'thiruvananthapuram' ||
        lower.contains('trivandrum') || lower.contains('thiruvananthapuram') ||
        lower.contains('tvm') || lower.contains('tvpm')) {
      return LuminarBranch.trivandrum;
    }
    return LuminarBranch.unknown;
  }

  static OnamEventInfo? getEventForBranch(LuminarBranch branch) =>
      _events[branch];
}

// ─────────────────────────────────────────────────────────────────────────────
// Float emoji helper
// ─────────────────────────────────────────────────────────────────────────────

class _FloatEmoji {
  final double xFrac, offset, size, phase;
  final String emoji;
  static const _pool = ['🌸', '🌺', '🌼', '🪷', '🍀', '🌿', '✨'];
  _FloatEmoji({required math.Random rng})
      : xFrac  = rng.nextDouble(),
        offset = rng.nextDouble(),
        size   = 10 + rng.nextDouble() * 10,
        phase  = rng.nextDouble() * 2 * math.pi,
        emoji  = _pool[rng.nextInt(_pool.length)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Static decorative emoji spec
// ─────────────────────────────────────────────────────────────────────────────

class _DecorEmoji {
  final String emoji;
  final double? top, bottom, left, right;
  final double size, opacity;
  const _DecorEmoji({
    required this.emoji,
    this.top, this.bottom, this.left, this.right,
    required this.size,
    required this.opacity,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// OnamAllBranchesCard — green theme, tap to expand
// ─────────────────────────────────────────────────────────────────────────────

class OnamAllBranchesCard extends StatefulWidget {
  const OnamAllBranchesCard({super.key});

  @override
  State<OnamAllBranchesCard> createState() => _OnamAllBranchesCardState();
}

class _OnamAllBranchesCardState extends State<OnamAllBranchesCard>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _expandCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<Offset> _slideAnim;
  late final Animation<double>  _fadeAnim;
  late final Animation<double>  _expandAnim;
  late final Animation<double>  _chevronAnim;

  bool _expanded = false;

  static final _allEvents = [
    _events[LuminarBranch.thrissur]!,
    _events[LuminarBranch.kochi]!,
    _events[LuminarBranch.calicut]!,
    _events[LuminarBranch.trivandrum]!,
  ];

  // Green colour palette (matching screenshot)
  static const _darkGreen = Color(0xFF1B5E20);
  static const _midGreen  = Color(0xFF2E7D32);

  // Static decorative emojis placed like in the screenshot
  static const _decor = [
    _DecorEmoji(emoji: '🌼', top: 10, left: 110, size: 22, opacity: 0.85),
    _DecorEmoji(emoji: '🌺', top:  6, right: 14, size: 28, opacity: 0.9),
    _DecorEmoji(emoji: '🌸', bottom: 16, left: 16, size: 18, opacity: 0.55),
    _DecorEmoji(emoji: '🍀', bottom: 10, right: 68, size: 16, opacity: 0.5),
    _DecorEmoji(emoji: '🌿', top: 52, right: 38, size: 14, opacity: 0.4),
  ];

  final _rng = math.Random(42);
  late final List<_FloatEmoji> _floaters;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.65)));

    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _expandAnim  = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
    _chevronAnim = Tween<double>(begin: 0, end: 0.5)
        .animate(CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))..repeat();

    _floaters = List.generate(8, (_) => _FloatEmoji(rng: _rng));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _expandCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _midGreen.withOpacity(0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // ── Floating petals (background) ─────────────────────────
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, __) => LayoutBuilder(
                    builder: (_, c) {
                      const h = 150.0;
                      return SizedBox(
                        width: c.maxWidth, height: h,
                        child: Stack(
                          children: _floaters.map((f) {
                            final t = (_floatCtrl.value + f.offset) % 1.0;
                            final x = f.xFrac * c.maxWidth;
                            final y = h - (h + 20) * t;
                            final op = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.28;
                            return Positioned(
                              left: x + math.sin(t * 2 * math.pi + f.phase) * 8,
                              top: y,
                              child: Opacity(
                                opacity: op,
                                child: Text(f.emoji,
                                    style: TextStyle(fontSize: f.size)),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // ── Static decorative emojis ─────────────────────────────
                for (final d in _decor)
                  Positioned(
                    top: d.top, bottom: d.bottom,
                    left: d.left, right: d.right,
                    child: Opacity(
                      opacity: d.opacity,
                      child: Text(d.emoji,
                          style: TextStyle(fontSize: d.size)),
                    ),
                  ),

                // ── Main content ─────────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Collapsed header (always visible) ────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pookalam icon
                              const Text('🌺',
                                  style: TextStyle(fontSize: 38)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // White pill badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '🎉 Event Notice',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Bold title
                                    const Text(
                                      'Onam Celebrations 2026',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Animated chevron
                              RotationTransition(
                                turns: _chevronAnim,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Subtitle
                          Text(
                            _expanded
                                ? 'All 4 branches • tap to collapse'
                                : 'All Luminar branches — tap to view date, time & venue 🎊',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.82),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // "Harvest season is near" chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _darkGreen.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🌾  Harvest season is near',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Expandable detail section ────────────────────────
                    SizeTransition(
                      sizeFactor: _expandAnim,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _expandAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 1,
                                color: Colors.white.withOpacity(0.18)),

                            // Program pills
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                              child: Wrap(
                                spacing: 7,
                                children: [
                                  _pill('🎭 Cultural'),
                                  _pill('🍛 Sadhya'),
                                  _pill('🎵 Music'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            Container(height: 1,
                                color: Colors.white.withOpacity(0.18)),
                            const SizedBox(height: 10),

                            // Branch rows
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Column(
                                children: _allEvents
                                    .map((e) => _GreenBranchRow(event: e))
                                    .toList(),
                              ),
                            ),

                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
      );
}

// ── Green branch row ──────────────────────────────────────────────────────────

class _GreenBranchRow extends StatelessWidget {
  final OnamEventInfo event;
  const _GreenBranchRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.13)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9, height: 9,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: event.accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: event.accentColor.withOpacity(0.7),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.branchDisplayName,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('📅 ', style: TextStyle(fontSize: 10)),
                    Text(event.date,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9))),
                    const SizedBox(width: 8),
                    const Text('🕐 ', style: TextStyle(fontSize: 10)),
                    Flexible(
                      child: Text(event.time,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.white.withOpacity(0.7)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('📍 ', style: TextStyle(fontSize: 10)),
                    Flexible(
                      child: Text(event.venue,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.3,
                          )),
                    ),
                  ]),
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
// OnamNoticeCard — Vibrant Kerala Onam Festival Design
// Palette: Deep Saffron → Vibrant Orange → Golden Amber (🌺 Onam colors)
// Animations: elastic bounce entry, slow-rotating pookalam, particle burst,
//             breathing border glow, staggered program rows, shimmer sweep
// ─────────────────────────────────────────────────────────────────────────────

// ── Onam Festival Color Palette ───────────────────────────────────────────────
class _OnamColors {
  static const deepSaffron  = Color(0xFF6D1A00); // deep burnt saffron
  static const saffron      = Color(0xFFBF360C); // rich saffron
  static const orange       = Color(0xFFE64A19); // vibrant orange
  static const amber        = Color(0xFFFF6F00); // golden amber
  static const gold         = Color(0xFFFFB300); // warm gold
  static const cream        = Color(0xFFFFF8E1); // kasavu cream

  static const gradient = LinearGradient(
    colors: [deepSaffron, saffron, orange, amber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const shimmerColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFE082), // gold shimmer
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
  ];
}

// ── Confetti particle ─────────────────────────────────────────────────────────
class _Confetti {
  final double x, startY, size, speed, phase;
  final Color color;
  static const _colors = [
    Color(0xFFFFB300), Color(0xFFFF6F00), Color(0xFFFFFFFF),
    Color(0xFFFFF176), Color(0xFFFF8A65), Color(0xFFFFCC02),
  ];
  _Confetti({required math.Random rng})
      : x      = rng.nextDouble(),
        startY = -rng.nextDouble() * 0.5,
        size   = 4 + rng.nextDouble() * 5,
        speed  = 0.6 + rng.nextDouble() * 0.4,
        phase  = rng.nextDouble() * 2 * math.pi,
        color  = _colors[rng.nextInt(_colors.length)];
}

// ── Program item data ─────────────────────────────────────────────────────────
class _ProgramItem {
  final String icon, title, subtitle, accentHex;
  const _ProgramItem({
    required this.icon, required this.title,
    required this.subtitle, required this.accentHex,
  });
}

// ── OnamNoticeCard ────────────────────────────────────────────────────────────

class OnamNoticeCard extends StatefulWidget {
  final OnamEventInfo event;
  const OnamNoticeCard({super.key, required this.event});

  @override
  State<OnamNoticeCard> createState() => _OnamNoticeCardState();
}

class _OnamNoticeCardState extends State<OnamNoticeCard>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _bounceCtrl;   // elastic card entry
  late final AnimationController _rotateCtrl;   // pookalam spin
  late final AnimationController _shimmerCtrl;  // title shimmer sweep
  late final AnimationController _glowCtrl;     // border pulse
  late final AnimationController _confettiCtrl; // confetti burst
  late final AnimationController _staggerCtrl;  // section stagger

  // ── Animations ──────────────────────────────────────────────────────────
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final List<Animation<double>>  _sectionFade;
  late final List<Animation<Offset>>  _sectionSlide;

  final _rng = math.Random(55);
  late final List<_Confetti> _confetti;

  static const _sectionCount = 5;

  static const _programs = [
    _ProgramItem(
      icon: '🎭', title: 'Cultural Programs',
      subtitle: 'Traditional Thiruvathira, Kaikottikali & folk arts',
      accentHex: 'FFB300',
    ),
    _ProgramItem(
      icon: '🍛', title: 'Onam Sadhya',
      subtitle: 'Grand 26-dish feast served on banana leaf',
      accentHex: 'FF6F00',
    ),
    _ProgramItem(
      icon: '🎵', title: 'Music Events',
      subtitle: 'Live Onapattukal, classical & fusion performances',
      accentHex: 'E64A19',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Elastic bounce entry
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(
        parent: _bounceCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.75, end: 1.0));
    _fadeAnim = CurvedAnimation(
        parent: _bounceCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    // Stagger for sections
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _sectionFade  = [];
    _sectionSlide = [];
    for (int i = 0; i < _sectionCount; i++) {
      final s = (i * 0.16).clamp(0.0, 1.0);
      final e = (s + 0.28).clamp(0.0, 1.0);
      _sectionFade.add(Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _sectionSlide.add(Tween<Offset>(
              begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(s, e, curve: Curves.easeOutBack))));
    }

    // Pookalam slow rotation
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))..repeat();

    // Title shimmer
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))..repeat();

    // Border glow pulse
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    // Confetti
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))..repeat();
    _confetti = List.generate(18, (_) => _Confetti(rng: _rng));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bounceCtrl.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _staggerCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _staggerCtrl.dispose();
    _rotateCtrl.dispose();
    _shimmerCtrl.dispose();
    _glowCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Widget _staggered(int i, Widget child) => FadeTransition(
        opacity: _sectionFade[i],
        child: SlideTransition(position: _sectionSlide[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                // Outer amber glow
                BoxShadow(
                  color: _OnamColors.amber.withOpacity(0.30 + 0.22 * _glowCtrl.value),
                  blurRadius: 24 + 14 * _glowCtrl.value,
                  offset: const Offset(0, 8),
                ),
                // Inner saffron halo
                BoxShadow(
                  color: _OnamColors.saffron.withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: _OnamColors.gradient,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _OnamColors.gold.withOpacity(0.45),
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // ── Confetti particles ──────────────────────────────────
                AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => LayoutBuilder(builder: (_, c) {
                    return SizedBox(
                      width: c.maxWidth, height: c.maxWidth,
                      child: Stack(children: _confetti.map((p) {
                        final t = (_confettiCtrl.value * p.speed + p.phase / (2 * math.pi)) % 1.0;
                        final x = p.x * c.maxWidth;
                        final y = (p.startY + t) * c.maxWidth;
                        final op = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.35;
                        return Positioned(
                          left: x + math.sin(t * 4 * math.pi + p.phase) * 10,
                          top: y,
                          child: Opacity(
                            opacity: op,
                            child: Container(
                              width: p.size, height: p.size,
                              decoration: BoxDecoration(
                                color: p.color,
                                shape: t % 0.5 < 0.25
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: t % 0.5 < 0.25
                                    ? null
                                    : BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }).toList()),
                    );
                  }),
                ),

                // ── Light radial highlight top-left ─────────────────────
                Positioned(
                  top: -40, left: -40,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Section 0: Header
                      _staggered(0, _buildHeader(e)),

                      const SizedBox(height: 14),

                      // Section 1: Animated divider
                      _staggered(1, _buildWaveDivider()),

                      const SizedBox(height: 14),

                      // Section 2: Date & time
                      _staggered(2, _buildDateTimeRow(e)),

                      const SizedBox(height: 10),

                      // Section 3: Venue
                      _staggered(3, _buildVenue(e)),

                      const SizedBox(height: 14),

                      // Section 4: Programs
                      _staggered(4, _buildPrograms()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(OnamEventInfo e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slowly rotating pookalam in golden ring
        RotationTransition(
          turns: _rotateCtrl,
          child: Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFF6F00)],
                center: Alignment(0, -0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: _OnamColors.gold.withOpacity(0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text('🌺', style: TextStyle(fontSize: 30)),
            ),
          ),
        ),

        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _OnamColors.gold.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _OnamColors.gold.withOpacity(0.5),
                  ),
                ),
                child: const Text('🎉  Onam Celebration Notice',
                    style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w800,
                      color: Color(0xFFFFF8E1), letterSpacing: 0.4,
                    )),
              ),
              const SizedBox(height: 6),

              // Shimmer title
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) {
                  final p = _shimmerCtrl.value;
                  return ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: _OnamColors.shimmerColors,
                      stops: [
                        (p - 0.35).clamp(0.0, 1.0),
                        p.clamp(0.0, 1.0),
                        (p + 0.15).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ).createShader(bounds),
                    child: const Text('Onam Celebrations 2026',
                        style: TextStyle(
                          fontSize: 18.5, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.1,
                        )),
                  );
                },
              ),
              const SizedBox(height: 3),
              Text(e.branchDisplayName,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _OnamColors.cream.withOpacity(0.8),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Wave shimmer divider ─────────────────────────────────────────────────────

  Widget _buildWaveDivider() => AnimatedBuilder(
    animation: _shimmerCtrl,
    builder: (_, __) {
      final p = _shimmerCtrl.value;
      return Container(
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              _OnamColors.gold.withOpacity(0.3),
              _OnamColors.gold,
              _OnamColors.cream,
              _OnamColors.gold,
              _OnamColors.gold.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: [
              0.0,
              (p - 0.3).clamp(0.0, 1.0),
              (p - 0.05).clamp(0.0, 1.0),
              p.clamp(0.0, 1.0),
              (p + 0.05).clamp(0.0, 1.0),
              (p + 0.3).clamp(0.0, 1.0),
              1.0,
            ],
          ),
        ),
      );
    },
  );

  // ── Date & Time ──────────────────────────────────────────────────────────────

  Widget _buildDateTimeRow(OnamEventInfo e) => Row(children: [
    Expanded(child: _infoTile('📅', 'DATE', e.date)),
    const SizedBox(width: 10),
    Expanded(child: _infoTile('🕐', 'TIME', e.time)),
  ]);

  Widget _infoTile(String icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.22),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _OnamColors.gold.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: _OnamColors.gold.withOpacity(0.9),
            letterSpacing: 0.8,
          )),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: Colors.white, height: 1.25,
          )),
        ],
      )),
    ]),
  );

  // ── Venue ────────────────────────────────────────────────────────────────────

  Widget _buildVenue(OnamEventInfo e) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.22),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _OnamColors.gold.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _OnamColors.gold.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Text('📍', style: TextStyle(fontSize: 18)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VENUE', style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: _OnamColors.gold.withOpacity(0.9),
          letterSpacing: 0.8,
        )),
        const SizedBox(height: 3),
        Text(e.venue, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: Colors.white, height: 1.35,
        )),
      ])),
    ]),
  );

  // ── Programs ─────────────────────────────────────────────────────────────────

  Widget _buildPrograms() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _OnamColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text('PROGRAMS', style: TextStyle(
          fontSize: 9.5, fontWeight: FontWeight.w800,
          color: _OnamColors.gold,
          letterSpacing: 1.2,
        )),
      ]),
      const SizedBox(height: 10),
      ..._programs.asMap().entries.map((entry) =>
          _AnimatedProgramRow(item: entry.value, delay: entry.key * 80)),
    ],
  );
}

// ── Animated program row (bounces in with delay) ──────────────────────────────

class _AnimatedProgramRow extends StatefulWidget {
  final _ProgramItem item;
  final int delay;
  const _AnimatedProgramRow({required this.item, required this.delay});

  @override
  State<_AnimatedProgramRow> createState() => _AnimatedProgramRowState();
}

class _AnimatedProgramRowState extends State<_AnimatedProgramRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double>  _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay + 600), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(int.parse('FF${widget.item.accentHex}', radix: 16));
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(children: [
              // Accent icon bubble
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.7), accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.4),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: Text(widget.item.icon,
                    style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.title, style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
                  const SizedBox(height: 3),
                  Text(widget.item.subtitle, style: TextStyle(
                    fontSize: 10.5,
                    color: _OnamColors.cream.withOpacity(0.7),
                    height: 1.35,
                  )),
                ],
              )),
              // Accent dot
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
