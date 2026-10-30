import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/icons.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/morphicons.dart';

void main() {
  test('Flutter morph geometry matches the official morphicons engine', () {
    final fixtures = jsonDecode(
      File('test/morphicons_fixtures.json').readAsStringSync(),
    ) as Map;
    for (final entry in fixtures.entries) {
      final actual = MorphiconsGeometry.points(
        'play_arrow>pause',
        double.parse(entry.key),
      );
      final expected = entry.value as List;
      expect(actual.length, expected.length);
      for (int k = 0; k < actual.length; k++) {
        for (int i = 0; i < actual[k].length; i++) {
          expect(
            actual[k][i],
            closeTo((expected[k][i] as num).toDouble(), .00001),
          );
        }
      }
    }
  });
  testWidgets(
    'Morphicons morphs play to pause and settles without a ticker leak',
    (tester) async {
      Widget icon(RcGlyph glyph) =>
          MaterialApp(home: Scaffold(body: RcIcon(glyph)));
      await tester.pumpWidget(icon(RcIcons.play_arrow));
      await tester.pumpWidget(icon(RcIcons.pause));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle();
      expect(find.byType(MorphiconsIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
