import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import '../api/laptop_api.dart';

// ── Result passed back when a sheet closes ─────────────────────────────────

class SheetOutcome {
  final String message;
  final LaptopCounts? counts;
  final bool isError;
  final bool rescan;

  const SheetOutcome({
    required this.message,
    required this.counts,
    this.isError = false,
    this.rescan = false,
  });
}

// ── Standard sheet wrapper ─────────────────────────────────────────────────

class SheetScaffold extends StatelessWidget {
  const SheetScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close_rounded,
                  color: AppColors.textSecondary, size: 22),
            ),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Laptop asset header row ────────────────────────────────────────────────

class AssetHeader extends StatelessWidget {
  const AssetHeader({super.key, required this.asset, required this.available});
  final LaptopAsset asset;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final statusColor = available ? const Color(0xFF10B981) : Colors.orange;
    final statusLabel = available ? 'Available' : 'Checked out';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.laptop_mac_rounded,
              color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('${asset.assetTag}  ·  ${asset.serialNumber}',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Accessory type → icon ──────────────────────────────────────────────────

IconData accessoryIcon(String type) {
  switch (type) {
    case 'charger':
      return Icons.power_rounded;
    case 'mouse':
      return Icons.mouse_rounded;
    case 'keyboard':
      return Icons.keyboard_rounded;
    case 'bag':
      return Icons.work_outline_rounded;
    default:
      return Icons.cable_rounded;
  }
}

// ── Full-sheet success confirmation ────────────────────────────────────────
//
// Full success bounces in with Curves.elasticOut (a little overshoot/pop);
// partial success (bounce: false) just fades in — calmer, distinct feel.

class SuccessBurst extends StatelessWidget {
  const SuccessBurst({
    super.key,
    required this.title,
    this.subtitle,
    this.color = const Color(0xFF10B981),
    this.bounce = true,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    final icon = CircleAvatar(
      radius: 32,
      backgroundColor: color,
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bounce
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: icon,
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: icon,
                ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
