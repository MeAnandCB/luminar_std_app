import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import '../api/laptop_api.dart';
import '../screens/rack_scan_screen.dart';
import '../time_ago.dart';
import 'scan_camera.dart';
import 'sheet_widgets.dart';

/// Opens when /lookup returns itemType "laptop", state "assigned". The
/// phone always returns a loan in full, in one visit — this checklist
/// doesn't unlock Return until every item (laptop + every accessory) is
/// ticked, then hands off to a dedicated full-screen rack scan to confirm.
/// Partial returns are still supported by the system, but that
/// reconciliation happens on the admin web dashboard, not from here.
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

class _ReturnLine {
  _ReturnLine({
    required this.id,
    required this.kind,
    required this.name,
    required this.assetTag,
    this.accessoryType = '',
    this.ticked = false,
  });

  final String id;
  final String kind; // 'laptop' | 'accessory'
  final String name;
  final String assetTag;
  final String accessoryType; // charger | mouse | keyboard | bag | other
  bool ticked;
}

class _ReturnSheetState extends State<ReturnSheet> {
  late final List<_ReturnLine> _lines;
  final _feedbackCtrl = TextEditingController();

  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    final asset = widget.result.asset!;
    // The scan that opened this flow already proved the laptop is present
    // — that scan was its confirmation, so it starts pre-ticked.
    _lines = [
      _ReturnLine(
        id: asset.id,
        kind: 'laptop',
        name: asset.name,
        assetTag: asset.assetTag,
        ticked: true,
      ),
    ];
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  int get _expectedTotal => 1 + widget.result.loan!.accessoryCount;
  int get _tickedCount => _lines.where((l) => l.ticked).length;
  bool get _allTicked =>
      _lines.length == _expectedTotal && _lines.every((l) => l.ticked);

  Future<void> _scanItem() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final raw = await ScanCamera.scanOnce(
        context,
        hint: 'Scan the next item to return',
      );
      if (raw == null || !mounted) return;

      final result = await widget.api.lookup(raw);
      if (!mounted) return;

      final id = result.isLaptop ? result.asset!.id : result.accessory!.id;
      final existing = _lines.where((l) => l.id == id).firstOrNull;

      if (existing != null) {
        if (existing.ticked) {
          _toast('${existing.name} already scanned');
        } else {
          setState(() => existing.ticked = true);
          HapticFeedback.lightImpact();
        }
        return;
      }

      if (result.isLaptop && id != widget.result.asset!.id) {
        _toast('That laptop isn\'t part of this loan');
        return;
      }

      final line = _ReturnLine(
        id: id,
        kind: result.isLaptop ? 'laptop' : 'accessory',
        name: result.isLaptop ? result.asset!.name : result.accessory!.name,
        assetTag:
            result.isLaptop ? result.asset!.assetTag : result.accessory!.assetTag,
        accessoryType: result.isLaptop ? '' : result.accessory!.type,
        ticked: true,
      );
      setState(() => _lines.add(line));
      HapticFeedback.lightImpact();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _toggle(_ReturnLine line) {
    setState(() => line.ticked = !line.ticked);
    if (line.ticked) HapticFeedback.lightImpact();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _goToRackScan() async {
    final outcome = await Navigator.of(context).push<SheetOutcome>(
      MaterialPageRoute(
        builder: (_) => RackScanScreen(
          api: widget.api,
          identifiers: _lines.map((l) => l.id).toList(),
          earlyReturnFeedback: widget.result.loan!.isEarlyReturn
              ? _feedbackCtrl.text.trim()
              : null,
        ),
      ),
    );
    if (!mounted || outcome == null) return;
    // Success — close the checklist too, bubbling the final outcome up to
    // the scan screen. A null outcome (user backed out of the rack scan)
    // leaves the checklist open exactly as it was, everything still ticked.
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.result.loan!;

    return SheetScaffold(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssetHeader(asset: widget.result.asset!, available: false),
            const SizedBox(height: 16),
            _HolderCard(loan: loan),

            if (loan.isEarlyReturn) ...[
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
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Why so soon? (optional)',
                        hintStyle:
                            TextStyle(fontSize: 13, color: AppColors.textHint),
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
                            borderSide:
                                const BorderSide(color: Colors.amber, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(
              'Items ($_tickedCount/$_expectedTotal)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._lines.map(
              (line) => _ReturnRow(line: line, onTap: () => _toggle(line)),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _scanning ? null : _scanItem,
              icon: _scanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan an item'),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _allTicked ? _goToRackScan : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor:
                      const Color(0xFF10B981).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.keyboard_return_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Return',
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
      ),
    );
  }
}

class _HolderCard extends StatelessWidget {
  const _HolderCard({required this.loan});
  final LaptopLoan loan;

  @override
  Widget build(BuildContext context) {
    final initial = loan.studentName.trim().isNotEmpty
        ? loan.studentName.trim()[0].toUpperCase()
        : '?';
    return Container(
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
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.line, required this.onTap});
  final _ReturnLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = line.ticked;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              line.kind == 'laptop'
                  ? Icons.laptop_mac_rounded
                  : accessoryIcon(line.accessoryType),
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  if (line.assetTag.isNotEmpty)
                    Text(line.assetTag,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: done
                  ? const CircleAvatar(
                      key: ValueKey('done'),
                      radius: 11,
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                    )
                  : CircleAvatar(
                      key: const ValueKey('pending'),
                      radius: 11,
                      backgroundColor: AppColors.borderColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
