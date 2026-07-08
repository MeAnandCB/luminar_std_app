import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../api/laptop_api.dart';
import '../config.dart';
import '../widgets/assign_sheet.dart';
import '../widgets/return_sheet.dart';
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
  bool _awaitingRackScan = false;
  LookupResult? _pendingRackReturn; // track the laptop being returned
  int? _availableCount;
  String _scanHint = 'Scan a laptop QR sticker';
  Timer? _returnRackTimer;
  Completer<String>? _rackScanCompleter;

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
    _returnRackTimer?.cancel();
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
    if (_awaitingRackScan && _rackScanCompleter != null && !_rackScanCompleter!.isCompleted) {
      // Rack scan detected - stop camera and complete
      _inFlight = true;
      await _safeStop();
      _rackScanCompleter?.complete(identifier);
      return;
    }

    _inFlight = true;
    await _safeStop();

    try {
      final result = await _api!.lookup(identifier);
      if (!mounted) return;

      if (result.state == 'available') {
        await _showSheet(identifier, result);
      } else {
        await _showReturnRackFlow(result);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      _inFlight = false;
      if (mounted) await _safeStart();
    }
  }

  Future<void> _showReturnRackFlow(LookupResult result) async {
    // Restart camera to allow rack scan detection
    if (mounted) await _safeStart();

    // Reset in-flight guard to allow rack scan detection
    _inFlight = false;

    // Setup completer and timer
    _rackScanCompleter = Completer<String>();
    final rackFuture = _rackScanCompleter!.future;
    final timeoutFuture = Future.delayed(const Duration(seconds: 5));

    // Update UI to show timer overlay on camera
    setState(() {
      _awaitingRackScan = true;
      _pendingRackReturn = result;
      _scanHint = 'Now scan the rack QR within 5 seconds';
    });

    // Wait for either rack scan or timeout
    String? rackId;
    try {
      rackId = await Future.any<dynamic>([
        rackFuture,
        timeoutFuture.then((_) => throw TimeoutException('Rack scan timeout')),
      ]).then<String?>((v) => v is String ? v : null);
    } catch (_) {
      rackId = null;
    }

    _rackScanCompleter = null;
    _returnRackTimer?.cancel();

    if (!mounted) return;

    if (rackId != null && rackId.isNotEmpty) {
      await _completeReturnWithFeedback(result, rackId);
    } else {
      setState(() {
        _awaitingRackScan = false;
        _pendingRackReturn = null;
        _scanHint = 'Scan a laptop QR sticker';
      });
      _showSnack(
        'Return timed out. Please scan the laptop again to start a new return.',
        error: true,
      );
    }
  }

  Future<void> _completeReturnWithFeedback(
    LookupResult result,
    String rackIdentifier,
  ) async {
    if (!mounted) return;
    await _safeStop();

    _rackScanCompleter = null;
    _returnRackTimer?.cancel();

    final outcome = await showModalBottomSheet<SheetOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnFeedbackSheet(
        api: _api!,
        result: result,
        rackId: rackIdentifier,
      ),
    );

    if (!mounted) return;

    setState(() {
      _awaitingRackScan = false;
      _pendingRackReturn = null;
      _scanHint = 'Scan a laptop QR sticker';
    });

    if (outcome != null) {
      _showSnack(outcome.message, error: outcome.isError);
      if (!outcome.isError && outcome.counts != null) {
        setState(() => _availableCount = outcome.counts!.available);
      }
    }

    if (mounted) await _safeStart();
  }

  Future<void> _showSheet(String identifier, LookupResult result) async {
    final outcome = await showModalBottomSheet<SheetOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => result.state == 'available'
          ? AssignSheet(
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

  // ── Settings ──────────────────────────────────────────────────────────────

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _camera, onDetect: _onDetect),
          _ScanOverlay(),
          if (_awaitingRackScan && _pendingRackReturn != null)
            _RackScanTimerOverlay(result: _pendingRackReturn!),
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Laptop Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _scanHint,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
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

// ── Return Rack Modal – shows countdown and asset details ─────────────────────

class _RackScanTimerOverlay extends StatefulWidget {
  const _RackScanTimerOverlay({required this.result});
  final LookupResult result;

  @override
  State<_RackScanTimerOverlay> createState() => _RackScanTimerOverlayState();
}

class _RackScanTimerOverlayState extends State<_RackScanTimerOverlay> {
  late Timer _timer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.result.asset;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Asset info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.laptop_mac_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${asset.assetTag}  ·  ${asset.serialNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Laptop scan completed',
                    style: TextStyle(
                      color: Colors.amber.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Now scan the rack QR to complete the return',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Timer
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'seconds remaining',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Return Feedback Sheet – shows asset details and gets feedback ─────────────

class _ReturnFeedbackSheet extends StatefulWidget {
  const _ReturnFeedbackSheet({
    required this.api,
    required this.result,
    required this.rackId,
  });

  final LaptopApi api;
  final LookupResult result;
  final String rackId;

  @override
  State<_ReturnFeedbackSheet> createState() => _ReturnFeedbackSheetState();
}

class _ReturnFeedbackSheetState extends State<_ReturnFeedbackSheet> {
  bool _loading = false;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _doReturn() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.returnLaptop(
        widget.result.asset.id,
        rackCode: widget.rackId,
        earlyReturnFeedback: _feedbackCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        SheetOutcome(
          message: 'Laptop returned to rack ${widget.rackId}',
          counts: res.counts,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(
        context,
        SheetOutcome(
          message: e.message,
          counts: null,
          isError: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.result.asset;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.laptop_mac_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${asset.assetTag}  ·  ${asset.serialNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Scanned from: ${widget.rackId}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _feedbackCtrl,
            enabled: !_loading,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any feedback? (optional)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _doReturn,
              icon: const Icon(
                Icons.keyboard_return_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Complete Return',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: Colors.grey.shade400,
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
}
