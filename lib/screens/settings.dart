import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/ui.dart';
import '../core/preferences.dart';
import '../core/biometrics.dart';
import '../core/theme_reveal.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function()? onEditProfile, onEditAvatar;
  const SettingsScreen({super.key, this.onEditProfile, this.onEditAvatar});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool enabled = false, busy = false, loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final value = await BiometricSecurity.instance.enabled(
      Session.instance.user!['id'],
    );
    if (mounted) {
      setState(() {
        enabled = value;
        loading = false;
      });
    }
  }

  Future<void> biometrics(bool value) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ok = await BiometricSecurity.instance.setEnabled(
        Session.instance.user!['id'],
        value,
      );
      if (mounted) {
        setState(() {
          if (ok) {
            enabled = value;
          } else {
            error = BiometricSecurity.instance.error;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Chưa lưu được lựa chọn. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferences.instance,
        dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark
        ? [darkBg, cosmic, const Color(0xff474254)]
        : [candyBlue, const Color(0xffe5eff4), const Color(0xfff6f8fa)];
    final labels = dark
        ? ['Cosmic dịu', 'Cosmic gốc', 'Lavender']
        : ['Candy Blue', 'Mist', 'Trắng'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt ứng dụng'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const RcIcon(RcIcons.arrowBack),
        ),
      ),
      body: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.onEditProfile != null || widget.onEditAvatar != null)
              Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (widget.onEditProfile != null)
                      ListTile(
                        leading: const RcIcon(RcIcons.badge_rounded, size: 20),
                        title: const Text('Cập nhật hồ sơ cá nhân'),
                        trailing: const RcIcon(RcIcons.chevron_right, size: 18),
                        onTap: widget.onEditProfile,
                      ),
                    if (widget.onEditAvatar != null)
                      ListTile(
                        leading: const RcIcon(RcIcons.imageAdd, size: 20),
                        title: const Text('Đổi ảnh đại diện'),
                        trailing: const RcIcon(RcIcons.chevron_right, size: 18),
                        onTap: widget.onEditAvatar,
                      ),
                  ],
                ),
              ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: RcIcon(RcIcons.textSize, size: 22),
                    title: Text(
                      'Cỡ chữ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${(prefs.textScale * 100).round()}% · Nội dung hiển thị mẫu',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: prefs.textScale,
                    min: .9,
                    max: 1.3,
                    divisions: 4,
                    label: '${(prefs.textScale * 100).round()}%',
                    onChanged: prefs.setTextScale,
                  ),
                  const Text(
                    'Áp dụng cho toàn ứng dụng và được giữ sau khi mở lại.',
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: RcIcon(RcIcons.palette, size: 22),
                    title: Text(
                      'Màu nền',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Text('Lưu màu riêng cho chế độ sáng và tối.'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      colors.length,
                      (i) => ChoiceChip(
                        label: Text(labels[i]),
                        avatar: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        selected:
                            (dark
                                ? prefs.darkBackground ?? darkBg
                                : prefs.lightBackground ?? candyBlue) ==
                            colors[i],
                        onSelected: (_) => ThemeReveal.change(
                          context,
                          () => prefs.setBackground(colors[i], dark: dark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Khuôn mặt / Vân tay',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Dùng sinh trắc học của thiết bị cho lần mở ứng dụng tiếp theo.',
                    ),
                    secondary: const RcIcon(RcIcons.fingerprint, size: 24),
                    value: enabled,
                    onChanged: busy || loading ? null : biometrics,
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lần đầu vẫn cần mật khẩu và Email OTP. Thiết bị quyết định dùng khuôn mặt hay vân tay tùy phần cứng và dữ liệu đã đăng ký. Phiên hết hạn vẫn cần OTP; ứng dụng không lưu mẫu khuôn mặt/vân tay.',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => prefs.reset(),
              child: const Text('Khôi phục cỡ chữ và màu nền mặc định'),
            ),
          ],
        ),
      ),
    );
  }
}
