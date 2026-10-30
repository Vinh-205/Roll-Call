import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferences extends ChangeNotifier {
  static final instance = AppPreferences._();
  AppPreferences._();
  static const storage = FlutterSecureStorage();
  double textScale = 1;
  Color? lightBackground, darkBackground;
  Future<void> restore() async {
    try {
      final values = await Future.wait([
        storage.read(key: 'rollcall_text_scale'),
        storage.read(key: 'rollcall_background_light'),
        storage.read(key: 'rollcall_background_dark'),
      ]);
      textScale = (double.tryParse(values[0] ?? '') ?? 1).clamp(.9, 1.3);
      final light = int.tryParse(values[1] ?? ''),
          dark = int.tryParse(values[2] ?? '');
      lightBackground = light == null ? null : Color(light);
      darkBackground = dark == null ? null : Color(dark);
    } catch (_) {
      textScale = 1;
      lightBackground = null;
      darkBackground = null;
    }
  }

  void setTextScale(double value) {
    textScale = value.clamp(.9, 1.3);
    notifyListeners();
    unawaited(
      storage
          .write(key: 'rollcall_text_scale', value: textScale.toString())
          .catchError((_) {}),
    );
  }

  void setBackground(Color color, {required bool dark}) {
    if (dark) {
      darkBackground = color;
    } else {
      lightBackground = color;
    }
    notifyListeners();
    unawaited(
      storage
          .write(
            key: dark
                ? 'rollcall_background_dark'
                : 'rollcall_background_light',
            value: color.toARGB32().toString(),
          )
          .catchError((_) {}),
    );
  }

  Future<void> reset() async {
    textScale = 1;
    lightBackground = null;
    darkBackground = null;
    notifyListeners();
    await Future.wait(
      [
        'rollcall_text_scale',
        'rollcall_background_light',
        'rollcall_background_dark',
      ].map((key) => storage.delete(key: key)),
    );
  }
}
