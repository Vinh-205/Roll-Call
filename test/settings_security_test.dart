import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/biometrics.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/preferences.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/ui.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/morphicons.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/screens/auth.dart';

class FakeAuthentication extends LocalAuthentication {
  bool enrolled = true, result = false;
  int calls = 0;
  @override
  Future<bool> get canCheckBiometrics async => enrolled;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      enrolled ? [BiometricType.fingerprint] : [];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    expect(biometricOnly, isTrue);
    calls++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('Failed biometric opt-in never enables biometric login', () async {
    final fake = FakeAuthentication();
    final security = BiometricSecurity(authenticator: fake);
    security.acceptOtp('user-a');
    expect(await security.setEnabled('user-a', true), isFalse);
    expect(await security.enabled('user-a'), isFalse);
    fake.result = true;
    expect(await security.setEnabled('user-a', true), isTrue);
    expect(await security.enabled('user-a'), isTrue);
    expect(await security.enabled('user-b'), isFalse);
  });

  testWidgets(
    'Protected routes stay offstage after failed biometrics, then unlock on success',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'rollcall_biometric_user-a': 'true',
      });
      final fake = FakeAuthentication();
      final security = BiometricSecurity(authenticator: fake);
      await tester.pumpWidget(
        MaterialApp(
          home: BiometricGate(
            userId: 'user-a',
            security: security,
            child: const Scaffold(body: Text('Protected account')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Protected account'), findsNothing);
      expect(
        find.text('Protected account', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Mở khóa Roll call'), findsOneWidget);
      fake.result = true;
      await tester.tap(find.text('Xác thực sinh trắc học'));
      await tester.pumpAndSettle();
      expect(find.text('Protected account'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'Text size and backgrounds persist independently and reset cleanly',
    () async {
      final prefs = AppPreferences.instance;
      await prefs.reset();
      prefs.setTextScale(1.2);
      prefs.setBackground(const Color(0xffe5eff4), dark: false);
      prefs.setBackground(const Color(0xff474254), dark: true);
      await Future<void>.delayed(Duration.zero);
      await prefs.restore();
      expect(prefs.textScale, 1.2);
      expect(prefs.lightBackground, const Color(0xffe5eff4));
      expect(prefs.darkBackground, const Color(0xff474254));
      await prefs.reset();
      expect(prefs.textScale, 1);
      expect(prefs.lightBackground, isNull);
      expect(prefs.darkBackground, isNull);
    },
  );

  testWidgets(
    'Login field icons stay 20px inside 48px input slots and login button is visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const AuthScreen()),
      );
      await tester.pumpAndSettle();
      final icon = find
          .descendant(
            of: find.byType(TextFormField).first,
            matching: find.byType(MorphiconsIcon),
          )
          .first;
      final paint = find
          .descendant(of: icon, matching: find.byType(CustomPaint))
          .first;
      expect(tester.getSize(paint), const Size(20, 20));
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(button.style!.backgroundColor!.resolve({}), cosmic);
      expect(button.style!.foregroundColor!.resolve({}), candyBlue);
      expect(find.byType(ThemeToggleButton), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
