import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import '../api/laptop_api.dart';
import 'scan_camera.dart';
import 'sheet_widgets.dart';

export 'sheet_widgets.dart' show SheetOutcome;

/// Opens once the laptop scan that triggered this flow has already been
/// confirmed (the "Add?" dialog for the laptop itself happens one level up,
/// in the scan screen, before this sheet is ever shown — cancelling there
/// means this sheet never opens at all). From here: scan accessories (each
/// one gets its own confirm dialog before being added), fill in the
/// student's details, then Take.
class TakeSheet extends StatefulWidget {
  const TakeSheet({
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
  State<TakeSheet> createState() => _TakeSheetState();
}

class _TakeSheetState extends State<TakeSheet> {
  final _listKey = GlobalKey<AnimatedListState>();
  final List<AccessoryInfo> _accessories = [];

  late final _nameCtrl = TextEditingController(text: widget.prefillName);
  late final _idCtrl = TextEditingController(text: widget.prefillStudentId);
  late final _batchCtrl = TextEditingController(text: widget.prefillBatch);

  bool _scanningAccessory = false;
  bool _submitting = false;
  String? _error;
  CheckoutActionResult? _successResult;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _idCtrl.text.trim().isNotEmpty &&
      !_submitting;

  /// Every scan in this flow goes through a confirmation dialog before
  /// anything is added — nothing gets appended silently.
  Future<bool> _confirmAdd(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _scanAccessory() async {
    if (_scanningAccessory) return;
    setState(() => _scanningAccessory = true);
    try {
      final raw = await ScanCamera.scanOnce(
        context,
        hint: 'Scan the accessory QR sticker',
      );
      if (raw == null || !mounted) return;

      final result = await widget.api.lookup(raw);
      if (!mounted) return;

      if (!result.isAccessory) {
        _toast('That\'s a laptop, not an accessory');
        return;
      }
      final acc = result.accessory!;
      if (_accessories.any((a) => a.id == acc.id)) {
        _toast('${acc.name} already added');
        return;
      }
      if (acc.status != 'available') {
        _toast('${acc.name} isn\'t available');
        return;
      }

      final confirmed = await _confirmAdd(
        '${acc.name} (${acc.assetTag})',
        'Add to this checkout?',
      );
      if (!confirmed || !mounted) return;

      setState(() => _accessories.add(acc));
      _listKey.currentState?.insertItem(
        _accessories.length - 1,
        duration: const Duration(milliseconds: 250),
      );
      HapticFeedback.lightImpact();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _scanningAccessory = false);
    }
  }

  void _removeAccessory(int index) {
    final removed = _accessories.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _AccessoryRow(
        accessory: removed,
        animation: animation,
        onRemove: null,
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final studentName = _nameCtrl.text.trim();
    try {
      final res = await widget.api.checkout(
        identifier: widget.result.asset!.id,
        accessoryIdentifiers: _accessories.map((a) => a.id).toList(),
        studentName: studentName,
        studentId: _idCtrl.text.trim(),
        batch: _batchCtrl.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _successResult = res);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pop(
          context,
          SheetOutcome(
            message: 'Taken by $studentName',
            counts: res.counts,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_successResult != null) {
      return _TakeReceipt(
        studentName: _nameCtrl.text.trim(),
        items: _successResult!.items,
      );
    }

    return SheetScaffold(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, scale, child) =>
                  Opacity(opacity: scale, child: Transform.scale(scale: scale, child: child)),
              child: AssetHeader(asset: widget.result.asset!, available: true),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accessories (${_accessories.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _scanningAccessory ? null : _scanAccessory,
                  icon: _scanningAccessory
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan'),
                ),
              ],
            ),
            if (_accessories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No accessories scanned yet',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ),
            // Always mounted (even with zero items) so _listKey is already
            // attached by the time the first accessory is scanned — otherwise
            // that first insertItem() call would silently no-op.
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _accessories.length,
              itemBuilder: (context, index, animation) => _AccessoryRow(
                accessory: _accessories[index],
                animation: animation,
                onRemove: () => _removeAccessory(index),
              ),
            ),
            const SizedBox(height: 12),
            _label('Student Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _inputDec('Enter student name', Icons.person_rounded),
            ),
            const SizedBox(height: 12),
            _label('Student ID'),
            const SizedBox(height: 8),
            TextField(
              controller: _idCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _inputDec('Enter student ID', Icons.badge_rounded),
            ),
            const SizedBox(height: 12),
            _label('Batch (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _batchCtrl,
              decoration: _inputDec('e.g. MERN-Jul26', Icons.group_rounded),
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
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.laptop_mac_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Take',
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

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _AccessoryRow extends StatelessWidget {
  const _AccessoryRow({
    required this.accessory,
    required this.animation,
    required this.onRemove,
  });

  final AccessoryInfo accessory;
  final Animation<double> animation;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Icon(accessoryIcon(accessory.type),
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(accessory.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(accessory.assetTag,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the student sees once Take succeeds — the full receipt (every item
/// by name), not just a count. The same /checkout call already made this
/// loan visible as "out" on the admin dashboard, so nothing else is needed
/// here besides showing it before auto-dismissing.
class _TakeReceipt extends StatelessWidget {
  const _TakeReceipt({required this.studentName, required this.items});

  final String studentName;
  final List<CheckedOutItem> items;

  @override
  Widget build(BuildContext context) {
    return SuccessBurst(
      title: 'Taken by $studentName',
      subtitle: items.isEmpty
          ? null
          : items
              .map((i) => '${i.isLaptop ? '💻' : '🔌'} ${i.name} (${i.assetTag})')
              .join('\n'),
    );
  }
}
