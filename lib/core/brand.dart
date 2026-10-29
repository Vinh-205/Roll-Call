import 'package:flutter/material.dart';

import 'ui.dart';

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: teal,
      borderRadius: BorderRadius.circular(size * .29),
      boxShadow: [
        BoxShadow(
          color: teal.withValues(alpha: .24),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 100, s.height / 100);
    final p = Paint()
      ..color = const Color(0xffb8e870)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(
      Path()
        ..moveTo(37, 22)
        ..lineTo(26, 22)
        ..quadraticBezierTo(22, 22, 22, 26)
        ..lineTo(22, 37)
        ..moveTo(63, 22)
        ..lineTo(74, 22)
        ..quadraticBezierTo(78, 22, 78, 26)
        ..lineTo(78, 37)
        ..moveTo(22, 63)
        ..lineTo(22, 74)
        ..quadraticBezierTo(22, 78, 26, 78)
        ..lineTo(37, 78)
        ..moveTo(78, 63)
        ..lineTo(78, 74)
        ..quadraticBezierTo(78, 78, 74, 78)
        ..lineTo(63, 78)
        ..moveTo(35, 51)
        ..lineTo(46, 62)
        ..lineTo(66, 40),
      p,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RollHero extends StatelessWidget {
  final String title, subtitle, label;
  final Widget? action;
  const RollHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.label = 'MỖI BUỔI HỌC ĐỀU CÓ Ý NGHĨA',
    this.action,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xff27203f), Color(0xff171b31)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -40,
          top: -35,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xff8e75ed).withValues(alpha: .22),
                width: 30,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xffb8e870),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xffc7b9fc),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.18,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xffb9bfd4),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ],
    ),
  );
}
