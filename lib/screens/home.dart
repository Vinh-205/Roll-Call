import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/ui.dart';
import '../core/brand.dart';
import '../core/avatar.dart';
import '../core/glass_navigation.dart';
import 'classes.dart';
import 'attendance.dart';
import 'focus.dart';
import 'reviews.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0, previous = 0;
  void select(int next) {
    if (next == index || next < 0 || next > 4) return;
    setState(() {
      previous = index;
      index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = Session.instance.staff;
    final pages = <Widget>[
      const Overview(),
      const ClassesScreen(),
      staff ? const ReviewsScreen() : const HistoryScreen(),
      const FocusScreen(),
      const AccountScreen(),
    ];
    final icons = [
      RcIcons.grid_view_rounded,
      RcIcons.school_rounded,
      staff ? RcIcons.fact_check_rounded : RcIcons.history_rounded,
      RcIcons.sensors_rounded,
      RcIcons.person_rounded,
    ];
    final labels = [
      'Trang chủ',
      'Lớp học',
      staff ? 'Giải trình' : 'Lịch sử',
      'Nhịp học',
      'Cá nhân',
    ];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return Scaffold(
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0).abs() > 300) {
              select(index + ((d.primaryVelocity ?? 0) < 0 ? 1 : -1));
            }
          },
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, a) => SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index >= previous ? 0.12 : -0.12, 0),
                end: Offset.zero,
              ).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
          ),
        ),
      ),
      bottomNavigationBar: GlassNavigation(
        index: index,
        previous: previous,
        icons: icons,
        labels: labels,
        onSelected: select,
      ),
    );
  }
}

