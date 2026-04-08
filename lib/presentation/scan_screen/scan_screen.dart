import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';

import 'package:luminar_std/presentation/attandance_screen/controller/attandance_controller.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// NOTE: Adjust these import paths to match your project structure
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QR Payload Model
// ─────────────────────────────────────────────────────────────────────────────

class QRPayload {
  final String batchId;
  final String startTime;
  final String endTime;
  final int timestamp;
  final String? sessionId; // Made optional

  QRPayload({
    required this.batchId,
    required this.startTime,
    required this.endTime,
    required this.timestamp,
    this.sessionId, // Optional field
  });

  factory QRPayload.fromJson(Map<String, dynamic> json) {
    return QRPayload(
      batchId: json['batchId']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      sessionId: json['sessionId']?.toString(), // Optional, may be null
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance API Service
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceService {
  static const String _base =
      GlobalLinks.baseUrl; // Ensure this is defined in your GlobalLinks

  static Future<Map<String, dynamic>> markAttendance({
    required String batchId,
    required String sessionId,
    required String studentId,
  }) async {
    final String? token = await AppUtils.getAccessKey();
    final uri = Uri.parse(
      '$_base${AppEndpoints.attandance}',
    ); // Ensure this endpoint is defined

    final payload = {
      'batch_id': batchId,
      'session_id': sessionId,
      'student_id': studentId,
    };

    developer.log(
      '─── Attendance Request ───\n'
      '  POST       : $uri\n'
      '  batch_id   : $batchId\n'
      '  session_id : $sessionId\n'
      '  student_id : $studentId\n'
      '  payload    : ${jsonEncode(payload)}',
      name: 'AttendanceService.request',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    developer.log(
      '─── Attendance Response ───\n'
      '  Status  : ${response.statusCode}\n'
      '  Body    : ${response.body}',
      name: 'AttendanceService.response',
      error: (response.statusCode >= 400) ? 'HTTP ${response.statusCode}' : null,
    );

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = {'raw_body': response.body};
    }

    final httpSuccess = response.statusCode == 200 || response.statusCode == 201;
    // If the body explicitly has a "success" field, honour it;
    // otherwise fall back to the HTTP status code.
    final bodySuccess = data['success'];
    final isSuccess = bodySuccess is bool ? bodySuccess : httpSuccess;

    return {
      'statusCode': response.statusCode,
      'success': isSuccess,
      ...data,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QR Scanner Screen (using DashboardController)
// ─────────────────────────────────────────────────────────────────────────────

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _detected = false;
  bool _isLoading = false;
  bool _isFlashOn = false;
  String _statusText = 'Loading your enrollment data...';
  double _zoomLevel = 0.0; // 0.0 = min, 1.0 = max

  Dashboard? _dashboardData;
  bool _dashboardLoaded = false;
  bool _dashboardError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    // Camera stays paused until dashboard data is loaded
    _controller.stop();
    _loadDashboardData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _dashboardLoaded &&
        !_detected &&
        !_isLoading) {
      _safeStart();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // ── Step 1: Load dashboard data, then start camera ───────────────────────────

  Future<void> _loadDashboardData() async {
    setState(() {
      _dashboardError = false;
      _dashboardLoaded = false;
      _statusText = 'Loading your enrollment data...';
    });

    try {
      final dashboardController = Provider.of<DashboardController>(
        context,
        listen: false,
      );

      // Fetch dashboard data if not already loaded
      if (dashboardController.dashboard == null) {
        await dashboardController.getDashboardData(context: context);
      }

      if (!mounted) return;

      if (dashboardController.error != null ||
          dashboardController.dashboard == null) {
        setState(() {
          _dashboardError = true;
          _statusText = 'Could not load enrollment data.';
        });
        return;
      }

      _dashboardData = dashboardController.dashboard;
      _dashboardLoaded = true;

      final enrollments = _dashboardData?.enrollmentDetails?.enrollments ?? [];
      developer.log(
        '─── Dashboard Enrollments (${enrollments.length}) ───\n' +
            enrollments.asMap().entries.map((e) =>
              '  [${e.key + 1}] ${e.value.batchInfo?.batchName}\n'
              '      batchUid     : ${e.value.batchInfo?.uid}\n'
              '      enrollmentUid: ${e.value.basicInfo?.uid}\n'
              '      status       : ${e.value.status?.name}'
            ).join('\n'),
        name: 'QRScanner.dashboard',
      );

      setState(() => _statusText = 'Align QR code within the frame');
      _safeStart();
    } catch (e) {
      developer.log('Dashboard load error: $e', name: 'QRScanner.dashboard', error: e);
      if (!mounted) return;
      setState(() {
        _dashboardError = true;
        _statusText = 'Could not load enrollment data.';
      });
    }
  }

  // ── Step 2: QR detected — fires exactly once ──────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_detected || _isLoading || !_dashboardLoaded) return;

    for (final Barcode barcode in capture.barcodes) {
      final String? raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      // Stop immediately — single fire guaranteed
      _detected = true;
      _controller.stop();

      developer.log(
        '─── QR Scanned ───\n'
        '  Format  : ${barcode.format.name}\n'
        '  Raw     : $raw',
        name: 'QRScanner.detect',
      );

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final payload = QRPayload.fromJson(json);

        developer.log(
          '─── QR Payload Parsed ───\n'
          '  batchId   : ${payload.batchId}\n'
          '  sessionId : ${payload.sessionId ?? "(none)"}\n'
          '  startTime : ${payload.startTime}\n'
          '  endTime   : ${payload.endTime}\n'
          '  timestamp : ${payload.timestamp}',
          name: 'QRScanner.payload',
        );

        _validateAndSubmit(payload);
      } catch (_) {
        _showResult(
          success: false,
          title: 'Invalid QR Code',
          message:
              'This is not a valid attendance QR code.\nPlease scan the correct session QR.',
        );
      }
      break;
    }
  }

  // ── Step 3: Validate batchId against enrollments ──────────────────────────

  void _validateAndSubmit(QRPayload payload) {
    final enrollments = _dashboardData?.enrollmentDetails?.enrollments ?? [];
    Enrollment? matched;

    for (final e in enrollments) {
      if (e.batchInfo?.uid == payload.batchId) {
        matched = e;
        break;
      }
    }

    if (matched == null) {
      developer.log(
        'No matching batch for batchId: ${payload.batchId}',
        name: 'QRScanner.validate',
        error: 'batch_not_found',
      );
      _showResult(
        success: false,
        title: 'Session Not Found',
        message:
            'This session does not belong to your enrolled batches.\nPlease verify you are scanning the correct QR.',
      );
      return;
    }

    final studentId =
        _dashboardData?.studentDetails?.basicInfo?.studentId ?? '';

    developer.log(
      '─── Batch Matched ───\n'
      '  batchName     : ${matched.batchInfo?.batchName}\n'
      '  enrollmentUid : ${matched.basicInfo?.uid}\n'
      '  studentId     : $studentId',
      name: 'QRScanner.validate',
    );

    if (studentId.isEmpty) {
      _showResult(
        success: false,
        title: 'Error',
        message: 'Could not retrieve student information.',
      );
      return;
    }

    final sessionIdToUse =
        (payload.sessionId != null && payload.sessionId!.isNotEmpty)
        ? payload.sessionId!
        : '';

    developer.log(
      'sessionId resolved: "${sessionIdToUse.isEmpty ? "(empty)" : sessionIdToUse}"',
      name: 'QRScanner.validate',
    );

    _callAttendanceApi(
      batchId: matched.batchInfo?.uid ?? payload.batchId,
      sessionId: sessionIdToUse,
      studentId: studentId,
      batchName: matched.batchInfo?.batchName ?? 'Unknown Batch',
    );
  }

  // ── Step 4: Call attendance API ───────────────────────────────────────────

  Future<void> _callAttendanceApi({
    required String batchId,
    required String sessionId,
    required String studentId,
    required String batchName,
  }) async {
    setState(() {
      _isLoading = true;
      _statusText = 'Marking attendance...';
    });

    try {
      final result = await AttendanceService.markAttendance(
        batchId: batchId,
        sessionId: sessionId,
        studentId: studentId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Refresh attendance data so the attendance screen shows updated records
        final attendanceProvider = context.read<AttendanceProvider>();
        if (attendanceProvider.selectedBatch != null) {
          attendanceProvider.loadAttendance();
        }

        _showResult(
          success: true,
          title: 'Attendance Marked!',
          message:
              '🎉 Your attendance has been successfully recorded for\n$batchName.\nHave a great session!',
        );
      } else {
        // Show whatever the server returned
        final msg =
            result['message'] ??
            result['detail'] ??
            result['error'] ??
            result['raw_body'] ??
            'Status ${result['statusCode']} — Something went wrong.';
        developer.log('API failure: $result', name: 'QRScanner.api', error: 'status_${result['statusCode']}');
        _showResult(
          success: false,
          title: 'Attendance Failed (${result['statusCode']})',
          message: msg.toString(),
        );
      }
    } catch (e) {
      developer.log('Network error: $e', name: 'QRScanner.api', error: e);
      if (!mounted) return;
      _showResult(
        success: false,
        title: 'Network Error',
        message:
            'Could not connect to the server.\nCheck your internet and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Result dialog — resets scanner on dismiss ─────────────────────────────

  void _showResult({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        success: success,
        title: title,
        message: message,
        onPressed: () {
          Navigator.pop(context); // close dialog
          // Reset and restart scanner
          setState(() {
            _detected = false;
            _statusText = 'Align QR code within the frame';
          });
          _safeStart();
        },
      ),
    );
  }

  Future<void> _toggleFlash() async {
    await _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  Future<void> _safeStart() async {
    try {
      await _controller.start();
    } catch (e) {
      developer.log('camera start skipped: $e', name: 'QRScanner.camera');
    }
  }

  Future<void> _setZoom(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await _controller.setZoomScale(clamped);
    setState(() => _zoomLevel = clamped);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),

          // Scan frame overlay
          const _ScanOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _CircleBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Title
                  const Text(
                    'Scan Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  // Flash toggle (only when camera is active)
                  _CircleBtn(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    active: _isFlashOn,
                    onTap: _dashboardLoaded ? _toggleFlash : () {},
                  ),
                ],
              ),
            ),
          ),

          // Full-screen loading overlay (dashboard fetch OR API call)
          if (_isLoading || (!_dashboardLoaded && !_dashboardError))
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF00C2A8),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isLoading
                          ? 'Marking attendance...'
                          : 'Loading enrollment data...',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

          // Dashboard error state
          if (_dashboardError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFFF5252),
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load enrollment data',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDashboardData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C2A8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom status hint + zoom controls
          if (!_isLoading && !_dashboardError)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Zoom controls
                  if (_dashboardLoaded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _setZoom(_zoomLevel - 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove, color: Colors.white, size: 18),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _zoomLevel,
                              min: 0.0,
                              max: 1.0,
                              activeColor: const Color(0xFF00C2A8),
                              inactiveColor: Colors.white24,
                              onChanged: _setZoom,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _setZoom(_zoomLevel + 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Icon(
                    _dashboardLoaded
                        ? Icons.qr_code_scanner
                        : Icons.hourglass_top_rounded,
                    color: const Color(0xFF00C2A8),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan Overlay (same as before)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _OverlayPainter(), child: const SizedBox.expand());
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double s = 260.0;
    final r = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: s,
      height: s,
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(20)))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withValues(alpha: 0.68),
    );

    final p = Paint()
      ..color = const Color(0xFF00C2A8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cs = 30.0;
    final l = r.left;
    final t = r.top;
    final ri = r.right;
    final b = r.bottom;

    canvas.drawPath(
      Path()
        ..moveTo(l, t + cs)
        ..lineTo(l, t + 10)
        ..arcToPoint(Offset(l + 10, t), radius: const Radius.circular(10))
        ..lineTo(l + cs, t),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(ri - cs, t)
        ..lineTo(ri - 10, t)
        ..arcToPoint(Offset(ri, t + 10), radius: const Radius.circular(10))
        ..lineTo(ri, t + cs),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l, b - cs)
        ..lineTo(l, b - 10)
        ..arcToPoint(
          Offset(l + 10, b),
          radius: const Radius.circular(10),
          clockwise: false,
        )
        ..lineTo(l + cs, b),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(ri - cs, b)
        ..lineTo(ri - 10, b)
        ..arcToPoint(
          Offset(ri, b - 10),
          radius: const Radius.circular(10),
          clockwise: false,
        )
        ..lineTo(ri, b - cs),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle Button (same as before)
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF00C2A8).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Dialog (same as before)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.success,
    required this.title,
    required this.message,
    required this.onPressed,
  });

  final bool success;
  final String title;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF00C2A8) : const Color(0xFFFF5252);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(success ? 'Great! Done' : 'Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
