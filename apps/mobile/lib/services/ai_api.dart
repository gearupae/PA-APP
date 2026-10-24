import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_store.dart';

class AiAnalysis {
  AiAnalysis({
    required this.summary,
    required this.todos,
    required this.promises,
  });
  final String summary;
  final List<String> todos;
  final List<String> promises;
}

/// Calls the backend's GPT-backed /ai endpoints. All methods return null on
/// any failure so callers can fall back to on-device heuristics.
class AiApi {
  AiApi(this.store, {http.Client? client})
      : _client = client ?? http.Client();

  final LocalStore store;
  final http.Client _client;

  bool get enabled => store.authToken.isNotEmpty;

  Uri _uri(String path) {
    final base = store.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${store.authToken}',
      };

  Future<AiAnalysis?> analyze(String transcript) async {
    if (!enabled || transcript.trim().isEmpty) return null;
    try {
      final res = await _client
          .post(_uri('/ai/analyze'),
              headers: _headers, body: jsonEncode({'transcript': transcript}))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return AiAnalysis(
        summary: (j['summary'] as String?)?.trim() ?? '',
        todos: ((j['todos'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
        promises: ((j['promises'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> ask(String question, {String context = ''}) async {
    if (!enabled || question.trim().isEmpty) return null;
    try {
      final res = await _client
          .post(_uri('/ai/ask'),
              headers: _headers,
              body: jsonEncode({'question': question, 'context': context}))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        final detail = _detail(res.body);
        return detail == null ? null : 'Error: $detail';
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['answer'] as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  String? _detail(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['detail']?.toString();
    } catch (_) {
      return null;
    }
  }
}
