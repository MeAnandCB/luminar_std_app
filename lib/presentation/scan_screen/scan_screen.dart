import 'dart:convert';
import 'dart:io' show Platform;
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/device_time_utils.dart';

import 'package:luminar_std/presentation/attandance_screen/controller/attandance_controller.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
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
    String? token,
  }) async {
    final String? resolvedToken = token ?? await AppUtils.getAccessKey();
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

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $resolvedToken',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

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

  // Gates the whole flow: attendance validity is checked against
  // DateTime.now(), so a manually-set device clock causes valid QR codes to
  // read as "not yet valid" / "expired". If auto time is off, we block
  // before the dashboard/camera even loads rather than let scans fail with
  // a confusing time-mismatch error.
  bool _checkingAutoTime = true;
  bool _autoTimeDisabled = false;

  // Pre-fetched token — avoids storage read on every scan
  String? _cachedToken;

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
    // Rebuild when the camera's own state changes (e.g. permission denied)
    // so the surrounding overlay (scan frame, zoom controls, status hint) —
    // which are separate Stack layers, not part of MobileScanner's
    // errorBuilder — can hide themselves instead of rendering on top of
    // the error view.
    _controller.addListener(_onCameraStateChanged);
    // Pre-fetch token in parallel with dashboard load
    AppUtils.getAccessKey().then((t) => _cachedToken = t);
    _checkAutoTimeThenLoad();
  }

  void _onCameraStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_autoTimeDisabled) {
        // User likely came back from Settings after enabling it — re-check
        // automatically instead of making them tap something.
        _checkAutoTimeThenLoad();
      } else if (_dashboardLoaded && !_detected && !_isLoading) {
        _safeStart();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onCameraStateChanged);
    _controller.dispose();
    super.dispose();
  }

  // ── Step 0: Auto time check — gates everything below ──────────────────────

  Future<void> _checkAutoTimeThenLoad() async {
    if (mounted) setState(() => _checkingAutoTime = true);
    final enabled = await DeviceTimeUtils.isAutoTimeEnabled();
    if (!mounted) return;
    if (!enabled) {
      setState(() {
        _checkingAutoTime = false;
        _autoTimeDisabled = true;
      });
      return;
    }
    setState(() {
      _checkingAutoTime = false;
      _autoTimeDisabled = false;
    });
    _loadDashboardData();
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
      // Show loading right away — no silent gap before API call
      if (mounted) setState(() { _isLoading = true; _statusText = 'Marking attendance...'; });

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

  // ── Access denied dialog (same as more screen) ───────────────────────────

  void _showAccessDenied() {
    setState(() {
      _detected = false;
      _isLoading = false;
      _statusText = 'Align QR code within the frame';
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.red.shade400, size: 22),
            const SizedBox(width: 8),
            const Text('Access Denied'),
          ],
        ),
        content: const Text(
          'Your access was denied. Please contact your academic counselor.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _safeStart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Validate batchId against enrollments ──────────────────────────

  void _validateAndSubmit(QRPayload payload) {
    // ── Check 2: Required fields present ─────────────────────────────────────
    if (payload.batchId.isEmpty || payload.startTime.isEmpty || payload.endTime.isEmpty) {
      developer.log('Missing required fields in QR', name: 'QRScanner.validate', error: 'missing_fields');
      _showResult(
        success: false,
        title: 'Incomplete QR Code',
        message: 'QR code is missing required information.\nPlease scan the correct session QR.',
      );
      return;
    }

    // ── Check 3: Student ID available ────────────────────────────────────────
    final studentId = _dashboardData?.studentDetails?.basicInfo?.studentId ?? '';
    if (studentId.isEmpty) {
      developer.log('Student ID unavailable', name: 'QRScanner.validate', error: 'no_student_id');
      _showResult(
        success: false,
        title: 'Student Info Missing',
        message: 'Unable to retrieve student information.\nPlease restart the app and try again.',
      );
      return;
    }

    // ── Check 4: Student has enrollments ─────────────────────────────────────
    final enrollments = _dashboardData?.enrollmentDetails?.enrollments ?? [];
    if (enrollments.isEmpty) {
      developer.log('No enrollments found', name: 'QRScanner.validate', error: 'no_enrollments');
      _showResult(
        success: false,
        title: 'No Enrollments',
        message: 'You have no active batch enrollments.',
      );
      return;
    }

    // ── Check 5: Student enrolled in scanned batch ────────────────────────────
    Enrollment? matched;
    for (final e in enrollments) {
      if (e.batchInfo?.uid == payload.batchId) {
        matched = e;
        break;
      }
    }

    if (matched == null) {
      developer.log(
        'Batch not in student enrollments: ${payload.batchId}',
        name: 'QRScanner.validate',
        error: 'not_enrolled',
      );
      _showResult(
        success: false,
        title: 'Not Enrolled',
        message: 'You are not enrolled in this batch.\nPlease verify you are scanning the correct QR.',
      );
      return;
    }

    // ── Check 6: Enrollment record found (uid non-empty) ─────────────────────
    final enrollmentUid = matched.basicInfo?.uid ?? '';
    if (enrollmentUid.isEmpty) {
      developer.log('Matched enrollment has no UID', name: 'QRScanner.validate', error: 'missing_enrollment_uid');
      _showResult(
        success: false,
        title: 'Enrollment Error',
        message: 'Enrollment record not found for this batch.\nPlease contact support.',
      );
      return;
    }

    // ── Check 7: CRM access granted ──────────────────────────────────────────
    final bool crmAccess = matched.basicInfo?.crmAccess ?? true;
    if (!crmAccess) {
      _showAccessDenied();
      return;
    }

    // ── Check 8 & 9: Date and time window ────────────────────────────────────
    final now      = DateTime.now().toUtc();
    final startUtc = DateTime.tryParse(payload.startTime)?.toUtc();
    final endUtc   = DateTime.tryParse(payload.endTime)?.toUtc();

    developer.log(
      '─── Time Validation ───\n'
      '  now       : $now\n'
      '  startTime : $startUtc\n'
      '  endTime   : $endUtc',
      name: 'QRScanner.timeCheck',
    );

    if (startUtc == null || endUtc == null) {
      _showResult(
        success: false,
        title: 'Invalid QR Code',
        message: 'The QR code contains an invalid time format.\nPlease scan the correct session QR.',
      );
      return;
    }

    // Date check: local calendar date must match QR start date
    final nowLocal   = now.toLocal();
    final startLocal = startUtc.toLocal();
    final todayDate  = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final qrDate     = DateTime(startLocal.year, startLocal.month, startLocal.day);
    if (todayDate != qrDate) {
      _showResult(
        success: false,
        title: 'Wrong Date',
        message:
            'This QR is for ${DateFormat('dd MMM yyyy').format(startLocal)}.\n'
            'Please scan today\'s session QR.',
      );
      return;
    }

    if (now.isBefore(startUtc)) {
      _showResult(
        success: false,
        title: 'QR Not Yet Valid',
        message:
            'This QR code is not yet valid.\n'
            'Session starts at ${DateFormat('hh:mm a').format(startLocal)}.\n\n'
            'If your device time is set manually and isn\'t accurate, this '
            'can happen even during a valid session — the attendance QR '
            'refreshes every 60 seconds. Please check that "Set time '
            'automatically" is on in your device settings.',
        showTimeSettingsHint: true,
      );
      return;
    }

    if (now.isAfter(endUtc)) {
      _showResult(
        success: false,
        title: 'QR Code Expired',
        message:
            'This QR code has expired.\n'
            'Session ended at ${DateFormat('hh:mm a').format(endUtc.toLocal())}.\n\n'
            'If your device time is set manually and isn\'t accurate, this '
            'can happen even during a valid session — the attendance QR '
            'refreshes every 60 seconds. Please check that "Set time '
            'automatically" is on in your device settings.',
        showTimeSettingsHint: true,
      );
      return;
    }

    developer.log(
      '─── All Checks Passed ───\n'
      '  batchName     : ${matched.batchInfo?.batchName}\n'
      '  enrollmentUid : $enrollmentUid\n'
      '  studentId     : $studentId',
      name: 'QRScanner.validate',
    );

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
      token: _cachedToken,
    );
  }

  // ── Step 4: Call attendance API ───────────────────────────────────────────

  Future<void> _callAttendanceApi({
    required String batchId,
    required String sessionId,
    required String studentId,
    required String batchName,
    String? token,
  }) async {
    // Loading state already set in _onDetect; set again in case called directly
    if (!_isLoading) setState(() { _isLoading = true; _statusText = 'Marking attendance...'; });

    try {
      final result = await AttendanceService.markAttendance(
        batchId: batchId,
        sessionId: sessionId,
        studentId: studentId,
        token: token,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Refresh attendance data so the attendance screen shows updated records
        final attendanceProvider = context.read<AttendanceProvider>();
        if (attendanceProvider.selectedBatch != null) {
          attendanceProvider.loadAttendance();
        }

        // created == false means attendance was already recorded in this session
        final data = result['data'];
        final alreadyMarked = data is Map && data['created'] == false;

        if (alreadyMarked) {
          final date = (data['date'] as String?) ?? '';
          _showResult(
            success: false,
            title: 'Already Marked',
            message:
                'Your attendance for $batchName\nwas already recorded${date.isNotEmpty ? ' on $date' : ''}.',
            overrideColor: const Color(0xFFFFA726),
            overrideIcon: Icons.info_rounded,
          );
        } else {
          _showResult(
            success: true,
            title: 'Attendance Marked!',
            message:
                '🎉 Your attendance has been successfully recorded for\n$batchName.\nHave a great session!',
          );
        }
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
          message:
              '${msg.toString()}\n\n'
              'The attendance QR refreshes every 60 seconds — if your '
              'device time is set manually and isn\'t accurate, scans can '
              'fail like this even during a valid session. Please check '
              'that "Set time automatically" is on in your device settings.',
          showTimeSettingsHint: true,
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
    Color? overrideColor,
    IconData? overrideIcon,
    bool showTimeSettingsHint = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        success: success,
        title: title,
        message: message,
        overrideColor: overrideColor,
        overrideIcon: overrideIcon,
        onPressed: () {
          Navigator.pop(context);
          // Clear scanned data and restart camera
          setState(() {
            _detected = false;
            _isLoading = false;
            _statusText = 'Align QR code within the frame';
          });
          _safeStart();
        },
        // iOS has no API to open Date & Time settings or check the auto-time
        // toggle, so there's nothing useful for this button to do there —
        // show the warning text only, no dead-end button.
        onCheckTimeSettings: (showTimeSettingsHint && Platform.isAndroid)
            ? _openDateSettings
            : null,
      ),
    );
  }

  // Wraps DeviceTimeUtils.openDateSettings with a visible fallback — if the
  // native channel call fails (e.g. app was hot-reloaded instead of fully
  // rebuilt after a native code change), tell the user instead of the
  // button silently doing nothing.
  Future<void> _openDateSettings() async {
    final opened = await DeviceTimeUtils.openDateSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't open Settings automatically. Please open your "
            'device\'s Date & Time settings manually.',
          ),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
    }
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
    context.watch<ThemeProvider>();

    if (_checkingAutoTime) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00C2A8), strokeWidth: 3),
        ),
      );
    }

    if (_autoTimeDisabled) {
      return _AutoTimeRequiredView(
        onOpenSettings: _openDateSettings,
        onRetry: _checkAutoTimeThenLoad,
      );
    }

    // The camera's own error state (e.g. permission denied) — everything
    // below other than the top bar and the error view itself must hide
    // when this is set, since MobileScanner's errorBuilder only replaces
    // the camera-feed layer, not the rest of the Stack.
    final hasCameraError = _controller.value.error != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
            errorBuilder: (context, error) {
              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                return _CameraPermissionDeniedView(onRetry: _safeStart);
              }
              return _CameraErrorView(
                message: error.errorDetails?.message ?? error.errorCode.message,
              );
            },
          ),

          // Scan frame overlay
          if (!hasCameraError) const _ScanOverlay(),

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
                    onTap: (_dashboardLoaded && !hasCameraError) ? _toggleFlash : () {},
                  ),
                ],
              ),
            ),
          ),

          // Full-screen loading overlay (dashboard fetch OR API call)
          if (!hasCameraError && (_isLoading || (!_dashboardLoaded && !_dashboardError)))
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
          if (!hasCameraError && _dashboardError)
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
          if (!hasCameraError && !_isLoading && !_dashboardError)
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
// Camera Permission Denied — shown in place of the camera feed via
// MobileScanner's errorBuilder when the OS camera permission isn't granted.
// ─────────────────────────────────────────────────────────────────────────────

