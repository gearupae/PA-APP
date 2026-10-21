import 'package:flutter/material.dart';

import '../services/mail_api.dart';

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({
    super.key,
    required this.messageId,
    this.mailApi,
  });

  final String messageId;
  final MailApi? mailApi;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  late final MailApi _api = widget.mailApi ?? MailApi();
  MailMessage? _message;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final msg = await _api.getMessage(widget.messageId);
      if (!mounted) return;
      setState(() => _message = msg);
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = _message;
    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : msg == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(msg.subject, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('From: ${msg.fromAddress}'),
                        Text('Provider: ${msg.provider}'),
                        Text('Received: ${msg.receivedAt.toLocal()}'),
                        if (msg.labels.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: msg.labels
                                .map((l) => Chip(label: Text(l), visualDensity: VisualDensity.compact))
                                .toList(),
                          ),
                        ],
                        const Divider(height: 32),
                        SelectableText(msg.bodyText ?? msg.snippet),
                      ],
                    ),
    );
  }
}
