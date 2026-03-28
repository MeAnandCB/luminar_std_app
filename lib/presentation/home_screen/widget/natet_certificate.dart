import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class NactetBanner extends StatefulWidget {
  final int pendingCount;
  final VoidCallback? onFormTap;

  const NactetBanner({super.key, this.pendingCount = 2, this.onFormTap});

  @override
  State<NactetBanner> createState() => _NactetBannerState();
}

class _NactetBannerState extends State<NactetBanner>
    with TickerProviderStateMixin {
  static const _palettes = [
    _Palette(
      border: Color(0xFFF97316),
      bg: [Color(0xFFFFF8F0), Color(0xFFFFFFFF)],
      dot: Color(0xFFF97316),
      badge: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      btn: [Color(0xFFF97316), Color(0xFFEA580C)],
      icon: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      label: Color(0xFFC2410C),
      num: Color(0xFFEA580C),
      shadow: Color(0xFFF97316),
    ),
    _Palette(
      border: Color(0xFF10B981),
      bg: [Color(0xFFF0FFF8), Color(0xFFFFFFFF)],
      dot: Color(0xFF10B981),
      badge: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      btn: [Color(0xFF10B981), Color(0xFF059669)],
      icon: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      label: Color(0xFF065F46),
      num: Color(0xFF059669),
      shadow: Color(0xFF10B981),
    ),
    _Palette(
      border: Color(0xFF6366F1),
      bg: [Color(0xFFF0F4FF), Color(0xFFFFFFFF)],
      dot: Color(0xFF6366F1),
      badge: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
      btn: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      icon: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
      label: Color(0xFF3730A3),
      num: Color(0xFF4F46E5),
      shadow: Color(0xFF6366F1),
    ),
    _Palette(
      border: Color(0xFFEC4899),
      bg: [Color(0xFFFFF0F8), Color(0xFFFFFFFF)],
      dot: Color(0xFFEC4899),
      badge: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
      btn: [Color(0xFFEC4899), Color(0xFFDB2777)],
      icon: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
      label: Color(0xFF9D174D),
      num: Color(0xFFDB2777),
      shadow: Color(0xFFEC4899),
    ),
  ];

  late AnimationController _cycleCtrl, _blinkCtrl, _pulseCtrl;
  late Animation<double> _blinkAnim, _pulseScale, _pulseOpacity;
  int _idx = 0;
  double _t = 0;

  _Palette get _cur => _palettes[_idx];
  _Palette get _nxt => _palettes[(_idx + 1) % _palettes.length];

  Color _lc(Color a, Color b) => Color.lerp(a, b, _t) ?? a;
  List<Color> _ll(List<Color> a, List<Color> b) =>
      List.generate(a.length, (i) => _lc(a[i], b[i]));

  Color get _dot => _lc(_cur.dot, _nxt.dot);
  Color get _border => _lc(_cur.border, _nxt.border);
  Color get _shadow => _lc(_cur.shadow, _nxt.shadow);
  Color get _label => _lc(_cur.label, _nxt.label);
  Color get _num => _lc(_cur.num, _nxt.num);
  List<Color> get _bg => _ll(_cur.bg, _nxt.bg);
  List<Color> get _btn => _ll(_cur.btn, _nxt.btn);
  List<Color> get _badge => _ll(_cur.badge, _nxt.badge);
  List<Color> get _icon => _ll(_cur.icon, _nxt.icon);

  @override
  void initState() {
    super.initState();

    _cycleCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 4000),
          )
          ..addListener(() {
            final v = _cycleCtrl.value;
            if (v > 0.85) setState(() => _t = (v - 0.85) / 0.15);
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(() {
                _idx = (_idx + 1) % _palettes.length;
                _t = 0;
              });
              _cycleCtrl.forward(from: 0);
            }
          });
    _cycleCtrl.forward();

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(
      begin: 1.0,
      end: 0.15,
    ).animate(CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 2.6,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _cycleCtrl.dispose();
    _blinkCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_blinkCtrl, _pulseCtrl]),
      builder: (_, __) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _bg,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _shadow.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            // ── Pulsing dot ──
            SizedBox(
              width: 14,
              height: 14,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _blinkAnim.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _dot,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _dot.withOpacity(0.6),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Icon box ──
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _icon,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _border.withOpacity(0.25)),
              ),
              child: Icon(Icons.assignment_outlined, size: 16, color: _dot),
            ),
            const SizedBox(width: 8),

            // ── Text — Expanded ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACTION NEEDED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: _label,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NACTET Registration',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Gradient divider ──
            Container(
              width: 1,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _border, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Count badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _badge,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.pendingCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _num,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Fill Form button ──
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _btn,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _shadow.withOpacity(0.38),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onFormTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: AppColors.white,
                ),
                label: Text(
                  'Fill Form',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette {
  final Color border, dot, label, num, shadow;
  final List<Color> bg, badge, btn, icon;
  const _Palette({
    required this.border,
    required this.bg,
    required this.dot,
    required this.badge,
    required this.btn,
    required this.icon,
    required this.label,
    required this.num,
    required this.shadow,
  });
}
