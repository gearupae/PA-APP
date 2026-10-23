import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages'),
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.seed,
              unselectedLabelColor: AppColors.slate,
              indicatorColor: AppColors.seed,
              tabs: [
                Tab(text: 'Important (${state.importantMessages.length})'),
                Tab(text: 'All (${state.messages.length})'),
              ],
            ),
          ),
          body: !state.smsGranted
              ? _permission(state)
              : state.loadingSms
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _list(state.importantMessages, important: true),
                        _list(state.messages),
                      ],
                    ),
        );
      },
    );
  }

  Widget _permission(AppState state) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sms_outlined, size: 56, color: AppColors.slate),
              const SizedBox(height: 16),
              const Text('See your messages here',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Allow SMS access to view messages and auto-flag important ones like bills, OTPs and appointments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.requestSmsPermission,
                child: const Text('Allow SMS access'),
              ),
            ],
          ),
        ),
      );

  Widget _list(List<SmsItem> items, {bool important = false}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          important ? 'No important messages right now.' : 'No messages.',
          style: TextStyle(color: AppColors.slate),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _tile(items[i], important),
    );
  }

  Widget _tile(SmsItem m, bool important) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (important ? AppColors.amber : AppColors.seed)
                .withValues(alpha: 0.14),
            child: Icon(
              important ? Icons.priority_high : Icons.sms_outlined,
              color: important ? AppColors.amber : AppColors.seed,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(m.address.isEmpty ? 'Unknown' : m.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(timeAgo(m.date),
                  style: TextStyle(fontSize: 11, color: AppColors.slate)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child:
                Text(m.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          isThreeLine: true,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.address.isEmpty ? 'Unknown' : m.address,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(dayMonthTime(m.date),
                        style: TextStyle(color: AppColors.slate, fontSize: 12)),
                    const SizedBox(height: 16),
                    Text(m.body, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
