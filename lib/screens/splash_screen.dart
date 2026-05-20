import 'dart:async';

import 'package:fasum_filbert/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_city,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Fasum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Aplikasi pelaporan fasilitas umum untuk jalan, lampu, trotoar, dan fasilitas sekitar kota.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
