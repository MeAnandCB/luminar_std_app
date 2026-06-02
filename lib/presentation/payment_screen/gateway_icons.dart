import 'package:flutter/material.dart';

/// Razorpay logo — dark-navy parallelogram + sky-blue diagonal slash
class RazorpayLogoIcon extends StatelessWidget {
  const RazorpayLogoIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RazorpayPainter()),
    );
  }
}

class _RazorpayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Dark navy body — wide base, tapers to upper-right point
    final navy = Paint()..color = const Color(0xFF0D2144);
    final navyPath = Path()
      ..moveTo(w * 0.05, h * 0.92)   // bottom-left
      ..lineTo(w * 0.42, h * 0.06)   // top apex
      ..lineTo(w * 0.62, h * 0.06)   // top-right corner
      ..lineTo(w * 0.52, h * 0.44)   // notch
      ..lineTo(w * 0.70, h * 0.44)   // right shoulder
      ..lineTo(w * 0.35, h * 0.92)   // bottom-right
      ..close();
    canvas.drawPath(navyPath, navy);

    // Light blue slash — diagonal accent
    final blue = Paint()..color = const Color(0xFF4DAAEC);
    final bluePath = Path()
      ..moveTo(w * 0.50, h * 0.44)   // starts at the notch
      ..lineTo(w * 0.62, h * 0.06)   // up to top
      ..lineTo(w * 0.98, h * 0.06)   // top-right
      ..lineTo(w * 0.68, h * 0.92)   // bottom-right
      ..lineTo(w * 0.36, h * 0.92)   // bottom shoulder (joins navy)
      ..lineTo(w * 0.68, h * 0.44)   // back to shoulder
      ..close();
    canvas.drawPath(bluePath, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// ICICI Bank logo — orange tilted oval with dark-red oval and white "i"
class IciciLogoIcon extends StatelessWidget {
  const IciciLogoIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IciciPainter()),
    );
  }
}

class _IciciPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    const angle = -0.42; // tilt ~24°

    // ── Orange outer oval ────────────────────────────────────────────────────
    final orangePaint = Paint()..color = const Color(0xFFFF8C00);
    canvas.save();
    canvas.translate(w * 0.50, h * 0.58);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.60,
        height: h * 0.96,
      ),
      orangePaint,
    );
    canvas.restore();

    // ── Dark red inner oval (slightly smaller, offset up-left) ───────────────
    final redPaint = Paint()..color = const Color(0xFF9B1A1A);
    canvas.save();
    canvas.translate(w * 0.44, h * 0.46);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.52,
        height: h * 0.82,
      ),
      redPaint,
    );
    canvas.restore();

    // ── White "i" body ───────────────────────────────────────────────────────
    final whitePaint = Paint()..color = Colors.white;

    // Dot
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.26),
      w * 0.075,
      whitePaint,
    );

    // Stem — italic-looking rounded rectangle
    final stemRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.40, w * 0.12, h * 0.36),
      Radius.circular(w * 0.06),
    );
    // Shear the stem slightly to mimic italics
    final stemPath = Path()..addRRect(stemRRect);
    canvas.save();
    final matrix = Matrix4.identity()
      ..setEntry(0, 1, -0.18); // slight italic shear
    canvas.transform(matrix.storage);
    canvas.drawPath(stemPath, whitePaint);
    canvas.restore();

    // Bottom serif / base curve
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;

    final basePath = Path()
      ..moveTo(w * 0.28, h * 0.78)
      ..quadraticBezierTo(w * 0.42, h * 0.88, w * 0.60, h * 0.80);
    canvas.drawPath(basePath, basePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
