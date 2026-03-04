import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  bool _isFlashOn = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview placeholder (simulated for demo)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1B2F), Color(0xFF2D2F4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Scan line animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ScannerLinePainter(
                        scanPosition: _scanAnimation.value,
                        size: size,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Scanner Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
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
                      // Title
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Scan Student QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                          onPressed: () {
                            setState(() {
                              _isFlashOn = !_isFlashOn;
                            });
                            HapticFeedback.lightImpact();
                          },
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

                Spacer(),

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
                              color: Color(0xFF6C5CE7).withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Corner decorations
                      ..._buildScannerCorners(size),
                      // Center icon
                      Icon(
                        Icons.qr_code_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 100,
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Bottom Info
                Container(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      // Instruction text
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Align QR code within the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Student count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF6C5CE7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '24 students present today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scan Result Overlay (shows when QR is scanned)
          if (!_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: SafeArea(
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(30),
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF6C5CE7).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 60,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Student Found!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: STD2025001 • Grade: 10th',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isScanning = true;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text('Scan Again'),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isScanning = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Attendance marked for John Doe',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF6C5CE7),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text('Mark Present'),
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
      // Floating scan button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.heavyImpact();
          setState(() {
            _isScanning = false; // Simulate successful scan
          });

          // Auto hide after 3 seconds (simulating scan)
          Timer(Duration(seconds: 3), () {
            if (mounted && !_isScanning) {
              setState(() {
                _isScanning = true;
              });
            }
          });
        },
        backgroundColor: Color(0xFF6C5CE7),
        child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildScannerCorners(Size size) {
    double cornerSize = 30;
    double frameSize = size.width * 0.7;
    double left = (size.width - frameSize) / 2;
    double top =
        (MediaQuery.of(context).size.height - frameSize) / 2 -
        40; // Adjust for safe area

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
              top: BorderSide(color: Color(0xFF6C5CE7), width: 4),
              left: BorderSide(color: Color(0xFF6C5CE7), width: 4),
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
              top: BorderSide(color: Color(0xFF6C5CE7), width: 4),
              right: BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        left: left,
        bottom: top,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF6C5CE7), width: 4),
              left: BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        right: left,
        bottom: top,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF6C5CE7), width: 4),
              right: BorderSide(color: Color(0xFF6C5CE7), width: 4),
            ),
          ),
        ),
      ),
    ];
  }
}

class ScannerLinePainter extends CustomPainter {
  final double scanPosition;
  final Size size;

  ScannerLinePainter({required this.scanPosition, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final frameSize = size.width * 0.7;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2 - 40;

    final scanLineY = top + (frameSize * scanPosition);

    // Create gradient for scan line
    final shader = LinearGradient(
      colors: [
        Colors.transparent,
        Color(0xFF6C5CE7).withOpacity(0.8),
        Color(0xFF8B7BF2).withOpacity(0.8),
        Color(0xFF6C5CE7).withOpacity(0.8),
        Colors.transparent,
      ],
      stops: [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(left, scanLineY - 30, frameSize, 60));

    // Draw scan line
    canvas.drawRect(
      Rect.fromLTWH(left, scanLineY - 2, frameSize, 4),
      Paint()
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Draw small dots on the sides
    final dotPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(Offset(left - 5, scanLineY), 3, dotPaint);
    canvas.drawCircle(Offset(left + frameSize + 5, scanLineY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
