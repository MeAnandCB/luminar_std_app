import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import '../api/laptop_api.dart';
import 'sheet_widgets.dart';

export 'sheet_widgets.dart' show SheetOutcome;

class AssignSheet extends StatefulWidget {
  const AssignSheet({
    super.key,
    required this.api,
    required this.result,
    this.prefillName = '',
    this.prefillStudentId = '',
    this.prefillBatch = '',
  });

  final LaptopApi api;
  final LookupResult result;
  final String prefillName;
  final String prefillStudentId;
  final String prefillBatch;

  @override
  State<AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<AssignSheet> {
  bool _loading = false;
  String? _error;

  String get _name      => widget.prefillName;
  String get _studentId => widget.prefillStudentId;
  String get _batch     => widget.prefillBatch;

  String get _initial =>
      _name.trim().isNotEmpty ? _name.trim()[0].toUpperCase() : '?';

  Future<void> _submit() async {
    // Both name and studentId are required
    if (_name.trim().isEmpty || _studentId.trim().isEmpty) {
      setState(() => _error =
          'Student name and ID are required. Please contact admin.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await widget.api.checkout(
        identifier:  widget.result.asset.id,
        studentName: _name,
        studentId:   _studentId,
        batch:       _batch,
      );
      if (!mounted) return;
      Navigator.pop(context,
          SheetOutcome(message: 'Laptop Taken — $_name', counts: res.counts));
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409: show error inline — user must cancel and re-scan manually
      setState(() { _loading = false; _error = e.message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetHeader(asset: widget.result.asset, available: true),
          const SizedBox(height: 20),

          // ── Student profile card ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.isNotEmpty ? _name : 'Unknown',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_studentId.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.badge_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(_studentId,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ],
                      if (_batch.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _batch,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.laptop_mac_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Take Laptop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
