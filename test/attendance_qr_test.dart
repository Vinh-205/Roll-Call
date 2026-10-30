import 'package:flutter_test/flutter_test.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/attendance_qr.dart';

void main() {
  test('Accepts the existing backend QR format after app rebranding', () {
    final payload = parseAttendanceQr('catcheck:session-123:token_ABC-456');
    expect(payload?.sessionId, 'session-123');
    expect(payload?.token, 'token_ABC-456');
  });
  test('Rejects unrelated QR, missing fields and malformed payloads', () {
    for (final value in [
      '',
      'https://example.com',
      'other:session:token',
      'catcheck::token',
      'catcheck:session:',
      'catcheck:session:token:extra',
    ]) {
      expect(parseAttendanceQr(value), isNull, reason: value);
    }
  });
}
