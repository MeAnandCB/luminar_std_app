import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../api/laptop_api.dart';
import '../widgets/sheet_widgets.dart';

/// Dedicated final step of the Return flow, reached only once every item on
/// the checklist is ticked. Scanning here *is* the confirmation — there's no
/// extra dialog on top of it. A wrong/unreadable QR just leaves the camera
/// running so the user can rescan; nothing scanned on the checklist is lost
/// by staying here or backing out.
class RackScanScreen extends StatefulWidget {
  const RackScanScreen({
    super.key,
    required this.api,
    required this.identifiers,
    this.earlyReturnFeedback,
  });

  final LaptopApi api;
  final List<String> identifiers;
  final String? earlyReturnFeedback;

  @override
  State<RackScanScreen> createState() => _RackScanScreenState();
}

class _RackScanScreenState extends State<RackScanScreen> {
  late final MobileScannerController _camera;
  bool _inFlight = false;
  bool _torchOn = false;
  String? _error;
  ReturnActionResult? _successResult;

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
    if (_inFlight || _successResult != null) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _submit(raw);
  }

  Future<void> _submit(String rackCode) async {
    setState(() {
      _inFlight = true;
      _error = null;
    });
    try {
      final res = await widget.api.returnItems(
        identifiers: widget.identifiers,
        rackCode: rackCode,
        earlyReturnFeedback: widget.earlyReturnFeedback,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _successResult = res);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pop(
          SheetOutcome(message: 'Returned', counts: res.counts),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // Wrong QR type / server rejection — stay on this screen, let them
      // rescan. Nothing on the checklist behind this screen is affected.
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _inFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_successResult != null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SuccessBurst(title: 'Returned', color: Color(0xFF10B981)),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    const box = 220.0;
    final top = (size.height - box) / 2 - 40;
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
                    icon: Icons.arrow_back_ios_new_rounded,
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
            top: top - 56,
            left: 24,
            right: 24,
            child: const Center(
              child: Text(
                'Scan the Rack QR to confirm return',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_inFlight)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
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
