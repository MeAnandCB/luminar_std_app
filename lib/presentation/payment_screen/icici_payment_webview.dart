import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:provider/provider.dart';

class IciciPaymentWebView extends StatefulWidget {
  const IciciPaymentWebView({
    super.key,
    required this.paymentUrl,
    this.amount = 0,
    this.discountApplied = false,
    this.discountAmount = 0,
  });

  final String paymentUrl;
  final double amount;
  final bool discountApplied;
  final double discountAmount;

  @override
  State<IciciPaymentWebView> createState() => _IciciPaymentWebViewState();
}

class _IciciPaymentWebViewState extends State<IciciPaymentWebView> {
  InAppWebViewController? _webCtrl;
  int _progress = 0;
  bool _paymentDetected = false;
  bool _paymentSucceeded = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  // URL patterns that signal the payment flow ended
  static const _successPatterns = [
    'success',
    'complete',
    'payment_success',
    'payment-success',
    'paymentsuccess',
    'return',
    'callback',
    'pg/success',
    'pg/return',
  ];

  static const _failurePatterns = [
    'failure',
    'failed',
    'cancel',
    'payment_failed',
    'payment-failed',
    'error',
  ];

  bool _isSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return _successPatterns.any((p) => lower.contains(p));
  }

  bool _isFailureUrl(String url) {
    final lower = url.toLowerCase();
    return _failurePatterns.any((p) => lower.contains(p));
  }


  void _onPaymentComplete({bool success = true}) {
    if (_paymentDetected) return;
    setState(() {
      _paymentDetected = true;
      _paymentSucceeded = success;
    });

    // Only auto-redirect on success. A failed/cancelled payment needs the
    // user to consciously see it failed and choose to retry or leave —
    // silently treating it the same as success left them thinking they'd
    // paid when they hadn't.
    if (!success) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _navigateHome();
      }
    });
  }

  // ── Retry: reload the original payment URL and go back to the webview ─────
  void _retryPayment() {
    setState(() {
      _paymentDetected = false;
      _paymentSucceeded = false;
      _progress = 0;
    });
    _webCtrl?.loadUrl(
      urlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
    );
  }

  void _navigateHome() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    // Refresh dashboard so payment status updates
    Provider.of<DashboardController>(context, listen: false)
        .getDashboardData(context: context, forceRefresh: true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Back button: confirm exit ────────────────────────────────────────────

  void _handleBackPress() async {
    if (_paymentDetected) return; // block while processing

    final canGoBack = await _webCtrl?.canGoBack() ?? false;
    if (canGoBack) {
      _webCtrl?.goBack();
      return;
    }

    if (!mounted) return;
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Leave Payment?'),
        content: const Text(
          'Your payment may not be completed yet. Are you sure you want to go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (exit == true) _navigateHome();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _paymentDetected ? null : _buildAppBar(),
        body: Stack(
          children: [
            // ── WebView ───────────────────────────────────────────────────
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.paymentUrl),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                transparentBackground: false,
              ),
              onWebViewCreated: (ctrl) => _webCtrl = ctrl,
              onProgressChanged: (_, progress) =>
                  setState(() => _progress = progress),
              onLoadStop: (_, url) {
                final urlStr = url?.toString() ?? '';
                if (_isSuccessUrl(urlStr)) {
                  _onPaymentComplete(success: true);
                } else if (_isFailureUrl(urlStr)) {
                  _onPaymentComplete(success: false);
                }
              },
              shouldOverrideUrlLoading: (ctrl, action) async {
                final urlStr =
                    action.request.url?.toString().toLowerCase() ?? '';
                if (_isSuccessUrl(urlStr) || _isFailureUrl(urlStr)) {
                  _onPaymentComplete(success: _isSuccessUrl(urlStr));
                  return NavigationActionPolicy.ALLOW;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),

            // ── Progress bar ──────────────────────────────────────────────
            if (_progress < 100 && !_paymentDetected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              ),

            // ── Payment processing overlay ────────────────────────────────
            if (_paymentDetected) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF9B1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () async {
          final canGoBack = await _webCtrl?.canGoBack() ?? false;
          if (canGoBack) {
            _webCtrl?.goBack();
          } else {
            _handleBackPress();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomPaint(painter: _IciciMiniPainter()),
          ),
          const SizedBox(width: 10),
          const Text(
            'ICICI Bank Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.white24, height: 1),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    if (!_paymentSucceeded) return _buildFailureOverlay();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ICICI logo area
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3E0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE87722).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(painter: _IciciMiniPainter()),
          ),
          const SizedBox(height: 28),

          // Countdown ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _countdown / 5,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF9B1A1A),
                  ),
                ),
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9B1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'We are confirming your payment.\nDo not close or refresh the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Failed / cancelled payment: clear messaging + explicit next step ──────
  // Deliberately does NOT auto-redirect — a user whose payment failed needs
  // to consciously see that before deciding what to do next, not get carried
  // along by the same countdown used for a successful payment.
  Widget _buildFailureOverlay() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFEBEE),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFD32F2F),
              size: 44,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Payment Not Completed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your payment was not completed — it may have been declined or '
              'cancelled. No amount has been confirmed as paid.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _navigateHome,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _retryPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Processing step row ──────────────────────────────────────────────────────

// ─── Mini ICICI painter (for AppBar + overlay icon) ──────────────────────────

class _IciciMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    const angle = -0.42;

    final orange = Paint()..color = const Color(0xFFFF8C00);
    canvas.save();
    canvas.translate(w * 0.50, h * 0.58);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.60, height: h * 0.96),
      orange,
    );
    canvas.restore();

    final red = Paint()..color = const Color(0xFF9B1A1A);
    canvas.save();
    canvas.translate(w * 0.44, h * 0.46);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.52, height: h * 0.82),
      red,
    );
    canvas.restore();

    final white = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.43, h * 0.26), w * 0.075, white);

    final stemRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.40, w * 0.12, h * 0.36),
      Radius.circular(w * 0.06),
    );
    final stemPath = Path()..addRRect(stemRRect);
    canvas.save();
    final matrix = Matrix4.identity()..setEntry(0, 1, -0.18);
    canvas.transform(matrix.storage);
    canvas.drawPath(stemPath, white);
    canvas.restore();

    final base = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.78)
        ..quadraticBezierTo(w * 0.42, h * 0.88, w * 0.60, h * 0.80),
      base,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
