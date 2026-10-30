/// Wire format issued by the existing API; independent of the app display name.
({String sessionId, String token})? parseAttendanceQr(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 3 ||
      parts[0] != 'catcheck' ||
      parts[1].isEmpty ||
      parts[2].isEmpty) {
    return null;
  }
  return (sessionId: parts[1], token: parts[2]);
}
