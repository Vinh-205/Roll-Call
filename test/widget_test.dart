import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/auth.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/api.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/classes.dart';

void main() {
  test('Release API uses public HTTPS, never localhost', () {
    expect(Uri.parse(apiBase).scheme, 'https');
    expect(Uri.parse(apiBase).host, isNot(contains('localhost')));
  });
  testWidgets('Login validates fields and opens email registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên đăng nhập'), findsOneWidget);
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản sinh viên'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
  testWidgets('Editing a session preserves its existing lateness threshold', (
    tester,
  ) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => SessionEditor(
                    initial: {
                      'title': 'Buổi kiểm tra',
                      'starts': start,
                      'ends': start + 3600000,
                      'late_minutes': 7,
                      'radius': 250,
                    },
                  ),
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu buổi học'));
    await tester.pumpAndSettle();
    expect(result?['lateMinutes'], 7);
    expect(result?['title'], 'Buổi kiểm tra');
  });
}