class Overview extends StatefulWidget {
  const Overview({super.key});
  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  List<JsonMap> sessions = [], courses = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final values = await Future.wait([
        Api.instance.list('sessions'),
        Api.instance.list('courses'),
      ]);
      if (mounted) {
        setState(() {
          sessions = values[0];
          courses = values[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Session.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upcoming = sessions
        .where(
          (r) => (r['ends'] as num) > DateTime.now().millisecondsSinceEpoch,
        )
        .toList()
        .reversed
        .toList();

    return RefreshIndicator(
      color: teal,
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // Header Bar với Brand & Nút Chuyển đổi Dark/Light
          Row(
            children: [
              const BrandMark(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Roll call',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : ink,
                  ),
                ),
              ),

              UserAvatar(
                userId: s.user!['id'],
                name: s.user!['name'],
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Greeting
          Text(
            'Xin chào, ${s.user!['name'].toString().split(' ').last} 👋',
            style: TextStyle(
              color: isDark ? Colors.white70 : muted(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.staff
                ? 'Sẵn sàng cho\nbuổi học tiếp theo?'
                : 'Một ngày học tốt\nbắt đầu từ có mặt.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -.6,
              color: isDark ? Colors.white : ink,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(roleLabel(s.role).toUpperCase()),
              const Tag('ROLL CALL', color: teal),
            ],
          ),
          const SizedBox(height: 20),

          RollHero(
            label: s.staff ? 'VẬN HÀNH LỚP HỌC' : 'ĐIỂM DANH THÔNG MINH',
            title: s.staff
                ? 'Lớp học kết nối.\nĐiểm danh rõ ràng.'
                : 'Một lần quét.\nGhi nhận có mặt.',
            subtitle: s.staff
                ? 'Tạo buổi học, mở mã QR và theo dõi lớp.'
                : 'Vị trí chỉ được chia sẻ khi bạn xác nhận điểm danh.',
            action: s.staff
                ? null
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffb2d5e5),
                      foregroundColor: ink,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinScreen()),
                    ),
                    icon: const RcIcon(
                      RcIcons.qr_code_scanner_rounded,
                      size: 20,
                    ),
                    label: const Text('Quét QR điểm danh'),
                  ),
          ),
          const SizedBox(height: 20),
          // Bento Box Metrics
          Row(
            children: [
              Expanded(
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const RcIcon(
                          RcIcons.school_rounded,
                          color: teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${courses.length}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : ink,
                        ),
                      ),
                      Text(
                        'Lớp học',
                        style: TextStyle(
                          color: muted(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const RcIcon(
                          RcIcons.event_available_rounded,
                          color: gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${upcoming.length}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Buổi sắp tới',
                        style: TextStyle(
                          color: muted(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Lịch học
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch học của bạn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : ink,
                ),
              ),
              if (upcoming.isNotEmpty)
                Text(
                  '${upcoming.length} buổi',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: teal),
              ),
            )
          else if (error != null)
            Empty('Chưa tải được lịch', error!, retry: load)
          else if (upcoming.isEmpty)
            const Empty(
              'Chưa có buổi học sắp tới',
              'Vào Lớp học để tham gia lớp hoặc tạo buổi học mới.',
            )
          else
            ...upcoming
                .take(5)
                .map(
                  (r) => SessionTile(
                    row: r,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionScreen(session: r),
                      ),
                    ).then((_) => load()),
                  ),
                ),
          const SizedBox(height: 10),

          // Info Panel
          Panel(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const RcIcon(
                    RcIcons.mark_chat_read_rounded,
                    color: teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Có lý do? Hãy lên tiếng.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Giải trình có phản hồi và dấu thời gian.',
                        style: TextStyle(color: muted(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SessionTile extends StatelessWidget {
  final JsonMap row;
  final VoidCallback onTap;
  const SessionTile({super.key, required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: teal.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const RcIcon(
            RcIcons.event_available_rounded,
            color: teal,
            size: 22,
          ),
        ),
        title: Text(
          row['title'],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${row['course_name'] ?? ''}\n${when(row['starts'])} · ${row['room'] ?? ''}',
            style: const TextStyle(height: 1.4, fontSize: 13),
          ),
        ),
        isThreeLine: true,
        trailing: RcIcon(
          RcIcons.arrow_forward_ios_rounded,
          size: 16,
          color: muted(context),
        ),
        onTap: onTap,
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool avatarBusy = false;
  @override
  void initState() {
    super.initState();
    AvatarStore.instance
        .recover(Session.instance.user!['id'])
        .catchError((_) {});
  }

  Future<void> changeAvatar() async {
    if (avatarBusy) return;
    final userId = Session.instance.user!['id'] as String;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Đổi ảnh đại diện',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mở thư viện ảnh của thiết bị và chọn ảnh bạn muốn dùng. Trình chọn ảnh hệ thống sẽ cấp quyền cho ảnh bạn chọn. Ảnh đại diện được lưu trên thiết bị này.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'choose'),
                icon: const RcIcon(RcIcons.imageAdd),
                label: const Text('Chọn từ thư viện'),
              ),
              if (AvatarStore.instance.file(userId) != null)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'remove'),
                  child: const Text('Xóa ảnh đại diện'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    setState(() => avatarBusy = true);
    try {
      if (action == 'remove') {
        await AvatarStore.instance.remove(userId);
      } else {
        final selected = await AvatarStore.instance.choose(userId);
        if (selected && mounted) {
          toast(context, 'Đã cập nhật ảnh đại diện trên thiết bị này.');
        }
      }
    } catch (e) {
      if (mounted) {
        toast(
          context,
          'Không chọn được ảnh. Kiểm tra quyền Ảnh/Thư viện trong Cài đặt và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => avatarBusy = false);
    }
  }

  Future<void> profile() async {
    final s = Session.instance;
    final data = await editor(context, 'Chỉnh sửa hồ sơ', [
      const Field('name', 'Họ tên'),
      const Field('studentCode', 'Mã sinh viên', required: false),
    ], initial: s.user!);
    if (data == null || !mounted) return;
    try {
      await Api.instance.call('PUT', 'profile', data: data);
      await s.restore();
    } catch (e) {
      if (mounted) {
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Session.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tài khoản',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            children: [
              InkWell(
                onTap: avatarBusy ? null : changeAvatar,
                borderRadius: BorderRadius.circular(50),
                child: Stack(
                  children: [
                    UserAvatar(
                      userId: s.user!['id'],
                      name: s.user!['name'],
                      size: 88,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: RcIcon(
                          avatarBusy ? RcIcons.refresh : RcIcons.edit_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                          autoContrast: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: avatarBusy ? null : changeAvatar,
                child: Text(
                  avatarBusy ? 'Đang xử lý ảnh…' : 'Đổi ảnh đại diện',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.user!['name'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Tag(roleLabel(s.role)),
              const SizedBox(height: 16),
              Text(
                s.user!['email'],
                style: TextStyle(color: muted(context), fontSize: 14),
              ),
              if ((s.user!['studentCode'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'MSSV: ${s.user!['studentCode']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const RcIcon(
                    RcIcons.edit_rounded,
                    color: teal,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: RcIcon(
                  RcIcons.arrow_forward_ios_rounded,
                  size: 15,
                  color: muted(context),
                ),
                onTap: profile,
              ),
              Divider(
                height: 1,
                indent: 64,
                color: isDark ? darkBorder : const Color(0xfff1f5f9),
              ),
              // Chế độ giao diện (Dark / Light)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RcIcon(
                    isDark
                        ? RcIcons.dark_mode_rounded
                        : RcIcons.light_mode_rounded,
                    color: gold,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Giao diện Sáng / Tối',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isDark
                      ? 'Đang bật chế độ Tối (Dark mode)'
                      : 'Đang bật chế độ Sáng (Light mode)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const ThemeToggleButton(),
              ),
              ListTile(
                leading: const RcIcon(RcIcons.settings, size: 20),
                title: const Text(
                  'Cài đặt ứng dụng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Cỡ chữ, màu nền, khuôn mặt / vân tay'),
                trailing: const RcIcon(RcIcons.chevron_right, size: 18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      onEditProfile: profile,
                      onEditAvatar: changeAvatar,
                    ),
                  ),
                ),
              ),
              if (s.admin) ...[
                Divider(
                  height: 1,
                  indent: 64,
                  color: isDark ? darkBorder : const Color(0xfff1f5f9),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffb2d5e5).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const RcIcon(
                      RcIcons.manage_accounts_rounded,
                      color: Color(0xffb2d5e5),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Quản trị tài khoản',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: RcIcon(
                    RcIcons.arrow_forward_ios_rounded,
                    size: 15,
                    color: muted(context),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeopleScreen()),
                  ),
                ),
              ],
              Divider(
                height: 1,
                indent: 64,
                color: isDark ? darkBorder : const Color(0xfff1f5f9),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: muted(context).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RcIcon(
                    RcIcons.privacy_tip_rounded,
                    color: muted(context),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Quyền riêng tư',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: RcIcon(
                  RcIcons.arrow_forward_ios_rounded,
                  size: 15,
                  color: muted(context),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    title: const Text(
                      'Dữ liệu của bạn',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    content: const Text(
                      'Vị trí chỉ được gửi khi bạn bấm xác nhận điểm danh. Dữ liệu chuyển động được xử lý trên thiết bị, không gửi lên máy chủ. Giảng viên chỉ xem sinh viên trong lớp phụ trách. Mật khẩu được băm; phiên đăng nhập lưu trong kho bảo mật của thiết bị.',
                      style: TextStyle(height: 1.5),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Đã hiểu'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff6b3747),
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: const Color(0xfff7edf0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => s.logout(),
          icon: const RcIcon(
            RcIcons.logout_rounded,
            size: 20,
            color: Color(0xfff7edf0),
            autoContrast: false,
          ),
          label: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'TRƯƠNG TUẤN VĨNH · 2380602577\nNHÓM 4 CON MÈO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted(context),
            fontSize: 12,
            height: 1.8,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<JsonMap> people = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await Api.instance.list('users');
      if (mounted) {
        setState(() {
          people = rows;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> role(JsonMap u) async {
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Vai trò của ${u['name']}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        children: [
          for (final r in ['student', 'teacher', 'admin'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  roleLabel(r),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    try {
      await Api.instance.call('PUT', 'users/${u['id']}', data: {'role': value});
      await load();
    } catch (e) {
      if (mounted) {
        toast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Quản trị tài khoản',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator(color: teal))
        : error != null
        ? Empty('Không tải được', error!, retry: load)
        : RefreshIndicator(
            color: teal,
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: people
                  .map(
                    (u) => Panel(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: teal.withValues(alpha: .15),
                          child: Text(
                            (u['name'] as String).characters.first,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          u['name'],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${u['email']}\n${roleLabel(u['role'])} · ${u['verified'] == 1 ? 'Đã xác thực' : 'Chưa xác thực'}',
                          style: const TextStyle(height: 1.4),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (v) async {
                            if (v == 'role') {
                              await role(u);
                            } else if (await confirm(
                              context,
                              'Xóa tài khoản?',
                              'Các phiên đăng nhập và dữ liệu liên quan sẽ bị xóa.',
                            )) {
                              try {
                                await Api.instance.call(
                                  'DELETE',
                                  'users/${u['id']}',
                                );
                                await load();
                              } catch (e) {
                                if (mounted) {
                                  toast(this.context, e.toString());
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'role',
                              child: Text('Đổi vai trò'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Xóa tài khoản',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
  );
}
