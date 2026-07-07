import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/laptop_scanner/config.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _LaptopAsset {
  final String id;
  final String assetTag;
  final String name;
  final String serialNumber;
  final int scanCount;
  _LaptopAsset.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '',
      assetTag = j['assetTag'] ?? '',
      name = j['name'] ?? '',
      serialNumber = j['serialNumber'] ?? '',
      scanCount = j['scanCount'] ?? 0;
}

class _LoanInfo {
  final String studentName;
  final String batch;
  final DateTime checkOutAt;
  _LoanInfo.fromJson(Map<String, dynamic> j)
    : studentName = j['studentName'] ?? '',
      batch = j['batch'] ?? '',
      checkOutAt = DateTime.tryParse(j['checkOutAt'] ?? '') ?? DateTime.now();
}

class _Counts {
  final int total;
  final int available;
  final int out;
  const _Counts({
    required this.total,
    required this.available,
    required this.out,
  });
  _Counts.fromJson(Map<String, dynamic> j)
    : total = j['total'] ?? 0,
      available = j['available'] ?? 0,
      out = j['out'] ?? 0;
  static const empty = _Counts(total: 0, available: 0, out: 0);
}

class _LookupResult {
  final String state;
  final _LaptopAsset asset;
  final _LoanInfo? loan;
  final _Counts counts;
  _LookupResult.fromJson(Map<String, dynamic> j)
    : state = j['state'] ?? '',
      asset = _LaptopAsset.fromJson(j['asset'] as Map<String, dynamic>),
      loan = j['loan'] != null
          ? _LoanInfo.fromJson(j['loan'] as Map<String, dynamic>)
          : null,
      counts = j['counts'] != null
          ? _Counts.fromJson(j['counts'] as Map<String, dynamic>)
          : _Counts.empty;
}

