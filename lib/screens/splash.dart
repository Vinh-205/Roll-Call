import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/ui.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  Timer? deadline, finishDelay;
  bool completed = false;
  void finish() {
    if (!mounted || completed) return;
    completed = true;
    deadline?.cancel();
    finishDelay?.cancel();
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    deadline = Timer(const Duration(seconds: 6), finish);
  }

  @override
  void dispose() {
    deadline?.cancel();
    finishDelay?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: dark ? darkBg : paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 330,
                      height: (constraints.maxHeight * .43).clamp(150, 320),
                      child: Lottie.asset(
                        'assets/lottie/smartphones-applications.json',
                        controller: controller,
                        repeat: false,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          if (completed) return;
                          if (reduced) {
                            controller.value = 1;
                            finishDelay ??= Timer(
                              const Duration(milliseconds: 600),
                              finish,
                            );
                          } else {
                            controller.duration = composition.duration;
                            controller.forward().then((_) {
                              if (mounted && !completed) {
                                finishDelay = Timer(
                                  const Duration(milliseconds: 180),
                                  finish,
                                );
                              }
                            });
                          }
                        },
                        errorBuilder: (_, _, _) {
                          finishDelay ??= Timer(
                            const Duration(milliseconds: 900),
                            finish,
                          );
                          return Image.asset(
                            'assets/branding/app-icon.png',
                            width: 100,
                            height: 100,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Roll call',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.6,
                        color: dark ? Colors.white : ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Có mặt. Có kết nối.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'TRƯƠNG TUẤN VĨNH · 2380602577',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark
                            ? const Color(0xffa1aac3)
                            : const Color(0xff647087),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
