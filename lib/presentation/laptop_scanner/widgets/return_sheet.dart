import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import '../api/laptop_api.dart';
import '../time_ago.dart';
import 'sheet_widgets.dart';

class ReturnSheet extends StatefulWidget {
  const ReturnSheet({
    super.key,
    required this.api,
    required this.result,
  });

  final LaptopApi api;
  final LookupResult result;

  @override
  State<ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<ReturnSheet> {
  bool _loading = false;
  final _feedbackCtrl = TextEditingController();

  static const _green = Color(0xFF10B981);

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _doReturn() async {
    setState(() => _loading = true);
    final feedback = widget.result.loan!.isEarlyReturn
        ? _feedbackCtrl.text.trim()
        : '';
    try {
      final res = await widget.api.returnLaptop(
        widget.result.asset.id,
        earlyReturnFeedback: feedback,
      );
      if (!mounted) return;
      Navigator.pop(context,
          SheetOutcome(message: 'Laptop Returned', counts: res.counts));
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 or other errors — close sheet, show snackbar, user re-scans
      Navigator.pop(context,
          SheetOutcome(message: e.message, counts: null, isError: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.result.loan!;
    final initial = loan.studentName.isNotEmpty
        ? loan.studentName.trim()[0].toUpperCase()
        : '?';

    return SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetHeader(asset: widget.result.asset, available: false),
          const SizedBox(height: 20),

          // ── Holder profile card ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.08),
                  Colors.orange.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
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
                        loan.studentName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (loan.studentId.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.badge_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(loan.studentId,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ],
                      if (loan.batch.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loan.batch,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'Taken ${timeAgo(loan.checkOutAt.toLocal())}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Early return feedback — only shown when loan.isEarlyReturn == true
          if (widget.result.loan!.isEarlyReturn) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 15),
                    const SizedBox(width: 6),
                    Text('Returned quickly',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700)),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackCtrl,
                    enabled: !_loading,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Why so soon? (optional)',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.amber, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _doReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: _green.withValues(alpha: 0.5),
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
                        const Icon(Icons.keyboard_return_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Return Laptop',
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