// Result passed back from the bottom sheet to the parent
class _SheetResult {
  final bool success;
  final String message;
  final _Counts? counts;
  const _SheetResult({
    required this.success,
    required this.message,
    this.counts,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// API
// ─────────────────────────────────────────────────────────────────────────────

class _LaptopApi {
  static const _base = AppConfigLap.defaultBaseUrl;
  static const _key = AppConfigLap.defaultApiKey;
  static Map<String, String> get _h => {
    'Content-Type': 'application/json',
    'x-api-key': _key,
  };

  static Future<_LookupResult> lookup(String identifier) async {
    final res = await http.post(
      Uri.parse('$_base${LaptopApiConfig.lookup}'),
      headers: _h,
      body: jsonEncode({'identifier': identifier}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) return _LookupResult.fromJson(body);
    throw _ApiError(res.statusCode, body['error'] ?? 'Lookup failed');
  }

  static Future<_Counts> checkout(
    String identifier,
    String studentName,
    String batch,
  ) async {
    final res = await http.post(
      Uri.parse('$_base${LaptopApiConfig.checkout}'),
      headers: _h,
      body: jsonEncode({
        'identifier': identifier,
        'studentName': studentName,
        if (batch.isNotEmpty) 'batch': batch,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['counts'] != null
          ? _Counts.fromJson(body['counts'] as Map<String, dynamic>)
          : _Counts.empty;
    }
    throw _ApiError(res.statusCode, body['error'] ?? 'Checkout failed');
  }

  static Future<_Counts> returnLaptop(String identifier) async {
    final res = await http.post(
      Uri.parse('$_base${LaptopApiConfig.returnLaptop}'),
      headers: _h,
      body: jsonEncode({'identifier': identifier}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['counts'] != null
          ? _Counts.fromJson(body['counts'] as Map<String, dynamic>)
          : _Counts.empty;
    }
    throw _ApiError(res.statusCode, body['error'] ?? 'Return failed');
  }
}

class _ApiError {
  final int statusCode;
  final String message;
  _ApiError(this.statusCode, this.message);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen  (camera is always visible)
// ─────────────────────────────────────────────────────────────────────────────

class LaptopScannerScreen extends StatefulWidget {
  const LaptopScannerScreen({super.key});
  @override
  State<LaptopScannerScreen> createState() => _LaptopScannerScreenState();
}

class _LaptopScannerScreenState extends State<LaptopScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _camera;
  bool _scanning = true;
  bool _torchOn = false;
  int? _availableCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _safeStart());
  }

  Future<void> _safeStart() async {
    try {
      await _camera.start();
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _camera.stop();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _scanning) {
      _safeStart();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _safeStop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handleScanned(raw);
  }

  Future<void> _handleScanned(String identifier) async {
    if (!mounted) return;
    setState(() => _scanning = false);
    await _safeStop();

    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => _LaptopActionSheet(identifier: identifier),
    );

    if (!mounted) return;

    if (result != null) {
      final color = result.success
          ? const Color(0xFF10B981)
          : Colors.red.shade600;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
        ),
      );
      if (result.success && result.counts != null) {
        setState(() => _availableCount = result.counts!.available);
      }
    }

    setState(() => _scanning = true);
    await _safeStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: _camera, onDetect: _onDetect),

          // Overlay with cut-out
          _ScanOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CamButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Laptop Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Scan a laptop QR sticker',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  _CamButton(
                    icon: _torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: _torchOn ? Colors.amber : Colors.white,
                    onTap: () {
                      _camera.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Available count badge at bottom
          if (_availableCount != null)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.laptop_mac_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_availableCount laptop${_availableCount == 1 ? '' : 's'} available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet  (lookup → checkout form OR return confirm)
// ─────────────────────────────────────────────────────────────────────────────

enum _SheetState { looking, checkout, returning, submitting, error }

class _LaptopActionSheet extends StatefulWidget {
  const _LaptopActionSheet({required this.identifier});
  final String identifier;
  @override
  State<_LaptopActionSheet> createState() => _LaptopActionSheetState();
}

class _LaptopActionSheetState extends State<_LaptopActionSheet> {
  _SheetState _state = _SheetState.looking;
  _LookupResult? _result;
  String _errorMsg = '';

  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _doLookup();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLookup() async {
    try {
      final res = await _LaptopApi.lookup(widget.identifier);
      if (!mounted) return;
      setState(() {
        _result = res;
        _state = res.state == 'available'
            ? _SheetState.checkout
            : _SheetState.returning;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _state = _SheetState.error;
      });
    }
  }

  Future<void> _doCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    setState(() => _state = _SheetState.submitting);
    try {
      final counts = await _LaptopApi.checkout(
        widget.identifier,
        name,
        _batchCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        _SheetResult(
          success: true,
          message: '✅ Assigned to $name',
          counts: counts,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e as _ApiError;
      if (err.statusCode == 409) {
        // Race: reload and show return screen
        setState(() => _state = _SheetState.looking);
        await _doLookup();
      } else {
        Navigator.pop(
          context,
          _SheetResult(success: false, message: err.message),
        );
      }
    }
  }

  Future<void> _doReturn() async {
    setState(() => _state = _SheetState.submitting);
    try {
      final counts = await _LaptopApi.returnLaptop(widget.identifier);
      if (!mounted) return;
      Navigator.pop(
        context,
        _SheetResult(success: true, message: '✅ Returned', counts: counts),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e as _ApiError;
      if (err.statusCode == 409) {
        setState(() => _state = _SheetState.looking);
        await _doLookup();
      } else {
        Navigator.pop(
          context,
          _SheetResult(success: false, message: err.message),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + close row
          Row(
            children: [
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
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SheetState.looking:
        return _buildLoading('Looking up laptop…');
      case _SheetState.submitting:
        return _buildLoading('Processing…');
      case _SheetState.error:
        return _buildError();
      case _SheetState.checkout:
        return _buildCheckout();
      case _SheetState.returning:
        return _buildReturn();
    }
  }

  Widget _buildLoading(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckout() {
    final asset = _result!.asset;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetTile(asset: asset, state: 'available'),
          const SizedBox(height: 20),
          Text(
            'Student Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            decoration: _inputDec('Enter student name', Icons.person_rounded),
          ),
          const SizedBox(height: 12),
          Text(
            'Batch (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _batchCtrl,
            decoration: _inputDec('e.g. MERN-Jul26', Icons.group_rounded),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _doCheckout,
              icon: const Icon(
                Icons.laptop_mac_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Assign',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturn() {
    final asset = _result!.asset;
    final loan = _result!.loan!;
    final fmt = DateFormat('dd MMM, hh:mm a');
    final duration = DateTime.now().difference(loan.checkOutAt);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    final dur = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssetTile(asset: asset, state: 'assigned'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Currently with',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                loan.studentName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (loan.batch.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  loan.batch,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${fmt.format(loan.checkOutAt.toLocal())}  ·  $dur ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _doReturn,
            icon: const Icon(
              Icons.keyboard_return_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Return',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const boxSize = 260.0;
    final top = (size.height - boxSize) / 2 - 40;
    final left = (size.width - boxSize) / 2;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: top,
          left: left,
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: CustomPaint(painter: _BracketPainter()),
          ),
        ),
        Positioned(
          top: top + boxSize + 20,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Point camera at the laptop QR sticker',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const r = 8.0;

    void corner(double ox, double oy, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(ox + sx * len, oy)
          ..lineTo(ox + sx * r, oy)
          ..arcToPoint(
            Offset(ox, oy + sy * r),
            radius: const Radius.circular(r),
            clockwise: sx > 0 ? sy > 0 : sy < 0,
          )
          ..lineTo(ox, oy + sy * len),
        p,
      );
    }

    corner(0, 0, 1, 1);
    corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1);
    corner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CamButton extends StatelessWidget {
  const _CamButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset, required this.state});
  final _LaptopAsset asset;
  final String state;

  @override
  Widget build(BuildContext context) {
    final isAvailable = state == 'available';
    final statusColor = isAvailable ? const Color(0xFF10B981) : Colors.orange;
    final statusLabel = isAvailable ? 'Available' : 'Checked out';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.laptop_mac_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${asset.assetTag}  ·  ${asset.serialNumber}',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
