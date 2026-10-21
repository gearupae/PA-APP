import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'mail_api.dart';

class DetectedSubscription {
  DetectedSubscription({
    required this.id,
    this.messageId,
    required this.kind,
    required this.title,
    required this.confidence,
    this.suggestedDueAt,
    this.snippetHint,
    required this.status,
    required this.createdAt,
  });

  factory DetectedSubscription.fromJson(Map<String, dynamic> json) {
    return DetectedSubscription(
      id: json['id'] as String,
      messageId: json['message_id'] as String?,
      kind: json['kind'] as String,
      title: json['title'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      suggestedDueAt: json['suggested_due_at'] != null
          ? DateTime.parse(json['suggested_due_at'] as String)
          : null,
      snippetHint: json['snippet_hint'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String? messageId;
  final String kind;
  final String title;
  final double confidence;
  final DateTime? suggestedDueAt;
  final String? snippetHint;
  final String status;
  final DateTime createdAt;
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.title,
    required this.dueAt,
    this.sourceDetectedId,
    this.sourceMessageId,
    required this.notifyEnabled,
    required this.notificationChannel,
    required this.status,
    required this.createdAt,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      title: json['title'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      sourceDetectedId: json['source_detected_id'] as String?,
      sourceMessageId: json['source_message_id'] as String?,
      notifyEnabled: json['notify_enabled'] as bool? ?? true,
      notificationChannel: json['notification_channel'] as String? ?? 'push',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String title;
  final DateTime dueAt;
  final String? sourceDetectedId;
  final String? sourceMessageId;
  final bool notifyEnabled;
  final String notificationChannel;
  final String status;
  final DateTime createdAt;
}

class SignalsApi {
  SignalsApi({http.Client? client, String? accessToken})
      : _client = client ?? http.Client(),
        _token = accessToken ?? ApiConfig.accessToken;

  final http.Client _client;
  final String _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<List<DetectedSubscription>> listSubscriptions({String? status}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/mail/subscriptions').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await _client.get(uri, headers: _headers);
    _ensureOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => DetectedSubscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DetectedSubscription> updateSubscriptionStatus(
    String id,
    String status,
  ) async {
    final res = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/mail/subscriptions/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    _ensureOk(res);
    return DetectedSubscription.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<List<ReminderItem>> listReminders() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/reminders'),
      headers: _headers,
    );
    _ensureOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderItem> createReminderFromDetected(String detectedId) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/reminders/from-detected/$detectedId'),
      headers: _headers,
      body: jsonEncode({}),
    );
    _ensureOk(res);
    return ReminderItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    var detail = res.body;
    try {
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      detail = parsed['detail']?.toString() ?? detail;
    } catch (_) {}
    throw MailApiException(detail, statusCode: res.statusCode);
  }
}
