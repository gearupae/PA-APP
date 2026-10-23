import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class MailApiException implements Exception {
  MailApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ConnectedAccount {
  ConnectedAccount({
    required this.id,
    required this.provider,
    this.emailAddress,
    required this.createdAt,
  });

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) {
    return ConnectedAccount(
      id: json['id'] as String,
      provider: json['provider'] as String,
      emailAddress: json['email_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String provider;
  final String? emailAddress;
  final DateTime createdAt;
}

class MailMessage {
  MailMessage({
    required this.id,
    required this.accountId,
    required this.provider,
    required this.fromAddress,
    required this.subject,
    required this.snippet,
    required this.receivedAt,
    this.labels = const [],
    this.isRead = false,
    this.bodyText,
    this.importanceScore,
    this.isImportant = false,
    this.importanceFlags = const [],
  });

  factory MailMessage.fromJson(Map<String, dynamic> json) {
    return MailMessage(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      provider: json['provider'] as String,
      fromAddress: json['from_address'] as String,
      subject: json['subject'] as String,
      snippet: json['snippet'] as String,
      receivedAt: DateTime.parse(json['received_at'] as String),
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isRead: json['is_read'] as bool? ?? false,
      bodyText: json['body_text'] as String?,
      importanceScore: (json['importance_score'] as num?)?.toDouble(),
      isImportant: json['is_important'] as bool? ?? false,
      importanceFlags: (json['importance_flags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  final String id;
  final String accountId;
  final String provider;
  final String fromAddress;
  final String subject;
  final String snippet;
  final DateTime receivedAt;
  final List<String> labels;
  final bool isRead;
  final String? bodyText;
  final double? importanceScore;
  final bool isImportant;
  final List<String> importanceFlags;
}

class OAuthConnectResult {
  OAuthConnectResult({
    required this.provider,
    required this.authorizationUrl,
    required this.state,
  });

  factory OAuthConnectResult.fromJson(Map<String, dynamic> json) {
    return OAuthConnectResult(
      provider: json['provider'] as String,
      authorizationUrl: json['authorization_url'] as String,
      state: json['state'] as String,
    );
  }

  final String provider;
  final String authorizationUrl;
  final String state;
}

class MailApi {
  MailApi({http.Client? client, String? accessToken, String? baseUrl})
      : _client = client ?? http.Client(),
        _token = accessToken ?? ApiConfig.accessToken,
        _base = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _token;
  final String _base;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<List<ConnectedAccount>> listAccounts() async {
    final res = await _client.get(
      Uri.parse('$_base/mail/accounts'),
      headers: _headers,
    );
    _ensureOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ConnectedAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OAuthConnectResult> connectGmail() async {
    final res = await _client.post(
      Uri.parse('$_base/mail/accounts/connect/gmail'),
      headers: _headers,
    );
    _ensureOk(res);
    return OAuthConnectResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<OAuthConnectResult> connectOutlook() async {
    final res = await _client.post(
      Uri.parse('$_base/mail/accounts/connect/outlook'),
      headers: _headers,
    );
    _ensureOk(res);
    return OAuthConnectResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<ConnectedAccount> connectImap({
    required String host,
    required String username,
    required String password,
    int port = 993,
    bool useSsl = true,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/mail/accounts/connect/imap'),
      headers: _headers,
      body: jsonEncode({
        'host': host,
        'username': username,
        'password': password,
        'port': port,
        'use_ssl': useSsl,
      }),
    );
    _ensureOk(res);
    return ConnectedAccount.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> disconnectAccount(String accountId) async {
    final res = await _client.delete(
      Uri.parse('$_base/mail/accounts/$accountId'),
      headers: _headers,
    );
    if (res.statusCode != 204) {
      _ensureOk(res);
    }
  }

  Future<List<MailMessage>> listMessages({bool importantOnly = false}) async {
    final uri = Uri.parse('$_base/mail/messages').replace(
      queryParameters: importantOnly ? {'important': 'true'} : null,
    );
    final res = await _client.get(
      uri,
      headers: _headers,
    );
    _ensureOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => MailMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MailMessage> getMessage(String messageId) async {
    final res = await _client.get(
      Uri.parse('$_base/mail/messages/$messageId'),
      headers: _headers,
    );
    _ensureOk(res);
    return MailMessage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
