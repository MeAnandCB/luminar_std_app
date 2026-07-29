import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../api/laptop_api.dart';
import '../config.dart';
import '../widgets/return_sheet.dart';
import '../widgets/take_sheet.dart';
import 'history_screen.dart';

class LaptopScanScreen extends StatefulWidget {
  const LaptopScanScreen({
    super.key,
    this.prefillName = '',
    this.prefillStudentId = '',
    this.prefillBatch = '',
  });

  final String prefillName;
  final String prefillStudentId;
  final String prefillBatch;

  @override
  State<LaptopScanScreen> createState() => _LaptopScanScreenState();
}

class _LaptopScanScreenState extends State<LaptopScanScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _camera;
  AppConfigLap? _config;
  LaptopApi? _api;

  bool _scanning = false; // true only when camera is ready and accepting scans
  bool _torchOn = false;
  bool _inFlight = false; // guard against double-detect during a request
  int? _availableCount;

  static const _scanHint = 'Scan a laptop QR sticker';

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
    _boot();
  }

  Future<void> _boot() async {
    final cfg = await AppConfigLap.load();
    if (!mounted) return;
    setState(() {
      _config = cfg;
      _api = LaptopApi(cfg);
    });
    await _safeStart();
  }

  Future<void> _safeStart() async {
    try {
      await _camera.start();
      if (mounted) setState(() => _scanning = true);
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _camera.stop();
    } catch (_) {}
    if (mounted) setState(() => _scanning = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _config != null && !_inFlight) {
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

  // ── Scan → lookup → sheet ─────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning || _inFlight) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handleScan(raw);
  }

  Future<void> _handleScan(String identifier) async {
    _inFlight = true;
    await _safeStop();

    try {
      final result = await _api!.lookup(identifier);
      if (!mounted) return;

      if (result.isAccessory) {
        _showSnack('Scan the laptop first', error: true);
        return;
      }

      await _showSheet(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      _inFlight = false;
      if (mounted) await _safeStart();
    }
  }

  Future<void> _showSheet(LookupResult result) async {
    if (result.state == 'available') {
      // The laptop scan that triggered this flow gets its own confirm
      // dialog before anything opens — cancelling here means the Take
      // flow never starts at all.
      final asset = result.asset!;
      final confirmed = await _confirmDialog(
        '${asset.name} (${asset.assetTag})',
        'Add?',
      );
      if (!mounted || !confirmed) return;
    }

    final outcome = await showModalBottomSheet<SheetOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => result.state == 'available'
          ? TakeSheet(
              api: _api!,
              result: result,
              prefillName: widget.prefillName,
              prefillStudentId: widget.prefillStudentId,
              prefillBatch: widget.prefillBatch,
            )
          : ReturnSheet(api: _api!, result: result),
    );

    if (!mounted || outcome == null) return;

    _showSnack(outcome.message, error: outcome.isError);
    if (!outcome.isError && outcome.counts != null) {
      setState(() => _availableCount = outcome.counts!.available);
    }
  }

  Future<bool> _confirmDialog(String title, String message) async {
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

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: error ? Colors.red.shade600 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<void> _openHistory() async {
    if (_api == null) return;
    await _safeStop();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LaptopHistoryScreen(api: _api!, studentId: widget.prefillStudentId),
      ),
    );
    if (mounted) await _safeStart();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _camera, onDetect: _onDetect),
          _ScanOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CamBtn(
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
                        _scanHint,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CamBtn(
                        icon: _torchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _torchOn ? Colors.amber : Colors.white,
                        onTap: () {
                          _camera.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                      ),
                      const SizedBox(width: 8),
                      _CamBtn(icon: Icons.history_rounded, onTap: _openHistory),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                    border: Border.all(color: Colors.white24),
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
          if (_inFlight)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Scan overlay ──────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const box = 260.0;
    final top = (size.height - box) / 2 - 40;
    final left = (size.width - box) / 2;

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
                  width: box,
                  height: box,
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
            width: box,
            height: box,
            child: CustomPaint(painter: _BracketPainter()),
          ),
        ),
        Positioned(
          top: top + box + 20,
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

// ── Tiny camera button ────────────────────────────────────────────────────────

class _CamBtn extends StatelessWidget {
  const _CamBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
