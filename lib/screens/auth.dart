import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/ui.dart';
import '../core/brand.dart';
import '../core/biometrics.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(),
      password = TextEditingController(),
      email = TextEditingController(),
      name = TextEditingController(),
      studentCode = TextEditingController(),
      otp = TextEditingController();
  bool register = false, busy = false, obscure = true;
  JsonMap? challenge;
  String? error;

  @override
  void dispose() {
    for (final c in [username, password, email, name, studentCode, otp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (challenge != null) {
        final result = await Api.instance.call(
          'POST',
          'auth/verify',
          auth: false,
          data: {
            'challengeId': challenge!['challengeId'],
            'code': otp.text.trim(),
          },
        );
        await Session.instance.accept(JsonMap.from(result as Map));
        BiometricSecurity.instance.acceptOtp(Session.instance.user!['id']);
      } else {
        final result = await Api.instance.call(
          'POST',
          register ? 'auth/register' : 'auth/login',
          auth: false,
          data: {
            'username': username.text.trim(),
            'password': password.text,
            if (register) ...{
              'name': name.text.trim(),
              'email': email.text.trim(),
              'studentCode': studentCode.text.trim(),
            },
          },
        );
        if (mounted) setState(() => challenge = JsonMap.from(result as Map));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Top App Bar với Branding và Theme Toggle
            Row(
              children: [
                const BrandMark(size: 40),
                const SizedBox(width: 10),
                Text(
                  'Roll call',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : ink,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 28),

            RollHero(
              title: challenge != null
                  ? 'An tâm đăng nhập.\nSẵn sàng đến lớp.'
                  : 'Có mặt hôm nay.\nKết nối ngày mai.',
              subtitle: 'Điểm danh bằng QR và vị trí.\nMỗi buổi học đều được ghi nhận.',
            ),
            const SizedBox(height: 26),
            // Header Form
            Text(
              challenge != null
                  ? 'Xác thực Email OTP'
                  : register
                  ? 'Tạo tài khoản sinh viên'
                  : 'Chào mừng trở lại',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge != null
                  ? 'Mã 6 số đã được gửi tới ${challenge!['emailHint']}. Có hiệu lực 10 phút.'
                  : register
                  ? 'Dùng email thật để nhận mã xác thực.'
                  : 'Tên đăng nhập + mật khẩu, sau đó xác thực qua email.',
              style: TextStyle(
                color: isDark ? Colors.white60 : muted(context),
                height: 1.5,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            Form(
              key: form,
              child: Column(
                children: [
                  if (challenge == null) ...[
                    if (register) ...[
                      TextFormField(
                        controller: name,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: RcIcon(RcIcons.badge_rounded, size: 20),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Nhập họ tên' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: RcIcon(RcIcons.mail_rounded, size: 20),
                        ),
                        validator: (v) =>
                            !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v ?? '')
                            ? 'Email không hợp lệ'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: studentCode,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Mã sinh viên',
                          prefixIcon: RcIcon(RcIcons.pin_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: username,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                        prefixIcon: RcIcon(RcIcons.person_rounded, size: 20),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Nhập tên đăng nhập'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const RcIcon(
                          RcIcons.lock_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: RcIcon(
                            obscure
                                ? RcIcons.visibility_off_rounded
                                : RcIcons.visibility_rounded,
                            color: muted(context),
                            size: 20,
                          ),
                        ),
                        helperText: register
                            ? 'Ít nhất 8 ký tự, có chữ và số'
                            : null,
                      ),
                      validator: (v) => (v ?? '').isEmpty
                          ? 'Nhập mật khẩu'
                          : register &&
                                (v!.length < 8 ||
                                    !RegExp(r'[a-zA-Z]').hasMatch(v) ||
                                    !RegExp(r'\d').hasMatch(v))
                          ? 'Mật khẩu cần ít nhất 8 ký tự, có chữ và số'
                          : null,
                    ),
                  ] else
                    TextFormField(
                      controller: otp,
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Mã xác thực 6 số',
                        prefixIcon: RcIcon(
                          RcIcons.verified_user_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (v) => !RegExp(r'^\d{6}$').hasMatch(v ?? '')
                          ? 'Nhập đủ 6 chữ số'
                          : null,
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: .3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const RcIcon(
                              RcIcons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: busy ? null : submit,
                      child: busy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              challenge != null
                                  ? 'Xác nhận và tiếp tục'
                                  : register
                                  ? 'Đăng ký bằng email'
                                  : 'Đăng nhập',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            if (challenge != null) {
                              challenge = null;
                              otp.clear();
                            } else {
                              register = !register;
                            }
                            error = null;
                          }),
                    child: Text(
                      challenge != null
                          ? 'Gửi lại mã / đổi tài khoản'
                          : register
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TRƯƠNG TUẤN VĨNH · 2380602577',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: muted(context),
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
