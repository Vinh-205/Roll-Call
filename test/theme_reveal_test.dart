import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/theme_reveal.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/ui.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'rollcall_theme': 'light'});
    await ThemeController.instance.restore();
  });

  Widget app({bool reducedMotion = false}) => ListenableBuilder(
    listenable: ThemeController.instance,
    builder: (_, _) => MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeController.instance.mode,
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: ThemeReveal(child: child!),
      ),
      home: const Scaffold(
        body: Column(children: [ThemeToggleButton(), TextField()]),
      ),
    ),
  );

  test(
    'Cosmic and Candy Blue have exact requested colors and readable contrast',
    () {
      expect(cosmic, const Color(0xff23212c));
      expect(buildDarkTheme().scaffoldBackgroundColor, darkBg);
      expect(
        buildLightTheme().scaffoldBackgroundColor,
        const Color(0xffb2d5e5),
      );
      expect(buildDarkTheme().colorScheme.primary, const Color(0xffb2d5e5));
      final contrast =
          (const Color(0xffb2d5e5).computeLuminance() + .05) /
          (const Color(0xff23212c).computeLuminance() + .05);
      expect(contrast, greaterThan(7));
    },
  );

  testWidgets(
    'Circular theme reveal preserves form state and cleans its overlay',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Giữ nội dung đang nhập');
      final fieldState = tester.state(find.byType(EditableText));
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
      expect(ThemeController.instance.mode, ThemeMode.dark);
      expect(
        find.byKey(const ValueKey('theme-reveal-overlay')),
        findsOneWidget,
      );
      expect(tester.state(find.byType(EditableText)), same(fieldState));
      expect(find.text('Giữ nội dung đang nhập'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.byKey(const ValueKey('theme-reveal-overlay')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Reduced motion switches theme without capturing or playing a ripple',
    (tester) async {
      await tester.pumpWidget(app(reducedMotion: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.mode, ThemeMode.dark);
      expect(find.byKey(const ValueKey('theme-reveal-overlay')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
