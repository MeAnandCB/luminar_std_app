import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A single-shot QR scanner pushed as a full-screen route. Used inside the
/// Checkout/Return sheets to scan an accessory or item without leaving the
/// sheet's flow — returns the decoded string, or null if the user backs out.
class ScanCamera {
  static Future<String?> scanOnce(
    BuildContext context, {
    String hint = 'Scan a QR code',
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ScanCameraScreen(hint: hint),
      ),
    );
  }
}

class _ScanCameraScreen extends StatefulWidget {
  const _ScanCameraScreen({required this.hint});
  final String hint;

  @override
  State<_ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<_ScanCameraScreen> {
  late final MobileScannerController _camera;
  bool _handled = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _camera = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const box = 220.0;
    final top = (size.height - box) / 2 - 30;
    final left = (size.width - box) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _camera, onDetect: _onDetect),
          Positioned(
            top: top,
            left: left,
            child: Container(
              width: box,
              height: box,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _RoundIconButton(
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
          Positioned(
            top: top + box + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.hint,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
