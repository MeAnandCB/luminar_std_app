import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_images.dart';
import 'package:luminar_std/presentation/bottom_nav_screen/bottom_nav_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Timer to move to the next screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavScreen()),
      );
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Matching the purple gradient from your button and bottom bar
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your "L" Logo
              Container(
                height: 120,
                width: 120,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  AppImages.lumLogo, // Same asset used in BottomNav
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              // App Name using Roboto font
              Text(
                'LUMINAR',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
