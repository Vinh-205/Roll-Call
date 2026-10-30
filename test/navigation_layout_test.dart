import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/api.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/glass_navigation.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/home.dart';

void main() {
  testWidgets('Create/join class buttons remain above glass navigation', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final oldUser = Session.instance.user;
    addTearDown(() => Session.instance.user = oldUser);
    for (final role in ['admin', 'student']) {
      Session.instance.user = {
        'id': 'layout-test',
        'name': 'Test',
        'role': role,
      };
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: HomeScreen(key: ValueKey(role)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lớp học'));
      await tester.pumpAndSettle();
      final button = find.byType(FloatingActionButton);
      expect(button, findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThan(tester.getRect(find.byType(GlassNavigation)).top),
      );
      expect(
        find.text(role == 'admin' ? 'Tạo lớp' : 'Tham gia lớp'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
