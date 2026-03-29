import 'dart:math';
import 'package:flutter/material.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [NoDataFoundScreen(), NoInternetScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBtn(
                  icon: Icons.search_off_rounded,
                  label: 'No Data',
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavBtn(
                  icon: Icons.wifi_off_rounded,
                  label: 'No Internet',
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF6C63FF) : Colors.grey,
              size: 20,
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NO DATA FOUND SCREEN
// ─────────────────────────────────────────────

class NoDataFoundScreen extends StatefulWidget {
  const NoDataFoundScreen({super.key});

  @override
  State<NoDataFoundScreen> createState() => _NoDataFoundScreenState();
}

class _NoDataFoundScreenState extends State<NoDataFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _fadeController;

  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _particleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _floatAnim = Tween<double>(begin: 0, end: -18).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _particleAnim = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B6B).withOpacity(0.06),
                ),
              ),
            ),

            // Floating particles
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particleAnim.value,
                    color: const Color(0xFF6C63FF),
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated illustration
                      AnimatedBuilder(
                        animation: Listenable.merge([_floatAnim, _pulseAnim]),
                        builder: (context, _) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: Transform.scale(
                              scale: _pulseAnim.value,
                              child: _NoDataIllustration(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Title
                      const Text(
                        'Nothing Here Yet',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1040),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Looks like this space is empty.\nTry a different search or come back later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF1A1040).withOpacity(0.5),
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // CTA Button
                      _PulseButton(
                        label: 'Explore Something',
                        icon: Icons.explore_rounded,
                        color: const Color(0xFF6C63FF),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDataIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withOpacity(0.06),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 52,
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                  ),
                  Positioned(
                    bottom: 22,
                    right: 22,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF6B6B),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NO INTERNET SCREEN
// ─────────────────────────────────────────────

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _signalController;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _dotController;

  late Animation<double> _waveAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _dotAnim;

  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _signalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _waveAnim = CurvedAnimation(parent: _waveController, curve: Curves.linear);

    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _dotAnim = CurvedAnimation(parent: _dotController, curve: Curves.linear);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _signalController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _retry() async {
    setState(() => _isRetrying = true);
    _shakeController.reset();
    await Future.delayed(const Duration(milliseconds: 1800));
    _shakeController.forward();
    setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Animated wave background
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(progress: _waveAnim.value),
                child: const SizedBox.expand(),
              ),
            ),

            // Star particles
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (context, _) => CustomPaint(
                painter: _StarPainter(progress: _waveAnim.value),
                child: const SizedBox.expand(),
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Wifi illustration with shake
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) {
                          final shake = sin(_shakeAnim.value * pi * 6) * 12;
                          return Transform.translate(
                            offset: Offset(shake, 0),
                            child: child,
                          );
                        },
                        child: _WifiIllustration(
                          signalController: _signalController,
                        ),
                      ),

                      const SizedBox(height: 48),

                      const Text(
                        'No Connection',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Your device is offline. Check your Wi-Fi or mobile data and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.45),
                            height: 1.65,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Status dots
                      _StatusDots(dotAnim: _dotAnim),

                      const SizedBox(height: 40),

                      // Retry button
                      _isRetrying
                          ? _RetryingIndicator()
                          : _PulseButton(
                              label: 'Try Again',
                              icon: Icons.refresh_rounded,
                              color: const Color(0xFF00D4FF),
                              onTap: _retry,
                              dark: true,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WifiIllustration extends StatelessWidget {
  final AnimationController signalController;

  const _WifiIllustration({required this.signalController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          AnimatedBuilder(
            animation: signalController,
            builder: (context, _) {
              return Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF00D4FF,
                  ).withOpacity(0.04 + signalController.value * 0.04),
                ),
              );
            },
          ),
          // Middle ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1830),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: signalController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WifiIconPainter(
                    progress: signalController.value,
                    color: const Color(0xFF00D4FF),
                  ),
                );
              },
            ),
          ),
          // Slash indicator
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4F6A),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4F6A).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiIconPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WifiIconPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;
    final paint = Paint()
      ..color = color.withOpacity(0.3 + progress * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw 3 wifi arcs (bottom to top)
    for (int i = 0; i < 3; i++) {
      final radius = 12.0 + i * 12;
      final opacity = i == 2 ? 0.2 : (i == 1 ? 0.5 : 1.0);
      paint.color = color.withOpacity(opacity * (0.3 + progress * 0.7));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        pi + 0.4,
        pi - 0.8,
        false,
        paint,
      );
    }

    // Dot at bottom
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()
        ..color = color.withOpacity(0.3 + progress * 0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_WifiIconPainter old) => old.progress != progress;
}

class _StatusDots extends StatelessWidget {
  final Animation<double> dotAnim;

  const _StatusDots({required this.dotAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dotAnim,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final val = ((dotAnim.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + sin(val * pi) * 0.4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF00D4FF,
                    ).withOpacity(0.4 + sin(val * pi) * 0.6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _RetryingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF00D4FF).withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────

class _PulseButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool dark;

  const _PulseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.dark = false,
  });

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final _rand = Random(42);

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final x = _rand.nextDouble() * size.width;
      final startY = _rand.nextDouble() * size.height;
      final speed = 0.3 + _rand.nextDouble() * 0.7;
      final y = (startY - progress * size.height * speed) % size.height;
      final radius = 1.5 + _rand.nextDouble() * 2.5;
      final opacity = 0.1 + _rand.nextDouble() * 0.25;
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _WavePainter extends CustomPainter {
  final double progress;

  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00D4FF).withOpacity(0.04);

    for (int w = 0; w < 3; w++) {
      final path = Path();
      final waveHeight = 40.0 + w * 20;
      final offset = (progress + w * 0.33) % 1.0;
      path.moveTo(-size.width, size.height);
      for (double x = -size.width; x <= size.width * 2; x += 10) {
        final y =
            size.height * 0.82 +
            sin((x / size.width * 2 * pi) + offset * 2 * pi) * waveHeight;
        path.lineTo(x, y);
      }
      path.lineTo(size.width * 2, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

class _StarPainter extends CustomPainter {
  final double progress;
  final _rand = Random(7);

  _StarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final x = _rand.nextDouble() * size.width;
      final y = _rand.nextDouble() * size.height * 0.75;
      final twinkle = (sin((progress * 2 * pi) + i) + 1) / 2;
      final radius = 0.8 + _rand.nextDouble() * 1.5;
      paint.color = Colors.white.withOpacity(0.05 + twinkle * 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.progress != progress;
}
