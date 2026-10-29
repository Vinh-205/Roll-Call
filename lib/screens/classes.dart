import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/ui.dart';
import 'home.dart';
import 'attendance.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<JsonMap> rows = [];
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
      final value = await Api.instance.list('courses');
      if (mounted) setState(() => rows = value);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    final staff = Session.instance.staff;
    final value = await editor(
      context,
      staff ? 'Tạo lớp học' : 'Tham gia lớp',
      staff
          ? [
              const Field('code', 'Mã lớp, ví dụ LTDD-4M'),
              const Field('name', 'Tên học phần'),
              const Field('room', 'Phòng học'),
            ]
          : [const Field('code', 'Mã lớp do giảng viên cung cấp')],
    );
    if (value == null || !mounted) return;
    try {
      await Api.instance.call(
        'POST',
        staff ? 'courses' : 'courses/join',
        data: value,
      );
      await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lớp học của bạn'),
      actions: [
        IconButton(
          onPressed: load,
          icon: const RcIcon(RcIcons.refresh),
          tooltip: 'Tải lại',
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Empty('Không tải được lớp', error!, retry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                const Text(
                  'Mỗi lớp học là một hành trình.',
                  style: TextStyle(color: Color(0xff778399)),
                ),
                const SizedBox(height: 20),
                if (rows.isEmpty)
                  const Empty(
                    'Chưa có lớp học',
                    'Bấm nút bên dưới để bắt đầu.',
                  ),
                ...rows.map(
                  (r) => Panel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: const CircleAvatar(
                        backgroundColor: ink,
                        child: RcIcon(RcIcons.school_outlined, color: gold),
                      ),
                      title: Text(
                        r['name'],
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${r['code']} · ${r['room']}\n${r['teacher_name']}',
                      ),
                      isThreeLine: true,
                      trailing: const RcIcon(RcIcons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassScreen(course: r),
                        ),
                      ).then((_) => load()),
                    ),
                  ),
                ),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const RcIcon(RcIcons.add),
      label: Text(Session.instance.staff ? 'Tạo lớp' : 'Tham gia lớp'),
    ),
  );
}

