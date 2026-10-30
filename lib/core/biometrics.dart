import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'api.dart';
import 'ui.dart';
import 'brand.dart';

class BiometricSecurity {
  static final instance = BiometricSecurity();
  BiometricSecurity({LocalAuthentication? authenticator})
    : auth = authenticator ?? LocalAuthentication();
  final LocalAuthentication auth;
  static const storage = FlutterSecureStorage();
  String? unlockedUser;
  String? error;
  void acceptOtp(String userId) => unlockedUser = userId;
  Future<bool> enabled(String userId) async =>
      await storage.read(key: 'rollcall_biometric_$userId') == 'true';
  Future<List<BiometricType>> available() async {
    try {
      if (!await auth.canCheckBiometrics) return [];
      return await auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate(String userId) async {
    error = null;
    try {
      if ((await available()).isEmpty) {
        error = 'Thiết bị chưa có khuôn mặt hoặc vân tay khả dụng. Hãy đăng ký sinh trắc học trong Cài đặt thiết bị.';
        return false;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Xác thực để mở Roll call',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        unlockedUser = userId;
      } else {
        error = 'Chưa xác thực thành công. Bạn có thể thử lại hoặc dùng mật khẩu và OTP.';
      }
      return ok;
    } on LocalAuthException catch (e) {
      final code = e.code.name.toLowerCase();
      error = code.contains('lockout')
          ? 'Sinh trắc học đang tạm khóa. Dùng mật khẩu và OTP hoặc thử lại sau.'
          : 'Không xác thực được. Kiểm tra sinh trắc học của thiết bị hoặc dùng mật khẩu và OTP.';
      return false;
    } catch (_) {
      error = 'Không mở được xác thực sinh trắc học trên thiết bị này.';
      return false;
    }
  }

  Future<bool> setEnabled(String userId, bool value) async {
    if ((value || unlockedUser != userId) && !await authenticate(userId)) {
      return false;
    }
    await storage.write(
      key: 'rollcall_biometric_$userId',
      value: value.toString(),
    );
    return true;
  }
}

/// Wraps the entire authenticated Navigator, including pushed settings routes.
class BiometricGate extends StatefulWidget {
  final String userId;
  final Widget child;
  final BiometricSecurity? security;
  const BiometricGate({
    super.key,
    required this.userId,
    required this.child,
    this.security,
  });
  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  late final security = widget.security ?? BiometricSecurity.instance;
  bool checking = true, locked = true, busy = false;
  DateTime? backgroundAt;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  Future<void> initialize() async {
    final enabled = await security.enabled(widget.userId);
    if (!mounted) return;
    setState(() {
      checking = false;
      locked = enabled && security.unlockedUser != widget.userId;
    });
    if (locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unlock();
      });
    }
  }

  Future<void> unlock() async {
    if (busy) return;
    setState(() => busy = true);
    final ok = await security.authenticate(widget.userId);
    if (mounted) {
      setState(() {
        busy = false;
        locked = !ok;
      });
    }
  }

  Future<void> usePassword() async {
    if (busy) return;
    setState(() => busy = true);
    security.unlockedUser = null;
    try {
      await Api.instance.call('POST', 'auth/logout');
    } catch (_) {}
    await Session.instance.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !busy) {
      backgroundAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed && !busy) {
      final since = backgroundAt;
      backgroundAt = null;
      if (since != null &&
          DateTime.now().difference(since) >= const Duration(minutes: 1)) {
        lockAfterBackground();
      }
    }
  }

  Future<void> lockAfterBackground() async {
    if (!await security.enabled(widget.userId) || !mounted) return;
    security.unlockedUser = null;
    setState(() => locked = true);
    await unlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: checking || locked,
        child: TickerMode(enabled: !checking && !locked, child: widget.child),
      ),
      if (checking || locked)
        Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 76),
                      const SizedBox(height: 24),
                      const Text(
                        'Mở khóa Roll call',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Dùng khuôn mặt hoặc vân tay đã đăng ký trên thiết bị.',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      if (checking || busy)
                        const CircularProgressIndicator()
                      else ...[
                        FilledButton.icon(
                          onPressed: unlock,
                          icon: const RcIcon(RcIcons.fingerprint),
                          label: const Text('Xác thực sinh trắc học'),
                        ),
                        if (security.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              security.error!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: usePassword,
                          child: const Text('Dùng mật khẩu và Email OTP'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