class _CameraPermissionDeniedView extends StatelessWidget {
  const _CameraPermissionDeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_rounded,
                  color: Color(0xFFFF5252),
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Luminar Technolab needs camera access to scan attendance '
                'QR codes.\n\nPlease grant camera permission in your device '
                'settings, then come back to scan.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Open App Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  "I've granted it — Retry",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Error — generic fallback for any other MobileScanner error
// (e.g. unsupported device, camera already in use).
// ─────────────────────────────────────────────────────────────────────────────

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 52),
              const SizedBox(height: 16),
              const Text(
                'Camera Error',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto Time Required — blocks scanning until the device's automatic
// date/time is on, since attendance validity is checked against the
// device clock.
// ─────────────────────────────────────────────────────────────────────────────

class _AutoTimeRequiredView extends StatelessWidget {
  const _AutoTimeRequiredView({required this.onOpenSettings, required this.onRetry});

  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFFFA726),
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Turn On Automatic Date & Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your device time is set manually, which can make valid '
                'attendance QR codes appear expired or not yet active.\n\n'
                'Please turn on "Set time automatically" in your device '
                'settings, then come back to scan again.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Open Date & Time Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  "I've enabled it — Retry",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    this.overrideColor,
    this.overrideIcon,
    this.onCheckTimeSettings,
  });

  final bool success;
  final String title;
  final String message;
  final VoidCallback onPressed;
  final Color? overrideColor;
  final IconData? overrideIcon;
  final VoidCallback? onCheckTimeSettings;

  @override
  Widget build(BuildContext context) {
    final color = overrideColor ?? (success ? const Color(0xFF00C2A8) : const Color(0xFFFF5252));
    final icon  = overrideIcon  ?? (success ? Icons.check_circle_rounded : Icons.error_rounded);

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
                child: const Text('Close'),
              ),
            ),
            if (onCheckTimeSettings != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onCheckTimeSettings,
                icon: const Icon(Icons.settings_rounded, size: 16, color: Colors.white70),
                label: const Text(
                  'Check Time Settings',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
