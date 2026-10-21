import 'package:flutter/material.dart';

import '../services/mail_api.dart';
import '../services/signals_api.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.signalsApi});

  final SignalsApi? signalsApi;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final SignalsApi _api = widget.signalsApi ?? SignalsApi();
  List<ReminderItem> _items = [];
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
      final rows = await _api.listReminders();
      if (!mounted) return;
      setState(() => _items = rows);
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
        title: const Text('Reminders'),
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
                          'No reminders yet. Confirm a subscription detection to schedule one.',
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
                          final r = _items[index];
                          return ListTile(
                            leading: const Icon(Icons.notifications_active_outlined),
                            title: Text(r.title),
                            subtitle: Text(
                              'Due ${r.dueAt.toLocal()}\n${r.status} · ${r.notificationChannel}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
    );
  }
}
