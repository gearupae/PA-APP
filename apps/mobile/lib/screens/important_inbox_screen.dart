import 'package:flutter/material.dart';

import '../services/mail_api.dart';
import 'message_detail_screen.dart';

class ImportantInboxScreen extends StatefulWidget {
  const ImportantInboxScreen({super.key, this.mailApi});

  final MailApi? mailApi;

  @override
  State<ImportantInboxScreen> createState() => _ImportantInboxScreenState();
}

class _ImportantInboxScreenState extends State<ImportantInboxScreen> {
  late final MailApi _api = widget.mailApi ?? MailApi();
  List<MailMessage> _messages = [];
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
      final rows = await _api.listMessages(importantOnly: true);
      if (!mounted) return;
      setState(() => _messages = rows);
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No important messages yet. Connect mail and sync — '
                          'heuristics flag urgent senders, keywords, and provider labels.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          return ListTile(
                            leading: Icon(
                              Icons.priority_high,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              m.subject.isEmpty ? '(no subject)' : m.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${m.fromAddress}\nScore: ${m.importanceScore?.toStringAsFixed(2) ?? "—"}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => MessageDetailScreen(
                                    messageId: m.id,
                                    mailApi: _api,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
