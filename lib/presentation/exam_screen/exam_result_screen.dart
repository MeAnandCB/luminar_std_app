import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/exam_screen/model.dart';
import 'package:luminar_std/repository/exam_screen/service.dart';

// ── Grade configuration ────────────────────────────────────────────────────────
class _GradeConfig {
  final String label;
  final String emoji;
  final List<Color> gradient;
  final Color accent;
  final String message;

  const _GradeConfig({
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.accent,
    required this.message,
  });
}

_GradeConfig _gradeConfig(double pct) {
  if (pct >= 85) {
    return _GradeConfig(
      label: 'Outstanding',
      emoji: '🏆',
      gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      accent: const Color(0xFF42A5F5),
      message: 'Exceptional performance! Keep soaring high.',
    );
  } else if (pct >= 70) {
    return _GradeConfig(
      label: 'Excellent',
      emoji: '⭐',
      gradient: [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
      accent: const Color(0xFF66BB6A),
      message: 'Great work! You are on the right track.',
    );
  } else if (pct >= 50) {
    return _GradeConfig(
      label: 'Good',
      emoji: '👍',
      gradient: [const Color(0xFFE65100), const Color(0xFFFFB74D)],
      accent: const Color(0xFFFFB74D),
      message: 'Solid effort! A little more push to excel.',
    );
  } else {
    return _GradeConfig(
      label: 'Needs Work',
      emoji: '💪',
      gradient: [const Color(0xFFC62828), const Color(0xFFEF9A9A)],
      accent: const Color(0xFFEF9A9A),
      message: 'Don\'t give up! Every attempt makes you stronger.',
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class ExamResultScreen extends StatefulWidget {
  const ExamResultScreen({super.key, required this.attemptUid});
  final String attemptUid;

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with TickerProviderStateMixin {
  late Future<ApiResponse<ExamResultResponse>> _futureResult;

  late AnimationController _heroCtrl;
  late AnimationController _arcCtrl;
  late AnimationController _cardsCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _heroScale;
  late Animation<double> _heroFade;
  late Animation<double> _arcProgress;
  late Animation<double> _counterValue;
  late Animation<double> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _futureResult =
        ExamService().fetchExamResult(attemptUid: widget.attemptUid);

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _heroScale =
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutBack);
    _heroFade =
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeIn);
    _cardsSlide =
        CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOutCubic);
    // Initialize with zero so they are never uninitialized when build runs
    _arcProgress = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic));
    _counterValue = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic));
  }

  void _startAnimations(double pct) {
    // Reassign inside setState so _HeroHeader rebuilds with the new animation references
    setState(() {
      _arcProgress = Tween<double>(begin: 0, end: pct / 100)
          .animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic));
      _counterValue = Tween<double>(begin: 0, end: pct)
          .animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic));
    });

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _arcCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _arcCtrl.dispose();
    _cardsCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _futureResult =
          ExamService().fetchExamResult(attemptUid: widget.attemptUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: FutureBuilder<ApiResponse<ExamResultResponse>>(
        future: _futureResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.data == null) {
            return _ErrorView(onRetry: _retry);
          }

          final result = snapshot.data!.data!.data;
          final cfg = _gradeConfig(result.overallPercent);

          // Kick off animations once we have data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_heroCtrl.isAnimating && _heroCtrl.value == 0) {
              _startAnimations(result.overallPercent);
            }
          });

          final publishedStr = result.publishedAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a')
                  .format(result.publishedAt!.toLocal())
              : '—';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero Header ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 440,
                pinned: true,
                backgroundColor: cfg.gradient.first,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: const Text(
                  'Exam Result',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _HeroHeader(
                    config: cfg,
                    percent: result.overallPercent,
                    grade: result.grade,
                    moduleName: result.module?.name ?? 'Assessment',
                    heroFade: _heroFade,
                    heroScale: _heroScale,
                    arcProgress: _arcProgress,
                    counterValue: _counterValue,
                    particleCtrl: _particleCtrl,
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _cardsSlide,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 40 * (1 - _cardsSlide.value)),
                    child: Opacity(
                      opacity: _cardsSlide.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      children: [
                        // Performance Level
                        _PerformanceLevelCard(percent: result.overallPercent),
                        const SizedBox(height: 16),

                        // Quick stats row
                        Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                icon: Icons.repeat_rounded,
                                label: 'Attempt',
                                value: '#${result.attemptNo}',
                                color: cfg.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatChip(
                                icon: Icons.category_rounded,
                                label: 'Type',
                                value: result.examType?.name ?? '—',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatChip(
                                icon: result.examAttended == true
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                label: 'Attended',
                                value: result.examAttended == true
                                    ? 'Yes'
                                    : result.examAttended == false
                                        ? 'No'
                                        : '—',
                                color: result.examAttended == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Details card
                        _InfoCard(
                          children: [
                            _InfoRow(
                              icon: Icons.menu_book_rounded,
                              label: 'Course',
                              value: result.batch?.courseName ?? '—',
                            ),
                            _InfoRow(
                              icon: Icons.class_outlined,
                              label: 'Batch',
                              value: result.batch?.batchName ?? '—',
                            ),
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Published',
                              value: publishedStr,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Remarks
                        if (result.remarks.isNotEmpty)
                          _CommentCard(
                            title: 'Instructor Remarks',
                            icon: Icons.chat_bubble_rounded,
                            content: result.remarks,
                            color: AppColors.primary,
                          ),

                        if (result.attendanceComment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _CommentCard(
                              title: 'Attendance Comment',
                              icon: Icons.event_available_rounded,
                              content: result.attendanceComment,
                              color: Colors.teal,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Hero Header widget ────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final _GradeConfig config;
  final double percent;
  final String grade;
  final String moduleName;
  final Animation<double> heroFade;
  final Animation<double> heroScale;
  final Animation<double> arcProgress;
  final Animation<double> counterValue;
  final AnimationController particleCtrl;

  const _HeroHeader({
    required this.config,
    required this.percent,
    required this.grade,
    required this.moduleName,
    required this.heroFade,
    required this.heroScale,
    required this.arcProgress,
    required this.counterValue,
    required this.particleCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([heroFade, arcProgress, particleCtrl]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: config.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Floating particles
              CustomPaint(
                painter: _ParticlePainter(
                    progress: particleCtrl.value, color: config.accent),
                size: Size.infinite,
              ),

              // Content
              SafeArea(
                child: Opacity(
                  opacity: heroFade.value.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Module name
                      Text(
                        moduleName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Arc ring with score
                      ScaleTransition(
                        scale: heroScale,
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: _ArcPainter(
                              progress: arcProgress.value,
                              arcColor: config.accent,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    config.emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${counterValue.value.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  const Text(
                                    'Score',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Grade pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Colors.white54, width: 1.5),
                        ),
                        child: Text(
                          grade.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Motivational message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          config.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Performance Level Card ────────────────────────────────────────────────────
class _PerformanceLevelCard extends StatelessWidget {
  final double percent;
  const _PerformanceLevelCard({required this.percent});

  static const _levels = [
    ('Poor', Color(0xFFEF5350)),
    ('Fair', Color(0xFFFF7043)),
    ('Good', Color(0xFFFFA726)),
    ('Excellent', Color(0xFF66BB6A)),
    ('Outstanding', Color(0xFF42A5F5)),
  ];

  int get _activeIndex {
    if (percent >= 85) return 4;
    if (percent >= 70) return 3;
    if (percent >= 50) return 2;
    if (percent >= 30) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Performance Level',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_levels.length, (i) {
              final isActive = i == active;
              final isPast = i < active;
              final (name, color) = _levels[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _levels.length - 1 ? 6 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: isActive ? 14 : 8,
                        decoration: BoxDecoration(
                          color: (isActive || isPast)
                              ? color
                              : color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1)
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive
                              ? color
                              : AppColors.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _levels[active].$1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _levels[active].$2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color arcColor;

  _ArcPainter({required this.progress, required this.arcColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * progress,
      colors: [arcColor.withValues(alpha: 0.6), Colors.white],
      tileMode: TileMode.clamp,
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );

    // Tip dot
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final tipX = center.dx + radius * math.cos(angle);
    final tipY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 7, dotPaint);

    final dotInnerPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 4, dotInnerPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.arcColor != arcColor;
}

// ── Particle Painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 2.0 + rng.nextDouble() * 4;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * math.pi;

      final offsetY = math.sin(progress * 2 * math.pi * speed + phase) * 12;
      final opacity = 0.1 + 0.2 * math.sin(progress * math.pi * speed + phase).abs();

      paint.color = color.withValues(alpha: opacity.clamp(0.05, 0.3));
      canvas.drawCircle(Offset(baseX, baseY + offsetY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 56, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.8), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment Card ──────────────────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final Color color;

  const _CommentCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(content,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6)),
        ],
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Exam Result'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load exam result',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
