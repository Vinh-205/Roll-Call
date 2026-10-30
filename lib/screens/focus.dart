import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/ui.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  StreamSubscription<UserAccelerometerEvent>? subscription;
  Timer? timer;
  double motion = 0;
  List<double> samples = [];
  int seconds = 25 * 60, movements = 0;
  bool running = false, enabled = false;
  String? error;
  DateTime lastMovement = DateTime(2000);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      subscription?.cancel();
      timer?.cancel();
      if (mounted) {
        setState(() {
          enabled = false;
          running = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void sensor() {
    if (enabled) {
      subscription?.cancel();
      setState(() => enabled = false);
      return;
    }
    setState(() {
      enabled = true;
      error = null;
    });
    subscription =
        userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen(
              (e) {
                if (!mounted) return;
                final value = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
                setState(() {
                  motion = value;
                  samples = [
                    ...samples,
                    value,
                  ].skip(max(0, samples.length - 45)).toList();
                  if (value > 1.8 &&
                      DateTime.now().difference(lastMovement) >
                          const Duration(seconds: 2)) {
                    movements++;
                    lastMovement = DateTime.now();
                  }
                });
              },
              onError: (_) {
                if (mounted) {
                  setState(() {
                    error = 'Thiết bị không cung cấp cảm biến chuyển động.';
                    enabled = false;
                  });
                }
              },
            );
  }

  void toggle() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds <= 1) {
        timer?.cancel();
        setState(() {
          seconds = 0;
          running = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Đến lúc nghỉ vận động'),
            content: const Text(
              'Hãy đứng dậy, thả lỏng vai và vận động nhẹ. Nhịp học không dùng chuyển động để chấm điểm chuyên cần.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Tag('HỌC TẬP BỀN VỮNG'),
      const SizedBox(height: 16),
      const Text(
        'Giữ nhịp học.\nĐừng quên nhịp sống.',
        style: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Tập trung 25 phút, nghỉ vận động ngắn. Cảm biến chỉ hoạt động khi bạn bật và ở màn hình này.',
        style: TextStyle(color: muted(context), height: 1.6),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            const Text(
              'PHIÊN TẬP TRUNG',
              style: TextStyle(color: gold, letterSpacing: 2, fontSize: 12),
            ),
            const SizedBox(height: 22),
            Text(
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: ink,
                  ),
                  onPressed: seconds == 0 ? null : toggle,
                  icon: RcIcon(running ? RcIcons.pause : RcIcons.play_arrow),
                  label: Text(running ? 'Tạm dừng' : 'Bắt đầu'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    timer?.cancel();
                    setState(() {
                      seconds = 25 * 60;
                      running = false;
                    });
                  },
                  icon: const RcIcon(RcIcons.restart_alt, color: Colors.white),
                  tooltip: 'Đặt lại',
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const RcIcon(RcIcons.sensors, color: teal),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chuyển động trực tiếp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Switch(value: enabled, onChanged: (_) => sensor()),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${motion.toStringAsFixed(2)} m/s²',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Gia tốc không gồm trọng lực',
              style: TextStyle(color: muted(context), fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: CustomPaint(
                painter: MotionChart(
                  samples,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$movements đợt chuyển động được phát hiện',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      Panel(
        child: Text(
          'Không theo dõi nền, không gửi cảm biến lên máy chủ. Kết quả này không chứng minh bạn đang có mặt tại lớp và không thay thế QR/vị trí.',
          style: TextStyle(color: muted(context), height: 1.6),
        ),
      ),
    ],
  );
}

class MotionChart extends CustomPainter {
  final List<double> samples;
  final Color lineColor;
  MotionChart(this.samples, this.lineColor);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xffe5eaf0)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        grid,
      );
    }
    if (samples.length < 2) return;
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = size.width * i / (samples.length - 1),
          y = size.height * (1 - min(samples[i] / 10, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant MotionChart old) => true;
}
