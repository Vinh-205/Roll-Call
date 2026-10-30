import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/otp_input.dart';

void main() {
  testWidgets('OTP filters pasted text and validates through one editor', (
    tester,
  ) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: OtpInput(controller: controller),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '12a34 5678');
    expect(controller.text, '123456');
    expect(form.currentState!.validate(), isTrue);
    await tester.enterText(find.byType(TextFormField), '123');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Nhập đủ 6 chữ số'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Six equal OTP cells fit narrow screens and large text', (
    tester,
  ) async {
    final controller = TextEditingController(text: '123456');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 280,
                child: OtpInput(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
    final cells = find.descendant(
      of: find.byType(OtpInput),
      matching: find.byType(AnimatedContainer),
    );
    expect(cells, findsNWidgets(6));
    final sizes = tester.getSize(cells.first);
    for (final element in cells.evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)), sizes);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
