import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/ui.dart';
import '../core/brand.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 2450), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff101323),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!MediaQuery.disableAnimationsOf(context))
                    Lottie.asset(
                      'assets/lottie/splash.json',
                      repeat: false,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  const BrandMark(size: 94),
                ],
              ),
            ),
            const Text(
              'Roll call',
              style: TextStyle(
                fontSize: 39,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Có mặt. Có kết nối.',
              style: TextStyle(color: Color(0xffb8a6ff), fontSize: 16),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 70,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xffb8e870),
                backgroundColor: darkCard,
              ),
            ),
            const SizedBox(height: 52),
            const Text(
              'TRƯƠNG TUẤN VĨNH · 2380602577',
              style: TextStyle(
                color: Color(0xffa1aac3),
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
