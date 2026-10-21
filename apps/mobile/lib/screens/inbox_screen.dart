import 'package:flutter/material.dart';

import '../services/mail_api.dart';
import 'connect_account_screen.dart';
import 'message_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.mailApi});

  final MailApi? mailApi;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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
      final rows = await _api.listMessages();
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
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Connect account',
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ConnectAccountScreen(mailApi: _api),
                ),
              );
              await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No messages yet.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConnectAccountScreen(mailApi: _api),
                                ),
                              );
                            },
                            child: const Text('Connect an account'),
                          ),
                        ],
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
                            title: Text(
                              m.subject.isEmpty ? '(no subject)' : m.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${m.fromAddress}\n${m.snippet}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: m.isRead
                                ? null
                                : Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
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
