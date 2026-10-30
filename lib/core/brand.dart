import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'assets/branding/app-icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    ),
  );
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
        colors: [Color(0xff23212c), Color(0xff1b1922)],
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
                color: const Color(0xffb2d5e5).withValues(alpha: .22),
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
                    color: Color(0xffb2d5e5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xffb2d5e5),
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
                color: Color(0xffb2d5e5),
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
