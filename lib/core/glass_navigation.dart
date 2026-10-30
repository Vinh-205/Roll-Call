import 'dart:ui';

import 'package:flutter/material.dart';

import 'ui.dart';

class GlassNavigation extends StatelessWidget {
  const GlassNavigation({
    super.key,
    required this.index,
    required this.previous,
    required this.icons,
    required this.labels,
    required this.onSelected,
  });

  final int index, previous;
  final List<RcGlyph> icons;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: cosmic.withValues(alpha: dark ? .24 : .12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 82,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? [
                          const Color(0xff5d586f).withValues(alpha: .86),
                          cosmic.withValues(alpha: .82),
                        ]
                      : [
                          Colors.white.withValues(alpha: .76),
                          candyBlue.withValues(alpha: .72),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? .22 : .75),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(
                      -1 + 2 * index / (labels.length - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / labels.length,
                      heightFactor: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: dark ? .7 : .95),
                              candyBlue.withValues(alpha: .88),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cosmic.withValues(alpha: .14),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(labels.length, (i) {
                      final active = i == index;
                      final color = active || !dark ? cosmic : candyBlue;
                      return Expanded(
                        child: Semantics(
                          selected: active,
                          button: true,
                          label: labels[i],
                          child: ExcludeSemantics(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onSelected(i),
                                borderRadius: BorderRadius.circular(23),
                                child: SizedBox(
                                  height: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSlide(
                                        duration: duration,
                                        curve: Curves.easeOutCubic,
                                        offset: active
                                            ? const Offset(0, -.07)
                                            : Offset.zero,
                                        child: RcIcon(
                                          icons[i],
                                          from: active ? icons[previous] : null,
                                          size: 22,
                                          color: color,
                                          autoContrast: false,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Text(
                                          labels[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight: active
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                          ),
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
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
