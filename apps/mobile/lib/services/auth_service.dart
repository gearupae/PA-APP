import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_store.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the backend /auth endpoints (single shared DB) and stores the
/// resulting token + identity locally.
class AuthService {
  AuthService(this.store, {http.Client? client})
      : _client = client ?? http.Client();

  final LocalStore store;
  final http.Client _client;

  Uri _uri(String path) {
    final base = store.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _post('/auth/login', {'email': email, 'password': password});
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    http.Response res;
    try {
      res = await _client
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw AuthException(
          'Could not reach the server. Check the server URL or your connection.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await store.setAuthToken(data['access_token'] as String? ?? '');
      await store.setAuthEmail(data['email'] as String? ?? '');
      final name = (data['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) await store.setUserName(name);
      await store.setOfflineMode(false);
      return;
    }
    String detail = 'Something went wrong (${res.statusCode}).';
    try {
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      detail = parsed['detail']?.toString() ?? detail;
    } catch (_) {}
    throw AuthException(detail);
  }
}
