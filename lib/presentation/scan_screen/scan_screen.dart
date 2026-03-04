import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class ScannerApp extends StatelessWidget {
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student QR Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF6C5CE7),
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        useMaterial3: true,
      ),
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _hasPermission = false;
  bool _isProcessing = false;
  MobileScannerController? _scannerController;
  Barcode? _lastScannedCode;
  final Duration _scanDelay = const Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkPermissions() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();

    // Internet permission is automatically granted on Android/iOS
    // No need to explicitly request it

    if (cameraStatus.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: _isFlashOn,
      );
    } else if (cameraStatus.isDenied) {
      _showPermissionDialog();
    } else if (cameraStatus.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('Camera permission is needed to scan QR codes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final status = await Permission.camera.request();
              if (status.isGranted) {
                setState(() {
                  _hasPermission = true;
                });
                _scannerController = MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                  torchEnabled: _isFlashOn,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is permanently denied. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!mounted || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      if (barcode.displayValue != null && barcode.displayValue!.isNotEmpty) {
        _processScannedCode(barcode);
        break;
      }
    }
  }

  Future<void> _processScannedCode(Barcode barcode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = barcode;
      _isScanning = false;
    });

    // Vibrate on successful scan
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    HapticFeedback.heavyImpact();

    // Auto hide result after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted && !_isScanning) {
        setState(() {
          _isScanning = true;
          _isProcessing = false;
        });
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _scannerController?.toggleTorch();
    HapticFeedback.lightImpact();
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
      _lastScannedCode = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          if (_hasPermission && _scannerController != null && _isScanning)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _handleBarcode,
              fit: BoxFit.cover,
            )
          else if (!_hasPermission)
            // Permission required placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [Color(0xFF1A1B2F), Color(0xFF2D2F4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Enable Camera'),
                    ),
                  ],
                ),
              ),
            )
          else if (_isScanning)
            // Loading state
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              ),
            ),

          // Scanner Overlay (only when scanning)
          if (_isScanning && _hasPermission)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar with only icons (no text)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // Flash button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _toggleFlash,
                              icon: Icon(
                                _isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Scanner Frame
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Scanner frame
                          Container(
                            width: size.width * 0.7,
                            height: size.width * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // Corner decorations
                          ..._buildScannerCorners(size),

                          // Animated scan line
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Positioned(
                                top:
                                    (size.height / 2) -
                                    (size.width * 0.35) +
                                    (size.width * 0.7 * _scanAnimation.value),
                                child: Container(
                                  width: size.width * 0.7,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(
                                          0xFF6C5CE7,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xFF8B7BF2,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xFF6C5CE7,
                                        ).withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom padding only (no text)
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

          // Scan Result Overlay (shows when QR is scanned)
          if (!_isScanning && _lastScannedCode != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: SafeArea(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(30),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Icon(
                            Icons.qr_code,
                            size: 40,
                            color: Color(0xFF6C5CE7),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _lastScannedCode!.displayValue ?? 'QR-2025-001',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _resetScanner,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Icon(Icons.refresh_rounded),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _resetScanner();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5CE7),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Icon(Icons.check_rounded),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildScannerCorners(Size size) {
    double cornerSize = 30;
    double frameSize = size.width * 0.7;
    double left = (size.width - frameSize) / 2;
    double top = (size.height - frameSize) / 2 - 40;

    return [
      // Top Left
      Positioned(
        left: left,
        top: top,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
              left: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        right: left,
        top: top,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
              right: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        left: left,
        bottom: MediaQuery.of(context).size.height - top - frameSize,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
              left: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        right: left,
        bottom: MediaQuery.of(context).size.height - top - frameSize,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
              right: const BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
    ];
  }
}
