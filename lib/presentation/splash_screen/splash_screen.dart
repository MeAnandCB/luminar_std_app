import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:luminar_std/core/services/app_update_service.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';
import 'package:luminar_std/presentation/auth_screens/terms_screen/terms_agreement_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;

  // Logo
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Ring burst
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;

  // Brand text
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  // Tagline pill
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Logo: spring in
    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    // Ring 1 (fast inner ring)
    _ring1Scale = Tween<double>(
      begin: 0.9,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ring1Opacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    // Ring 2 (slower outer ring, delayed)
    _ring2Scale = Tween<double>(begin: 0.9, end: 2.8).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Title
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainCtrl,
            curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
          ),
        );

    // Tagline pill
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainCtrl,
            curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
          ),
        );

    _mainCtrl.forward();

    // Trigger ring burst shortly after logo appears
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) _ringCtrl.forward();
    });

    // Navigate to login (or terms agreement) with fade transition
    Timer(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      if (AppUtils.isDeepLinking) {
        debugPrint(
          '[SplashScreen] Deep-link in progress — skipping auto-navigation',
        );
        AppUtils.appReady = true;
        return;
      }
      AppUtils.appReady = true;

      // Wait for the forced-update check (shared with the app-wide update
      // dialog) before leaving the splash screen, so we never navigate to
      // Login/Terms underneath a pending "Update Available" dialog.
      String? newVersion;
      try {
        newVersion = await AppUpdateService.checkForUpdate()
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        newVersion = null;
      }
      if (!mounted) return;
      if (newVersion != null) {
        // Update required — stay on splash; the dialog appears on top of it.
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final hasAcceptedTerms =
          prefs.getBool(TermsAgreementScreen.prefsKey) ?? false;
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => hasAcceptedTerms
              ? const LoginScreen()
              : const TermsAgreementScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _ringCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A0E8F), Color(0xFF5A3ED9), Color(0xFF9B8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Background blobs ────────────────────────────
            Positioned(
              top: -size.height * 0.18,
              right: -size.width * 0.28,
              child: Container(
                width: size.width * 0.82,
                height: size.width * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.12,
              left: -size.width * 0.22,
              child: Container(
                width: size.width * 0.70,
                height: size.width * 0.70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.38,
              right: -size.width * 0.08,
              child: Container(
                width: size.width * 0.28,
                height: size.width * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ── Floating particles ──────────────────────────
            ...List.generate(22, (i) {
              final rng = math.Random(i * 13);
              final baseX = rng.nextDouble() * size.width;
              final baseY = rng.nextDouble() * size.height;
              final dotSize = 1.5 + rng.nextDouble() * 3.5;
              final speed = 0.25 + rng.nextDouble() * 0.75;
              final drift = 15.0 + rng.nextDouble() * 25;
              return AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) {
                  final t = (_particleCtrl.value * speed) % 1.0;
                  final fade = (1.0 - t).clamp(0.0, 1.0);
                  return Positioned(
                    left: baseX + math.sin(t * 2 * math.pi + i) * drift,
                    top: baseY - (t * 140),
                    child: Opacity(
                      opacity: fade * 0.5,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // ── Main content ────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + rings
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring burst
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Opacity(
                            opacity: _ring2Opacity.value,
                            child: Transform.scale(
                              scale: _ring2Scale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Inner ring burst
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Opacity(
                            opacity: _ring1Opacity.value,
                            child: Transform.scale(
                              scale: _ring1Scale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Glow halo behind logo
                        AnimatedBuilder(
                          animation: _mainCtrl,
                          builder: (_, __) => Opacity(
                            opacity: _logoOpacity.value * 0.25,
                            child: Container(
                              width: 145,
                              height: 145,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Logo circle
                        AnimatedBuilder(
                          animation: _mainCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6C5CE7,
                                      ).withValues(alpha: 0.45),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/lum_logo.png',
                                    width: 62,
                                    height: 62,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Brand name + subtitle
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'LUMINAR TECHNOLAB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,

                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Kerala's No.1 Software Training Institute",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tagline pill
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Empowering Futures Through Technology',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Glowing progress bar ────────────────────────
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 3200),
                  curve: Curves.easeInOut,
                  builder: (_, value, __) {
                    return Column(
                      children: [
                        Container(
                          width: 160,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFD0CAFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Version ─────────────────────────────────────
            Positioned(
              bottom: 24,
              left: 24,
              child: Text(
                'Developed by Anvitha Infotech',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.38),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: Text(
                'V2 : 2.1.5',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.38),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
