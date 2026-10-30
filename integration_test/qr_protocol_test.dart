import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/attendance_qr.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android native decoder accepts attendance QR and rejects unrelated QR',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Roll call · Kiểm tra QR trên Android')),
          ),
        ),
      );
      final scanner = MobileScannerController(autoStart: false);
      final directory = await getTemporaryDirectory();
      try {
        for (final value in [
          'catcheck:emulator-session:test-token-123',
          'https://example.com/not-attendance',
        ]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 600, 600),
            Paint()..color = Colors.white,
          );
          canvas.translate(32, 32);
          QrPainter(
            data: value,
            version: QrVersions.auto,
            gapless: false,
            eyeStyle: const QrEyeStyle(color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
          ).paint(canvas, const Size(536, 536));
          final picture = recorder.endRecording();
          final image = await picture.toImage(600, 600);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          picture.dispose();
          expect(png, isNotNull);
          final file = File('${directory.path}/rollcall-qr-native-test.png');
          await file.writeAsBytes(png!.buffer.asUint8List());
          try {
            final capture = await scanner.analyzeImage(
              file.path,
              formats: [BarcodeFormat.qrCode],
            );
            expect(capture, isNotNull);
            final decoded = capture!.barcodes.single.rawValue;
            expect(decoded, value);
            final payload = parseAttendanceQr(decoded!);
            if (value.startsWith('catcheck:')) {
              expect(payload?.sessionId, 'emulator-session');
              expect(payload?.token, 'test-token-123');
            } else {
              expect(payload, isNull);
            }
          } finally {
            if (await file.exists()) await file.delete();
          }
        }
      } finally {
        await scanner.dispose();
      }
    },
  );
}
