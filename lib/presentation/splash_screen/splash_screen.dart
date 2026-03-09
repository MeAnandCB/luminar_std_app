import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:luminar_std/core/theme/app_colors.dart'; // Updated import
import 'package:luminar_std/core/theme/app_text_styles.dart'; // Updated import
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Scale animation for logo
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Rotation animation
    _rotationAnimation = Tween<double>(begin: -0.5, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    // Slide animation for tagline
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

    // Pulse animation for background
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Navigate to next screen after 3 seconds
    Timer(const Duration(milliseconds: 3200), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.splashGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Animated background shapes
            ...List.generate(8, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Positioned(
                    left: size.width * (index * 0.15) - 50,
                    top: size.height * (index * 0.1) - 50,
                    child: Transform.rotate(
                      angle:
                          _controller.value *
                          2 *
                          math.pi *
                          (index % 2 == 0 ? 1 : -1),
                      child: Container(
                        width: 100 + (index * 20),
                        height: 100 + (index * 20),
                        decoration: BoxDecoration(
                          color: AppColors.shapeBackground(
                            0.05 - (index * 0.005),
                          ),
                          shape: index % 2 == 0
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          borderRadius: index % 2 == 0
                              ? null
                              : BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Floating particles
            ...List.generate(30, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final random = math.Random(index);
                  final startX = random.nextDouble() * size.width;
                  final startY = random.nextDouble() * size.height;
                  final endX = startX + (random.nextDouble() - 0.5) * 100;
                  final endY = startY - 200;

                  return Positioned(
                    left: startX + (_controller.value * (endX - startX)),
                    top: startY + (_controller.value * (endY - startY)),
                    child: Opacity(
                      opacity: (1 - _controller.value).clamp(0, 1) * 0.5,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.particle,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * math.pi,
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderLighter,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/lum_logo.png',
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Animated Tagline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.whiteWithOpacity20,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Text(
                              'Empowering Futures Through Technology',
                              style: AppTextStyles.tagline,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Animated dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacity(
                                        0.3 +
                                            (math.sin(
                                                      _controller.value *
                                                              2 *
                                                              math.pi +
                                                          index,
                                                    ) *
                                                    0.3)
                                                .abs(),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 3000),
                  builder: (context, value, child) {
                    return Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.loadingBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.loadingProgress,
                                    AppColors.loadingProgress,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.loadingShadow,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Version text
            Positioned(
              bottom: 20,
              right: 20,
              child: Opacity(
                opacity: 0.5,
                child: Text('v1.0.0', style: AppTextStyles.version),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
