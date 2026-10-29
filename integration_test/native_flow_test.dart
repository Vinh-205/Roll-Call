import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/main.dart' as app;
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/api.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native Android: password + one-time email sandbox, admin CRUD, QR and logout',
    (tester) async {
      expect(
        ['localhost', '127.0.0.1'].contains(Uri.parse(apiBase).host),
        true,
        reason: 'Native sandbox tests must never target production.',
      );
      Future<void> see(Finder f) async {
        for (var i = 0; i < 200; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (f.evaluate().isNotEmpty) return;
        }
        fail('Not found: $f');
      }

      Future<void> tap(String label) async {
        final f = find.text(label);
        await see(f);
        await tester.ensureVisible(f.first);
        await tester.pumpAndSettle();
        await tester.tap(f.first);
        await tester.pumpAndSettle();
      }

      await app.main();
      await tester.pumpAndSettle();
      await Session.instance.clear();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        const String.fromEnvironment('TEST_ADMIN_USERNAME'),
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'CatCheck2577');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Đăng nhập');
      await see(find.text('Xác thực Email OTP'));
      final dynamic state = tester.state(find.byType(AuthScreen));
      final String otp = state.challenge['testOnlyCode'];
      await tester.enterText(find.byType(TextFormField).first, otp);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Xác nhận và tiếp tục');
      await see(find.text('QUẢN TRỊ VIÊN'));
      await Session.instance.restore();
      await tester.pumpAndSettle();
      await see(find.text('QUẢN TRỊ VIÊN'));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Lớp học'),
        ),
      );
      await tester.pumpAndSettle();
      await tap('Tạo lớp');
      final name = 'Android native ${DateTime.now().millisecondsSinceEpoch}';
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'N${DateTime.now().millisecondsSinceEpoch}',
      );
      await tester.enterText(find.byType(TextFormField).at(1), name);
      await tester.enterText(find.byType(TextFormField).at(2), 'E1.04');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Tiếp tục');
      await see(find.text(name));
      await tap(name);
      await see(find.text('Các buổi học'));
      await tap('Tạo buổi học');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Buổi kiểm thử Android',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Lưu buổi học');
      await see(find.text('Các buổi học'));
      await see(find.text('Buổi kiểm thử Android'));
      await tap('Buổi kiểm thử Android');
      await see(find.text('QR điểm danh có thời hạn'));
      await see(find.text('Đổi mã / tải danh sách'));
      final courses = await Api.instance.list('courses');
      final course = courses.singleWhere((c) => c['name'] == name);
      await Api.instance.call('DELETE', 'courses/${course['id']}');
      await Session.instance.clear();
      await tester.pumpAndSettle();
      await see(find.text('Chào mừng trở lại'));
    },
  );
}
