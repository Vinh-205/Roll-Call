import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/ui.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/splash.dart';

void main() {
  testWidgets('Splash completes once without replacing the app navigator', (
    tester,
  ) async {
    int completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onComplete: () => completed++)),
    );
    expect(find.text('Roll call'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Theme toggle persists the selected mode and renders opaque cards',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'rollcall_theme': 'light'});
      await ThemeController.instance.restore();
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: ThemeController.instance.mode,
            home: const Scaffold(
              body: Column(
                children: [
                  ThemeToggleButton(),
                  Panel(child: ListTile(title: Text('Lớp demo'))),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.mode, ThemeMode.dark);
      expect(
        await const FlutterSecureStorage().read(key: 'rollcall_theme'),
        'dark',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      ThemeController.instance.setMode(ThemeMode.light);
    },
  );
}
