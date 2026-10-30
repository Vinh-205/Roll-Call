import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Keeps one live navigator while the previous frame peels away from the tap.
/// Forms, scroll positions and authenticated routes are never recreated.
class ThemeReveal extends StatefulWidget {
  final Widget child;
  const ThemeReveal({super.key, required this.child});

  static Future<void> change(BuildContext context, VoidCallback change) async {
    final state = context.getInheritedWidgetOfExactType<_RevealScope>()?.state;
    if (state == null || MediaQuery.disableAnimationsOf(context)) {
      change();
      return;
    }
    final box = context.findRenderObject();
    final origin = box is RenderBox
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset.zero;
    await state.reveal(origin, change);
  }

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final boundaryKey = GlobalKey();
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  ui.Image? previousFrame;
  Offset origin = Offset.zero;
  bool busy = false;

  Future<void> reveal(Offset globalOrigin, VoidCallback change) async {
    if (busy) return;
    setState(() => busy = true);
    bool changed = false;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        change();
        return;
      }
      // Retain the GPU scene without waiting for a CPU image readback.
      final snapshot = boundary.toImageSync(
        pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 1.25),
      );
      if (!mounted) {
        snapshot.dispose();
        return;
      }
      origin = boundary.globalToLocal(globalOrigin);
      controller.value = 0;
      setState(() => previousFrame = snapshot);
      change();
      changed = true;
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await controller.forward(from: 0).orCancel;
    } catch (_) {
      // A native platform view may not support capture. Theme still changes.
      if (!changed && mounted) change();
    } finally {
      if (mounted) {
        final old = previousFrame;
        setState(() {
          previousFrame = null;
          busy = false;
        });
        if (old != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    previousFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RevealScope(
    state: this,
    child: Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: boundaryKey, child: widget.child),
        if (previousFrame != null)
          Positioned.fill(
            child: AbsorbPointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) => CustomPaint(
                    key: const ValueKey('theme-reveal-overlay'),
                    isComplex: true,
                    willChange: true,
                    painter: _PreviousThemePainter(
                      previousFrame!,
                      origin,
                      Curves.easeOutCubic.transform(controller.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _RevealScope extends InheritedWidget {
  final _ThemeRevealState state;
  const _RevealScope({required this.state, required super.child});
  @override
  bool updateShouldNotify(_RevealScope oldWidget) => false;
}

class _PreviousThemePainter extends CustomPainter {
  final ui.Image image;
  final Offset origin;
  final double progress;
  const _PreviousThemePainter(this.image, this.origin, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - origin).distance).reduce(math.max);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(center: origin, radius: (maxRadius + 2) * progress),
      );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviousThemePainter old) =>
      old.progress != progress || old.image != image || old.origin != origin;
}
