// Native Flutter adapter for morphicons' generated curves and morph plans.
// Polar interpolation and spring integration ported from morphicons 2.0.2.
// Copyright Guillermo; MIT license: docs/licenses/Morphicons-LICENSE.txt.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'morphicons_data.g.dart';

Float64List _numbers(dynamic values) => Float64List.fromList(
  (values as List).map((v) => (v as num).toDouble()).toList(),
);

class MorphiconsGeometry {
  static final _icons = <String, List<Path>>{};
  static bool hasPlan(String key) =>
      (morphiconsData['plans'] as Map).containsKey(key);
  static List<Path> icon(String name) => _icons.putIfAbsent(name, () {
    return ((morphiconsData['icons'] as Map)[name] as List)
        .map((part) {
          final p = _numbers(part['pts']);
          final path = Path()..moveTo(p[0], p[1]);
          for (int i = 2; i < p.length; i += 6) {
            path.cubicTo(
              p[i],
              p[i + 1],
              p[i + 2],
              p[i + 3],
              p[i + 4],
              p[i + 5],
            );
          }
          if (part['closed'] as bool) path.close();
          return path;
        })
        .toList(growable: false);
  });

  static final _plans = <String, List<_PlanPart>>{};
  static List<_PlanPart> _plan(String key) => _plans.putIfAbsent(
    key,
    () => (((morphiconsData['plans'] as Map)[key] as Map)['items'] as List)
        .map((item) => _PlanPart(item as Map))
        .toList(growable: false),
  );

  /// Exact polar/block transport from morphicons/core/interpolate.ts.
  static List<Float64List> points(String key, double t) => _plan(key)
      .map((it) {
        final out = Float64List(it.a.length);
        final scale = math.exp(it.lnSigma * t), angle = it.theta * t;
        final cos = math.cos(angle) * scale, sin = math.sin(angle) * scale;
        double cx, cy;
        if (it.off != null) {
          final ox = it.off![0], oy = it.off![1];
          cx = it.ca[0] + it.drift![0] * t + (ox * cos - oy * sin - ox);
          cy = it.ca[1] + it.drift![1] * t + (ox * sin + oy * cos - oy);
        } else {
          cx = it.ca[0] + (it.cb[0] - it.ca[0]) * t;
          cy = it.ca[1] + (it.cb[1] - it.ca[1]) * t;
        }
        for (int i = 0; i < out.length; i += 2) {
          final px = it.a[i] + (it.b[i] - it.a[i]) * t;
          final py = it.a[i + 1] + (it.b[i + 1] - it.a[i + 1]) * t;
          out[i] = cx + px * cos - py * sin;
          out[i + 1] = cy + px * sin + py * cos;
        }
        return out;
      })
      .toList(growable: false);

  static List<Path> interpolate(String key, double t) {
    final positions = points(key, t), parts = _plan(key);
    return List.generate(parts.length, (k) {
      final p = positions[k];
      final path = Path()..moveTo(p[0], p[1]);
      for (int i = 2; i < p.length; i += 2) {
        path.lineTo(p[i], p[i + 1]);
      }
      if (parts[k].closed) path.close();
      return path;
    }, growable: false);
  }
}

class _PlanPart {
  final Float64List a, b, ca, cb;
  final Float64List? off, drift;
  final double theta, lnSigma;
  final bool closed;
  _PlanPart(Map item)
    : a = _numbers(item['aC']),
      b = _numbers(item['bT']),
      ca = _numbers(item['ca']),
      cb = _numbers(item['cb']),
      off = item['block'] == null ? null : _numbers(item['block']['off']),
      drift = item['block'] == null ? null : _numbers(item['block']['drift']),
      theta = (item['theta'] as num).toDouble(),
      lnSigma = (item['lnSigma'] as num).toDouble(),
      closed = item['closed'] as bool;
}

class MorphiconsIcon extends StatefulWidget {
  final String icon;
  final String? from, label;
  final double size;
  final Color color;
  const MorphiconsIcon(
    this.icon, {
    super.key,
    this.from,
    this.label,
    required this.size,
    required this.color,
  });
  @override
  State<MorphiconsIcon> createState() => _MorphiconsIconState();
}

class _MorphiconsIconState extends State<MorphiconsIcon>
    with SingleTickerProviderStateMixin {
  late List<Path> paths = MorphiconsGeometry.icon(widget.icon);
  late final Ticker ticker = createTicker(tick);
  String? key, source, target;
  double x = 1, velocity = 0, goal = 1;
  Duration last = Duration.zero;
  bool reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      ticker.stop();
      paths = MorphiconsGeometry.icon(widget.icon);
    } else if (widget.from != null && source == null) {
      animate(widget.from!, widget.icon);
    }
  }

  @override
  void didUpdateWidget(MorphiconsIcon old) {
    super.didUpdateWidget(old);
    if (old.icon != widget.icon) {
      animate(old.icon, widget.icon);
    } else if (widget.from != null && widget.from != old.from) {
      animate(widget.from!, widget.icon);
    }
  }

  void animate(String from, String to) {
    if (reduced || from == to) {
      ticker.stop();
      paths = MorphiconsGeometry.icon(to);
      return;
    }
    if (ticker.isActive && (to == source || to == target)) {
      goal = to == target ? 1 : 0;
      return;
    }
    final next = '$from>$to';
    if (!MorphiconsGeometry.hasPlan(next)) {
      ticker.stop();
      paths = MorphiconsGeometry.icon(to);
      return;
    }
    ticker.stop();
    key = next;
    source = from;
    target = to;
    x = 0;
    goal = 1;
    velocity = 0;
    last = Duration.zero;
    paths = MorphiconsGeometry.interpolate(next, 0);
    ticker.start();
  }

  void tick(Duration elapsed) {
    final dt = math.min((elapsed - last).inMicroseconds / 1000000, 1 / 15);
    last = elapsed;
    final steps = (dt * 240).ceil().clamp(1, 16), h = dt / steps;
    final spring = morphiconsData['spring'] as Map;
    for (int i = 0; i < steps; i++) {
      final acceleration =
          (spring['k'] as num) * (goal - x) - (spring['c'] as num) * velocity;
      velocity += acceleration * h;
      x += velocity * h;
    }
    final settled = (goal - x).abs() < .001 && velocity.abs() < .02;
    setState(
      () => paths = settled
          ? MorphiconsGeometry.icon(widget.icon)
          : MorphiconsGeometry.interpolate(key!, x),
    );
    if (settled) ticker.stop();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    excludeSemantics: widget.label == null,
    child: Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(painter: _MorphiconsPainter(paths, widget.color)),
        ),
      ),
    ),
  );
}

class _MorphiconsPainter extends CustomPainter {
  final List<Path> paths;
  final Color color;
  const _MorphiconsPainter(this.paths, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in paths) {
      canvas.drawPath(path, pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MorphiconsPainter old) =>
      old.paths != paths || old.color != color;
}
