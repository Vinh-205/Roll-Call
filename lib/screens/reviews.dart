import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/ui.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
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
      final value = await Api.instance.list('explanations');
      if (mounted) setState(() => rows = value);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> review(JsonMap r, bool approve) async {
    final data = await editor(
      context,
      approve ? 'Chấp nhận giải trình' : 'Từ chối giải trình',
      [const Field('note', 'Phản hồi cho sinh viên', lines: 3)],
    );
    if (data == null || !mounted) return;
    try {
      await Api.instance.call(
        'PUT',
        'explanations/${r['id']}',
        data: {...data, 'status': approve ? 'approved' : 'rejected'},
      );
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
        const Tag('LẮNG NGHE · PHẢN HỒI · MINH BẠCH', color: Color(0xff99661d)),
        const SizedBox(height: 18),
        const Text(
          'Điểm danh\ncó giải trình.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Không chỉ đánh dấu vắng. Hiểu lý do và lưu lại quyết định của bạn.',
          style: TextStyle(color: Color(0xff778399), height: 1.6),
        ),
        const SizedBox(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          Empty('Không tải được', error!, retry: load)
        else if (rows.isEmpty)
          const Empty(
            'Chưa có giải trình',
            'Yêu cầu của sinh viên trong lớp sẽ xuất hiện tại đây.',
          )
        else
          ...rows.map(
            (r) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['student_name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Tag(
                        statusLabel(r['status']),
                        color: r['status'] == 'pending' ? Colors.orange : teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${r['course_name']} · ${r['title']}',
                    style: const TextStyle(
                      color: Color(0xff778399),
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 26),
                  Text(
                    r['message'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đã gửi ${when(r['created'])}',
                    style: const TextStyle(
                      color: Color(0xff778399),
                      fontSize: 12,
                    ),
                  ),
                  if (r['status'] == 'pending') ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => review(r, false),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => review(r, true),
                            child: const Text('Chấp nhận'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Divider(height: 26),
                    Text(
                      'Phản hồi: ${r['review_note']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Đã xử lý ${when(r['reviewed'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff778399),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
