// lib/presentation/widgets/shimmer_widget.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBaseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final defaultHighlightColor = isDark
        ? Colors.grey[700]!
        : Colors.grey[100]!;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: const Alignment(-1, 0),
          end: const Alignment(1, 0),
          colors: [
            widget.baseColor ?? defaultBaseColor,
            widget.highlightColor ?? defaultHighlightColor,
            widget.baseColor ?? defaultBaseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(slidePercent: _animation.value),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// Extension for creating shimmer effect on existing widgets
extension ShimmerExtension on Widget {
  Widget shimmer({
    bool enabled = true,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    if (!enabled) return this;

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            baseColor ?? Colors.grey[400]!,
            highlightColor ?? Colors.grey[200]!,
            baseColor ?? Colors.grey[400]!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1, 0),
          end: const Alignment(1, 0),
          transform: _SlidingGradientTransform(slidePercent: 0.2),
        ).createShader(bounds);
      },
      child: this,
    );
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          _buildHeaderShimmer(),
          const SizedBox(height: 14),

          // Status shimmer
          _buildStatusShimmer(),
          const SizedBox(height: 24),

          // Success stories title shimmer
          Center(child: _buildTitleShimmer()),
          const SizedBox(height: 10),

          // Carousel shimmer
          _buildCarouselShimmer(),
          const SizedBox(height: 20),

          // Course details title shimmer
          Center(child: _buildTitleShimmer()),
          const SizedBox(height: 10),

          // Course card shimmer
          _buildCourseCardShimmer(),
          const SizedBox(height: 24),

          // Quick stats grid shimmer
          _buildQuickStatsShimmer(),
          const SizedBox(height: 24),

          // Recent activities title shimmer
          _buildTitleShimmer(),
          const SizedBox(height: 12),

          // Activity list shimmer
          _buildActivityListShimmer(),
        ],
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Row(
      children: [
        // Avatar shimmer
        const ShimmerWidget(
          width: 50,
          height: 50,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        const SizedBox(width: 12),
        // Name and welcome text shimmer
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(
              width: 120,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            ShimmerWidget(
              width: 80,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const Spacer(),
        // Notification icon shimmer
        const ShimmerWidget(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ],
    );
  }

  Widget _buildStatusShimmer() {
    return ShimmerWidget(
      width: 100,
      height: 30,
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _buildTitleShimmer() {
    return ShimmerWidget(
      width: 150,
      height: 24,
      borderRadius: BorderRadius.circular(4),
    );
  }

  Widget _buildCarouselShimmer() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ShimmerWidget(
              width: 200,
              height: 120,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCardShimmer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget(
            width: 120,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 8),
          const ShimmerWidget(
            width: double.infinity,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (index) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 40,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 60,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerWidget(
            width: double.infinity,
            height: 8,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget(
                width: 80,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              ShimmerWidget(
                width: 120,
                height: 30,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsShimmer() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: List.generate(
        4,
        (index) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 80,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityListShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const ShimmerWidget(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            title: ShimmerWidget(
              width: 150,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ShimmerWidget(
                width: 200,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerWidget(
                  width: 60,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                ShimmerWidget(
                  width: 40,
                  height: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
