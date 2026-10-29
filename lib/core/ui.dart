import 'dart:async';
import 'icons.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'icons.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';

// --- Bảng màu chính (Modern Aesthetic Lucian Labs Inspiration) ---
const ink = Color(0xff18203a);
const gold = Color(0xffb8e870);
const teal = Color(0xff7357e8);
const tealLight = Color(0xffb8a6ff);
const paper = Color(0xfff4f5fa);

// Các màu nền Dark Mode hiện đại (Slate/Navy)
const darkBg = Color(0xff101323);
const darkCard = Color(0xff1b2034);
const darkBorder = Color(0xff30374f);

// Quản lý trạng thái Sáng / Tối toàn ứng dụng
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> restore() async {
    try {
      final value = await const FlutterSecureStorage().read(
        key: 'rollcall_theme',
      );
      if (value != null) {
        _mode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  void toggleTheme() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(
      const FlutterSecureStorage()
          .write(key: 'rollcall_theme', value: isDark ? 'dark' : 'light')
          .catchError((_) {}),
    );
  }

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
    unawaited(
      const FlutterSecureStorage()
          .write(key: 'rollcall_theme', value: isDark ? 'dark' : 'light')
          .catchError((_) {}),
    );
  }
}

// Cấu hình ThemeData chuẩn Material 3 Hiện đại
ThemeData buildLightTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: teal,
    brightness: Brightness.light,
    primary: teal,
    secondary: gold,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: paper,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xffe2e8f0)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffcbd5e1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: teal, width: 1.8),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: tealLight,
    brightness: Brightness.dark,
    primary: tealLight,
    secondary: gold,
    surface: darkCard,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tealLight, width: 1.8),
      ),
    ),
  );
}

final dateFormat = DateFormat('dd/MM · HH:mm');
String when(dynamic value) => value == null
    ? '—'
    : dateFormat.format(
        DateTime.fromMillisecondsSinceEpoch((value as num).toInt()),
      );

String roleLabel(String role) =>
    {
      'admin': 'Quản trị viên',
      'teacher': 'Giảng viên',
      'student': 'Sinh viên',
    }[role] ??
    role;

String statusLabel(dynamic status) =>
    {
      'present': 'Đúng giờ',
      'late': 'Đến muộn',
      'excused': 'Có phép',
      'pending': 'Chờ duyệt',
      'approved': 'Đã chấp nhận',
      'rejected': 'Từ chối',
    }[status] ??
    'Chưa điểm danh';

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

// Tag phong cách badge hiện đại
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = teal});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .24), width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .3,
      ),
    ),
  );
}

// Panel/Card nổi phong cách Bento Box (Lucian Labs UI)
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = color ?? (isDark ? darkCard : Colors.white);
    final borderColor = isDark ? darkBorder : const Color(0xffe2e8f0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// Nút chuyển đổi Dark/Light mode tròn nổi
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        return Tooltip(
          message: isDark
              ? 'Chuyển sang giao diện sáng'
              : 'Chuyển sang giao diện tối',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => ThemeController.instance.toggleTheme(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xff30374f)
                      : const Color(0xffe2e8f0),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey).withValues(
                        alpha: .15,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: RcIcon(
                    isDark
                        ? RcIcons.light_mode_rounded
                        : RcIcons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    size: 20,
                    color: isDark ? gold : ink,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Empty extends StatelessWidget {
  final String title, body;
  final RcGlyph icon;
  final VoidCallback? retry;
  const Empty(
    this.title,
    this.body, {
    super.key,
    this.icon = RcIcons.inbox_rounded,
    this.retry,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: teal.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: RcIcon(icon, size: 44, color: teal),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff778399), height: 1.4),
        ),
        if (retry != null) ...[
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: retry, child: const Text('Thử lại')),
        ],
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;

Future<JsonMap?> editor(
  BuildContext context,
  String title,
  List<Field> fields, {
  JsonMap initial = const {},
}) async {
  return showDialog<JsonMap>(
    context: context,
    builder: (_) =>
        RecordEditor(title: title, fields: fields, initial: initial),
  );
}

class Field {
  final String keyName, label;
  final bool required, number, password;
  final int lines;
  const Field(
    this.keyName,
    this.label, {
    this.required = true,
    this.number = false,
    this.password = false,
    this.lines = 1,
  });
}

class RecordEditor extends StatefulWidget {
  final String title;
  final List<Field> fields;
  final JsonMap initial;
  const RecordEditor({
    super.key,
    required this.title,
    required this.fields,
    required this.initial,
  });
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final form = GlobalKey<FormState>();
  late final controllers = {
    for (final f in widget.fields)
      f.keyName: TextEditingController(
        text: widget.initial[f.keyName]?.toString() ?? '',
      ),
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Text(
      widget.title,
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: controllers[f.keyName],
                    obscureText: f.password,
                    minLines: f.lines,
                    maxLines: f.lines,
                    keyboardType: f.number
                        ? const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          )
                        : TextInputType.text,
                    decoration: InputDecoration(labelText: f.label),
                    validator: (v) => f.required && (v ?? '').trim().isEmpty
                        ? 'Vui lòng nhập thông tin'
                        : f.number &&
                              (v ?? '').isNotEmpty &&
                              num.tryParse(v!) == null
                        ? 'Nhập số hợp lệ'
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, {
              for (final f in widget.fields)
                f.keyName: f.number
                    ? num.tryParse(controllers[f.keyName]!.text)
                    : controllers[f.keyName]!.text.trim(),
            });
          }
        },
        child: const Text('Tiếp tục'),
      ),
    ],
  );
}