class ClassScreen extends StatefulWidget {
  final JsonMap course;
  const ClassScreen({super.key, required this.course});
  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  late JsonMap course = Map.of(widget.course);
  List<JsonMap> sessions = [], members = [];
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
      final all = await Api.instance.list('sessions');
      final m = Session.instance.staff
          ? await Api.instance.list('courses/${course['id']}/members')
          : <JsonMap>[];
      if (mounted) {
        setState(() {
          sessions = all.where((s) => s['course_id'] == course['id']).toList();
          members = m;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createSession() async {
    final data = await showDialog<JsonMap>(
      context: context,
      builder: (_) => const SessionEditor(),
    );
    if (data == null || !mounted) return;
    try {
      await Api.instance.call(
        'POST',
        'sessions',
        data: {...data, 'courseId': course['id']},
      );
      await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  Future<void> editClass() async {
    final data = await editor(context, 'Sửa lớp học', [
      const Field('name', 'Tên học phần'),
      const Field('room', 'Phòng học'),
    ], initial: course);
    if (data == null || !mounted) return;
    try {
      await Api.instance.call('PUT', 'courses/${course['id']}', data: data);
      setState(() => course = {...course, ...data});
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  Future<void> addMember() async {
    final data = await editor(context, 'Thêm sinh viên', [
      const Field('username', 'Tên đăng nhập hoặc email'),
    ]);
    if (data == null || !mounted) return;
    try {
      await Api.instance.call(
        'POST',
        'courses/${course['id']}/members',
        data: data,
      );
      await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = Session.instance.staff;
    return Scaffold(
      appBar: AppBar(
        title: Text(course['code']),
        actions: [
          if (staff)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await editClass();
                } else if (await confirm(
                  context,
                  'Xóa lớp học?',
                  'Các buổi học, điểm danh và giải trình của lớp sẽ bị xóa.',
                )) {
                  try {
                    await Api.instance.call(
                      'DELETE',
                      'courses/${course['id']}',
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) toast(context, e.toString());
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa lớp')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa lớp')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(course['code']),
                  const SizedBox(height: 16),
                  Text(
                    course['name'],
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${course['room']} · ${course['teacher_name']}',
                    style: const TextStyle(color: Color(0xff778399)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Các buổi học',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Empty('Chưa tải được', error!, retry: load)
            else ...[
              if (sessions.isEmpty)
                const Empty(
                  'Chưa có buổi học',
                  'Giảng viên sẽ tạo lịch và mở QR tại đây.',
                ),
              ...sessions.map(
                (s) => SessionTile(
                  row: {
                    ...s,
                    'course_name': course['name'],
                    'room': course['room'],
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionScreen(
                        session: {
                          ...s,
                          'course_name': course['name'],
                          'room': course['room'],
                        },
                      ),
                    ),
                  ).then((_) => load()),
                ),
              ),
              if (staff) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Sinh viên (${members.length})',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Thêm sinh viên',
                      onPressed: addMember,
                      icon: const RcIcon(RcIcons.person_add_alt),
                    ),
                  ],
                ),
                ...members.map(
                  (m) => Panel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(m['name']),
                      subtitle: Text(m['student_code'] ?? m['username']),
                      trailing: IconButton(
                        icon: const RcIcon(RcIcons.person_remove_outlined),
                        onPressed: () async {
                          if (await confirm(
                            context,
                            'Xóa khỏi lớp?',
                            'Sinh viên không còn truy cập lớp này.',
                          )) {
                            try {
                              await Api.instance.call(
                                'DELETE',
                                'courses/${course['id']}/members/${m['id']}',
                              );
                              await load();
                            } catch (e) {
                              if (context.mounted) toast(context, e.toString());
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: staff
          ? FloatingActionButton.extended(
              onPressed: createSession,
              icon: const RcIcon(RcIcons.add),
              label: const Text('Tạo buổi học'),
            )
          : null,
    );
  }
}

class SessionEditor extends StatefulWidget {
  final JsonMap? initial;
  const SessionEditor({super.key, this.initial});
  @override
  State<SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<SessionEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(
    text: widget.initial?['title'] ?? '',
  );
  late final radius = TextEditingController(
    text: (widget.initial?['radius'] ?? 150).toString(),
  );
  late final late = TextEditingController(
    text: (widget.initial?['late_minutes'] ?? 15).toString(),
  );
  late DateTime start = widget.initial == null
      ? DateTime.now()
      : DateTime.fromMillisecondsSinceEpoch(widget.initial!['starts']);
  late DateTime end = widget.initial == null
      ? DateTime.now().add(const Duration(minutes: 90))
      : DateTime.fromMillisecondsSinceEpoch(widget.initial!['ends']);
  Position? location;
  bool locating = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    radius.dispose();
    late.dispose();
    super.dispose();
  }

  Future<void> choose(bool first) async {
    final selected = first ? start : end;
    final day = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2026),
      lastDate: DateTime(2035),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selected),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (first) {
        start = value;
        if (!end.isAfter(start)) end = start.add(const Duration(minutes: 90));
      } else {
        end = value;
      }
    });
  }

  Future<void> locate() async {
    setState(() {
      locating = true;
      error = null;
    });
    try {
      final p = await getLocation();
      if (mounted) setState(() => location = p);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Tạo buổi học' : 'Sửa buổi học'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tên buổi học'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nhập tên buổi học' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bắt đầu'),
                subtitle: Text(when(start.millisecondsSinceEpoch)),
                trailing: const RcIcon(RcIcons.edit_calendar),
                onTap: () => choose(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kết thúc'),
                subtitle: Text(when(end.millisecondsSinceEpoch)),
                trailing: const RcIcon(RcIcons.edit_calendar),
                onTap: () => choose(false),
              ),
              TextFormField(
                controller: late,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cho phép đúng giờ trong (phút)',
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ||
                        int.parse(v!) < 0 ||
                        int.parse(v) > 180
                    ? 'Từ 0 đến 180 phút'
                    : null,
              ),
              if (widget.initial == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: radius,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bán kính lớp (30–2000 m)',
                  ),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ||
                          int.parse(v!) < 30 ||
                          int.parse(v) > 2000
                      ? 'Từ 30 đến 2000 m'
                      : null,
                ),
                TextButton.icon(
                  onPressed: locating ? null : locate,
                  icon: const RcIcon(RcIcons.my_location),
                  label: Text(
                    locating
                        ? 'Đang lấy vị trí...'
                        : location == null
                        ? 'Đặt vị trí lớp tại đây'
                        : 'Đã xác định vị trí lớp',
                  ),
                ),
                Text(
                  location == null
                      ? 'Chưa đặt vị trí: QR vẫn hoạt động, vị trí sinh viên vẫn được ghi nhận.'
                      : 'Bán kính được kiểm tra tại máy chủ.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff778399),
                  ),
                ),
              ],
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
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
        onPressed: locating
            ? null
            : () {
                if (!form.currentState!.validate()) return;
                if (!end.isAfter(start) ||
                    end.difference(start) > const Duration(hours: 24)) {
                  setState(
                    () => error = 'Buổi học phải kết thúc sau khi bắt đầu và không quá 24 giờ.',
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': title.text.trim(),
                  'starts': start.millisecondsSinceEpoch,
                  'ends': end.millisecondsSinceEpoch,
                  'lateMinutes': int.parse(late.text),
                  if (widget.initial == null) ...{
                    'radius': int.parse(radius.text),
                    'lat': location?.latitude,
                    'lng': location?.longitude,
                  },
                });
              },
        child: const Text('Lưu buổi học'),
      ),
    ],
  );
}

Future<Position> getLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw ApiError('Vui lòng bật dịch vụ vị trí trên điện thoại.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw ApiError(
      'Cần quyền vị trí để xác nhận điểm danh. Bạn có thể cấp quyền trong Cài đặt.',
    );
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  if (p.isMocked) {
    throw ApiError('Vị trí giả lập không dùng để điểm danh thật.');
  }
  if (p.accuracy > 100) {
    throw ApiError(
      'Vị trí chưa đủ chính xác. Hãy đến nơi có tín hiệu tốt hơn hoặc gửi giải trình.',
    );
  }
  return p;
}
