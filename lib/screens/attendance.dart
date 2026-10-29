import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/ui.dart';
import 'classes.dart';

class SessionScreen extends StatefulWidget {
  final JsonMap session;
  const SessionScreen({super.key, required this.session});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late JsonMap session = Map.of(widget.session);
  JsonMap? qr;
  List<JsonMap> roster = [];
  bool busy = false;
  String? error;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    if (Session.instance.staff) {
      refresh();
      timer = Timer.periodic(const Duration(seconds: 50), (_) => refresh());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final code = await Api.instance.call(
        'GET',
        'sessions/${session['id']}/qr',
      );
      final rows = await Api.instance.list(
        'sessions/${session['id']}/attendance',
      );
      if (mounted) {
        setState(() {
          qr = JsonMap.from(code as Map);
          roster = rows;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> explain() async {
    final value = await editor(context, 'Gửi giải trình', [
      const Field(
        'message',
        'Lý do và thông tin muốn giảng viên biết',
        lines: 4,
      ),
    ]);
    if (value == null || !mounted) return;
    try {
      await Api.instance.call(
        'POST',
        'explanations',
        data: {...value, 'sessionId': session['id']},
      );
      if (mounted) {
        toast(context, 'Đã gửi giải trình. Theo dõi kết quả trong Lịch sử.');
      }
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  Future<void> action(String value) async {
    try {
      if (value == 'edit') {
        final data = await showDialog<JsonMap>(
          context: context,
          builder: (_) => SessionEditor(initial: session),
        );
        if (data == null) return;
        await Api.instance.call('PUT', 'sessions/${session['id']}', data: data);
        if (mounted) setState(() => session = {...session, ...data});
      } else if (value == 'toggle') {
        await Api.instance.call(
          'PUT',
          'sessions/${session['id']}',
          data: {'closed': session['closed'] != 1},
        );
        if (mounted) {
          setState(() => session['closed'] = session['closed'] == 1 ? 0 : 1);
        }
      } else if (await confirm(
        context,
        'Xóa buổi học?',
        'Các bản ghi điểm danh và giải trình của buổi này sẽ bị xóa.',
      )) {
        await Api.instance.call('DELETE', 'sessions/${session['id']}');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = Session.instance.staff;
    final count = roster.where((r) => r['status'] != null).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết buổi học'),
        actions: [
          if (staff)
            PopupMenuButton<String>(
              onSelected: action,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa lịch học')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    session['closed'] == 1
                        ? 'Mở lại điểm danh'
                        : 'Đóng điểm danh',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa buổi học'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  session['closed'] == 1 ? 'ĐÃ ĐÓNG' : 'BUỔI HỌC',
                  color: session['closed'] == 1 ? Colors.grey : teal,
                ),
                const SizedBox(height: 16),
                Text(
                  session['title'],
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${session['course_name'] ?? ''}\n${when(session['starts'])} → ${when(session['ends'])}',
                  style: const TextStyle(color: Color(0xff778399), height: 1.7),
                ),
                const SizedBox(height: 10),
                Text(
                  session['lat'] == null
                      ? 'Vị trí được ghi nhận khi xác nhận.'
                      : 'Phạm vi điểm danh: ${session['radius']} m',
                  style: const TextStyle(fontSize: 12, color: teal),
                ),
              ],
            ),
          ),
          if (staff) ...[
            if (error != null) Empty('Chưa mở được QR', error!, retry: refresh),
            Panel(
              child: Column(
                children: [
                  const Text(
                    'QR điểm danh có thời hạn',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (qr != null)
                    QrImageView(
                      data: qr!['qr'],
                      size: 250,
                      backgroundColor: Colors.white,
                    )
                  else
                    const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mã tự làm mới. Sinh viên cần ở trong phạm vi lớp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff778399), fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : refresh,
                    icon: const RcIcon(RcIcons.refresh),
                    label: const Text('Đổi mã / tải danh sách'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đã ghi nhận $count / ${roster.length}',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (roster.isEmpty)
              const Empty(
                'Chưa có sinh viên',
                'Thêm sinh viên vào lớp để theo dõi.',
              ),
            ...roster.map(
              (r) => Panel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(r['name']),
                  subtitle: Text(
                    '${r['student_code'] ?? ''}\n${when(r['checked'])}',
                  ),
                  isThreeLine: true,
                  trailing: Tag(
                    statusLabel(r['status']),
                    color: r['status'] == 'late'
                        ? Colors.orange
                        : r['status'] == null
                        ? Colors.grey
                        : teal,
                  ),
                  onTap: r['lat'] == null
                      ? null
                      : () async {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${r['lat']},${r['lng']}',
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                ),
              ),
            ),
          ] else ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sẵn sàng điểm danh?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Quét QR của giảng viên. Ứng dụng sẽ hỏi quyền vị trí trước khi bạn xác nhận.',
                    style: TextStyle(color: Color(0xff778399), height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CheckinScreen(expectedSession: session['id']),
                        ),
                      ),
                      icon: const RcIcon(RcIcons.qr_code_scanner),
                      label: const Text('Quét mã điểm danh'),
                    ),
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Tag(
                    'ĐIỂM DANH CÓ GIẢI TRÌNH',
                    color: Color(0xff99661d),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Đến muộn, mất mạng hay cần được hỗ trợ?',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gửi lý do để giảng viên xem xét. Không tự ý đánh dấu bạn đã có mặt.',
                    style: TextStyle(color: Color(0xff778399), height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: explain,
                    icon: const RcIcon(RcIcons.edit_note),
                    label: const Text('Gửi giải trình'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CheckinScreen extends StatefulWidget {
  final String? expectedSession;
  const CheckinScreen({super.key, this.expectedSession});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final scanner = MobileScannerController();
  bool processing = false, done = false;
  String? error;
  String? result;
  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  Future<void> found(String? value) async {
    if (processing || done || value == null) return;
    final parts = value.split(':');
    if (parts.length != 3 || parts[0] != 'Roll call') {
      setState(() => error = 'Đây không phải mã QR CatCheck.');
      return;
    }
    if (widget.expectedSession != null && parts[1] != widget.expectedSession) {
      setState(() => error = 'QR không thuộc buổi học đang chọn.');
      return;
    }
    setState(() {
      processing = true;
      error = null;
    });
    await scanner.stop();
    try {
      if (!mounted) return;
      final yes = await confirm(
        context,
        'Chia sẻ vị trí để điểm danh?',
        'Chỉ gửi vị trí hiện tại và độ chính xác cho giảng viên của lớp. Không theo dõi nền.',
      );
      if (!yes) return;
      final p = await getLocation();
      final response = await Api.instance.call(
        'POST',
        'sessions/${parts[1]}/checkin',
        data: {
          'qrToken': parts[2],
          'lat': p.latitude,
          'lng': p.longitude,
          'accuracy': p.accuracy,
        },
      );
      if (mounted) {
        setState(() {
          done = true;
          result = statusLabel(response['status']);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => processing = false);
        if (!done) await scanner.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét QR điểm danh')),
    body: done
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RcIcon(
                    RcIcons.check_circle_rounded,
                    color: teal,
                    size: 88,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bạn đã có mặt!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(result ?? ''),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hoàn tất'),
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: MobileScanner(
                      controller: scanner,
                      onDetect: (capture) {
                        if (capture.barcodes.isNotEmpty) {
                          found(capture.barcodes.first.rawValue);
                        }
                      },
                      errorBuilder: (context, error) => const Empty(
                        'Chưa mở được camera',
                        'Cấp quyền camera trong Cài đặt để quét QR.',
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Đặt mã QR của giảng viên trong khung hình.\nMã có thời hạn, không dùng ảnh chụp cũ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xff778399), height: 1.7),
                ),
              ),
              if (processing)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<JsonMap> history = [], explanations = [];
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
      final data = await Future.wait([
        Api.instance.list('history'),
        Api.instance.list('explanations'),
      ]);
      if (mounted) {
        setState(() {
          history = data[0];
          explanations = data[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit(JsonMap r) async {
    final value = await editor(context, 'Sửa giải trình', [
      const Field('message', 'Lý do', lines: 4),
    ], initial: r);
    if (value == null || !mounted) return;
    try {
      await Api.instance.call('PUT', 'explanations/${r['id']}', data: value);
      await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Dấu chân học tập',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mỗi lần có mặt, một bước tiến.',
          style: TextStyle(color: Color(0xff778399)),
        ),
        const SizedBox(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          Empty('Chưa tải được', error!, retry: load)
        else ...[
          if (history.isEmpty)
            const Empty(
              'Chưa có điểm danh',
              'Các buổi đã ghi nhận sẽ xuất hiện ở đây.',
            ),
          ...history.map(
            (r) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Tag(statusLabel(r['status'])),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${r['course_name']}\n${when(r['checked'])}',
                    style: const TextStyle(
                      color: Color(0xff778399),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Giải trình của tôi',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...explanations.map(
            (r) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['title'],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Tag(
                        statusLabel(r['status']),
                        color: r['status'] == 'pending' ? Colors.orange : teal,
                      ),
                      if (r['status'] == 'pending')
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await edit(r);
                            } else if (await confirm(
                              context,
                              'Xóa giải trình?',
                              'Chỉ giải trình chưa duyệt mới được xóa.',
                            )) {
                              try {
                                await Api.instance.call(
                                  'DELETE',
                                  'explanations/${r['id']}',
                                );
                                await load();
                              } catch (e) {
                                if (context.mounted) {
                                  toast(context, e.toString());
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(r['message']),
                  const SizedBox(height: 10),
                  Text(
                    'Đã gửi ${when(r['created'])}',
                    style: const TextStyle(
                      color: Color(0xff778399),
                      fontSize: 12,
                    ),
                  ),
                  if (r['review_note'] != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Phản hồi: ${r['review_note']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Đã xử lý ${when(r['reviewed'])}',
                      style: const TextStyle(
                        color: Color(0xff778399),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
