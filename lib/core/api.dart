import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.vihx.online/api',
);
typedef JsonMap = Map<String, dynamic>;

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class Api {
  static final instance = Api();
  final http.Client client;
  String? token;
  Api({http.Client? client}) : client = client ?? http.Client();
  Future<dynamic> call(
    String method,
    String path, {
    JsonMap? data,
    bool auth = true,
  }) async {
    final req = http.Request(method, Uri.parse('$apiBase/$path'));
    req.headers['Content-Type'] = 'application/json';
    if (auth && token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    if (data != null) {
      req.body = jsonEncode(data);
    }
    try {
      final res = await client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 25));
      dynamic value;
      try {
        value = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        value = null;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return value;
      }
      if (res.statusCode == 401 && auth) {
        await Session.instance.clear();
      }
      throw ApiError(
        value is Map
            ? value['message']?.toString() ?? 'Không xử lý được yêu cầu.'
            : 'Máy chủ trả về lỗi ${res.statusCode}.',
        res.statusCode,
      );
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError(
        'Không kết nối được máy chủ. Kiểm tra internet và thử lại.',
      );
    }
  }

  Future<List<JsonMap>> list(String path) async =>
      List<JsonMap>.from(await call('GET', path) as List);
}

class Session extends ChangeNotifier {
  static final instance = Session();
  static const storage = FlutterSecureStorage();
  JsonMap? user;
  bool loading = true;
  String? error;
  String get role => user?['role'] ?? 'student';
  bool get staff => role != 'student';
  bool get admin => role == 'admin';
  Future<void> restore() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      Api.instance.token = await storage.read(key: 'catcheck_token');
      if (Api.instance.token != null) {
        user = JsonMap.from(await Api.instance.call('GET', 'auth/me') as Map);
      }
    } on ApiError catch (e) {
      if (e.status != 401) {
        error = e.message;
      }
    } catch (_) {
      error = 'Không đọc được phiên đăng nhập. Vui lòng thử lại.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> accept(JsonMap data) async {
    Api.instance.token = data['token'];
    await storage.write(key: 'catcheck_token', value: Api.instance.token);
    user = JsonMap.from(data['user'] as Map);
    error = null;
    loading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    Api.instance.token = null;
    user = null;
    error = null;
    loading = false;
    await storage.delete(key: 'catcheck_token');
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await Api.instance.call('POST', 'auth/logout', data: {});
    } catch (_) {}
    await clear();
  }
}
