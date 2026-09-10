import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/feedback/feedback_model.dart';
import 'package:luminar_std/repository/feedback/feedback_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BatchReviewCard — self-contained: fetches the student's active batch(es)
// and their feedback history, then renders either an invitation to rate the
// batch or a summary of the latest review. Tapping opens the submission
// sheet; submitting always creates a new history entry (per the API).
// ─────────────────────────────────────────────────────────────────────────────

class BatchReviewCard extends StatefulWidget {
  const BatchReviewCard({super.key});

  @override
  State<BatchReviewCard> createState() => _BatchReviewCardState();
}

class _BatchReviewCardState extends State<BatchReviewCard>
    with TickerProviderStateMixin {
  final FeedbackService _service = FeedbackService();

  bool _loading = true;
  BatchFeedbackSummary? _batch;
  FeedbackOptions? _options;

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _entryFade =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  late final Animation<double> _entryScale = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.easeOutBack,
  ).drive(Tween(begin: 0.92, end: 1.0));

  // Gentle pulsing glow traced along the card's notched border curve; also
  // drives the icon badge's subtle breathing pulse.
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  // Slow diagonal sheen that sweeps across the card every few seconds.
  late final AnimationController _shimmerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _service.getMyBatches();
    if (!mounted) return;

    if (res.success && res.data != null && res.data!.batches.isNotEmpty) {
      setState(() {
        _batch = res.data!.batches.first;
        _loading = false;
      });
      _entryCtrl.forward(from: 0);
    } else {
      setState(() => _loading = false);
    }

    // Options change rarely — fetch lazily so it's ready by the time the
    // sheet opens, without delaying the card's own first paint.
    _service.getOptions().then((o) {
      if (mounted && o.success && o.data != null) {
        setState(() => _options = o.data);
      }
    });
  }

  Future<FeedbackOptions?> _ensureOptions() async {
    if (_options != null) return _options;
    final res = await _service.getOptions();
    if (res.success && res.data != null) {
      if (mounted) setState(() => _options = res.data);
      return res.data;
    }
    return null;
  }

  Future<void> _openFeedbackSheet() async {
    final batch = _batch;
    if (batch == null) return;

    final options = await _ensureOptions();
    if (!mounted) return;

    if (options == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the feedback form. Try again.')),
      );
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackFormSheet(
        batchName: batch.batchName,
        options: options,
        onSubmit: (rating, concernType, message, detail) => _service.submitFeedback(
          batchUid: batch.batchUid,
          rating: rating,
          concernType: concernType,
          message: message,
          concernDetail: detail,
        ),
      ),
    );

    if (submitted == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_batch == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _entryFade,
      child: ScaleTransition(
        scale: _entryScale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // A small curved notch cut into the top border, instead of a
          // plain rounded rect — the card's actual shape, via ClipPath.
          child: ClipPath(
            clipper: _NotchedCardClipper(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openFeedbackSheet,
                child: SizedBox(
                  // Every layer below is Positioned.fill'd against this
                  // explicit size — an unsized Stack child here previously
                  // laid out with unbounded height and made the whole card
                  // (and its shadow) balloon far past its visible content.
                  height: 78,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryDark, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Slow diagonal sheen for a touch of polish.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shimmerCtrl,
                            builder: (_, __) => CustomPaint(
                              painter: _ShimmerPainter(progress: _shimmerCtrl.value),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Single compact CTA row — same layout whether or not feedback exists.
  Widget _buildContent() {
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              painter: _FeedbackIconPainter(pulse: _glowCtrl.value),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Share Your Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Card shape — a plain rounded rect except for one small curve cut into the
// top border, so the card reads as a deliberately designed shape rather
// than a stock rectangle. Static geometry (no per-frame reclip); only the
// glow traced along it animates.
// ─────────────────────────────────────────────────────────────────────────────

class _NotchedCardClipper extends CustomClipper<Path> {
  static const double radius = 24;
  static const double notchWidth = 44;
  static const double notchDepth = 8;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    return Path()
      ..moveTo(radius, 0)
      ..lineTo(cx - notchWidth / 2, 0)
      ..quadraticBezierTo(cx, notchDepth, cx + notchWidth / 2, 0)
      ..lineTo(w - radius, 0)
      ..quadraticBezierTo(w, 0, w, radius)
      ..lineTo(w, h - radius)
      ..quadraticBezierTo(w, h, w - radius, h)
      ..lineTo(radius, h)
      ..quadraticBezierTo(0, h, 0, h - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer sheen — a soft slanted band of light sweeping across the card on
// a slow loop, for a touch of premium polish without any looping text/UI.
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double progress; // 0..1, looping

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.28;
    final skew = size.height * 0.6;
    final travel = size.width + bandWidth * 2;
    final cx = -bandWidth + progress * travel;

    final path = Path()
      ..moveTo(cx - bandWidth / 2, 0)
      ..lineTo(cx + bandWidth / 2, 0)
      ..lineTo(cx + bandWidth / 2 - skew, size.height)
      ..lineTo(cx - bandWidth / 2 - skew, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(cx - bandWidth, 0, bandWidth * 2, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback icon — a bespoke chat-bubble + sparkle mark instead of a stock
// Material icon, drawn entirely with Path/Canvas. The sparkle breathes
// gently in sync with the notch glow.
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackIconPainter extends CustomPainter {
  final double pulse; // 0..1

  _FeedbackIconPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft rounded backdrop.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.34),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Chat bubble with a small tail.
    final bubbleRect = Rect.fromLTWH(w * 0.16, h * 0.20, w * 0.52, h * 0.40);
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(bubbleRect, Radius.circular(w * 0.10)))
      ..moveTo(w * 0.30, h * 0.60)
      ..lineTo(w * 0.24, h * 0.74)
      ..lineTo(w * 0.42, h * 0.60)
      ..close();
    canvas.drawPath(bubble, Paint()..color = Colors.white);

    // Sparkle accent, gently pulsing.
    final sparkleCenter = Offset(w * 0.70, h * 0.34);
    final sparkleSize = w * 0.15 * (1.0 + 0.18 * pulse);
    _drawSparkle(canvas, sparkleCenter, sparkleSize, const Color(0xFFFFC24B));
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FeedbackIconPainter old) => old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Submission sheet
// ─────────────────────────────────────────────────────────────────────────────

typedef _SubmitFn = Future<dynamic> Function(
  int rating,
  String concernType,
  String message,
  String? concernDetail,
);

class _FeedbackFormSheet extends StatefulWidget {
  final String batchName;
  final FeedbackOptions options;
  final _SubmitFn onSubmit;

  const _FeedbackFormSheet({
    required this.batchName,
    required this.options,
    required this.onSubmit,
  });

  @override
  State<_FeedbackFormSheet> createState() => _FeedbackFormSheetState();
}

class _FeedbackFormSheetState extends State<_FeedbackFormSheet> {
  late int _rating = ((widget.options.ratingMin + widget.options.ratingMax) / 2).round();
  String? _concernType;
  final _messageCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.options.concernTypes.isNotEmpty) {
      _concernType = widget.options.concernTypes.first.value;
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageCtrl.text.trim();
    if (message.length < 8) {
      setState(() => _error = 'Please write a little more about your experience.');
      return;
    }
    if (_concernType == null) {
      setState(() => _error = 'Please select what this feedback is about.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final res = await widget.onSubmit(
      _rating,
      _concernType!,
      message,
      _detailCtrl.text,
    );

    if (!mounted) return;

    final success = res.success == true;
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Thanks for the feedback!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      setState(() {
        _submitting = false;
        _error = res.message?.toString() ?? 'Failed to submit feedback.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.rate_review_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate Your Batch',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.batchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  'Overall, how would you rate it?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RatingSlider(
                min: widget.options.ratingMin,
                max: widget.options.ratingMax,
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 22),
              const _FieldLabel('What is this feedback about?'),
              const SizedBox(height: 8),
              _ConcernChips(
                options: widget.options.concernTypes,
                selected: _concernType,
                onSelected: (v) => setState(() => _concernType = v),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Your feedback'),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: _inputDecoration('Tell us about your experience…'),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Anything specific? (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _detailCtrl,
                maxLines: 2,
                decoration: _inputDecoration('e.g. a module, a session, a facility…'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _ConcernChips extends StatelessWidget {
  final List<ConcernType> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ConcernChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((c) {
        final isSelected = c.value == selected;
        return GestureDetector(
          onTap: () => onSelected(c.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              c.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive rating slider — a custom drag-to-rate track with an animated,
// color-shifting thumb (red → amber → green as the rating rises).
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSlider extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RatingSlider> createState() => _RatingSliderState();
}

class _RatingSliderState extends State<_RatingSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  static const double _thumbSize = 44;
  static const double _trackHeight = 10;
  static const double _height = 56;

  Color _colorFor(int value) {
    final span = widget.max - widget.min;
    final ratio = span == 0 ? 1.0 : (value - widget.min) / span;
    if (ratio < 0.4) return const Color(0xFFEF4444);
    if (ratio < 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  void _updateFromDx(double dx, double width) {
    final usable = width - _thumbSize;
    final ratio = usable <= 0 ? 0.0 : ((dx - _thumbSize / 2) / usable).clamp(0.0, 1.0);
    final span = widget.max - widget.min;
    final newValue = (widget.min + ratio * span).round();
    if (newValue != widget.value) {
      widget.onChanged(newValue);
      _pulseCtrl.forward(from: 0);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = width - _thumbSize;
        final span = widget.max - widget.min;
        final ratio = span == 0 ? 0.0 : (widget.value - widget.min) / span;
        final thumbLeft = usable * ratio;
        final fillWidth = thumbLeft + _thumbSize / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _updateFromDx(d.localPosition.dx, width),
          onTapDown: (d) => _updateFromDx(d.localPosition.dx, width),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _thumbSize / 2,
                  right: _thumbSize / 2,
                  top: (_height - _trackHeight) / 2,
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left: _thumbSize / 2,
                  top: (_height - _trackHeight) / 2,
                  width: fillWidth.clamp(0, width),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.55), color],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left: thumbLeft,
                  top: (_height - _thumbSize) / 2,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 +
                          0.18 *
                              math.sin(_pulseCtrl.value * math.pi).clamp(0.0, 1.0),
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
