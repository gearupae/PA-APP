import 'package:flutter/material.dart';

import '../services/mail_api.dart';
import '../services/signals_api.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key, this.signalsApi});

  final SignalsApi? signalsApi;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late final SignalsApi _api = widget.signalsApi ?? SignalsApi();
  List<DetectedSubscription> _items = [];
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
      final rows = await _api.listSubscriptions(status: 'pending');
      if (!mounted) return;
      setState(() => _items = rows);
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(DetectedSubscription item) async {
    try {
      await _api.createReminderFromDetected(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder created from detection')),
      );
      await _load();
    } on MailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _dismiss(DetectedSubscription item) async {
    try {
      await _api.updateSubscriptionStatus(item.id, 'dismissed');
      await _load();
    } on MailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No pending subscription or renewal candidates.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Kind: ${item.kind} · ${(item.confidence * 100).toStringAsFixed(0)}%'),
                                  if (item.snippetHint != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.snippetHint!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      FilledButton(
                                        onPressed: () => _confirm(item),
                                        child: const Text('Create reminder'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _dismiss(item),
                                        child: const Text('Dismiss'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
