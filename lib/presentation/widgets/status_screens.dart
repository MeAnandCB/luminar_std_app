import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────
//  EMPTY STATE SCREEN
// ─────────────────────────────────────────────

class EmptyStateScreen extends StatefulWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final IconData? icon;
  final VoidCallback? onTap;

  const EmptyStateScreen({
    super.key,
    this.title = 'Nothing Here Yet',
    this.message = 'Looks like this space is empty.\nTry a different search or come back later.',
    this.buttonLabel = 'Explore Something',
    this.icon,
    this.onTap,
  });

  @override
  State<EmptyStateScreen> createState() => _EmptyStateScreenState();
}

class _EmptyStateScreenState extends State<EmptyStateScreen>
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
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
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
                  color: primaryColor.withOpacity(0.08),
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
                    color: primaryColor,
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
                              child: _NoDataIllustration(
                                icon: widget.icon,
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),

                      if (widget.onTap != null) ...[
                        const SizedBox(height: 40),
                        _PulseButton(
                          label: widget.buttonLabel,
                          icon: Icons.explore_rounded,
                          color: primaryColor,
                          onTap: widget.onTap!,
                        ),
                      ],
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
  final IconData? icon;
  final Color color;

  const _NoDataIllustration({this.icon, required this.color});

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
                color: color.withOpacity(0.15),
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
              color: color.withOpacity(0.06),
              border: Border.all(
                color: color.withOpacity(0.2),
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
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
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
                    icon ?? Icons.folder_open_rounded,
                    size: 52,
                    color: color.withOpacity(0.15),
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
//  NO CONNECTION SCREEN
// ─────────────────────────────────────────────

class NoConnectionScreen extends StatefulWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onRetry;

  const NoConnectionScreen({
    super.key,
    this.title = 'No Connection',
    this.message = 'Your device is offline. Check your Wi-Fi or mobile data and try again.',
    this.buttonLabel = 'Try Again',
    this.onRetry,
  });

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen>
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
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    _shakeController.reset();
    
    if (widget.onRetry != null) {
      widget.onRetry!();
    }
    
    await Future.delayed(const Duration(milliseconds: 1800));
    _shakeController.forward();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final backgroundColor = isDark ? const Color(0xFF0F0E1A) : AppColors.scaffoldBackground;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final infoColor = const Color(0xFF00D4FF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated wave background
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(progress: _waveAnim.value, color: infoColor),
                child: const SizedBox.expand(),
              ),
            ),

            // Star particles (only in dark mode)
            if (isDark)
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
                          color: infoColor,
                        ),
                      ),

                      const SizedBox(height: 48),

                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor.withOpacity(0.45),
                            height: 1.65,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Status dots
                      _StatusDots(dotAnim: _dotAnim, color: infoColor),

                      const SizedBox(height: 40),

                      // Retry button
                      _isRetrying
                          ? _RetryingIndicator(color: infoColor, textColor: textColor)
                          : _PulseButton(
                              label: widget.buttonLabel,
                              icon: Icons.refresh_rounded,
                              color: infoColor,
                              onTap: _retry,
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
  final Color color;

  const _WifiIllustration({required this.signalController, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
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
                  color: color.withOpacity(0.04 + signalController.value * 0.04),
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
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
              color: isDark ? const Color(0xFF1A1830) : AppColors.cardBackground,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
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
                    color: color,
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
  final Color color;

  const _StatusDots({required this.dotAnim, required this.color});

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
                    color: color.withOpacity(0.4 + sin(val * pi) * 0.6),
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
  final Color color;
  final Color textColor;

  const _RetryingIndicator({required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
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
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Connecting...',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
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

  const _PulseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

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
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
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
//  PAINTERS
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
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.04);

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
