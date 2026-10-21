import 'package:flutter/material.dart';

import 'important_inbox_screen.dart';
import 'inbox_screen.dart';
import 'record_screen.dart';
import 'reminders_screen.dart';
import 'subscriptions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PA-APP')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hello — authenticated shell (Phase 0)'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const InboxScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.inbox),
              label: const Text('Mail inbox'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ImportantInboxScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.priority_high),
              label: const Text('Important mail'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.subscriptions_outlined),
              label: const Text('Subscriptions'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RemindersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Reminders'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecordScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.mic),
              label: const Text('Record conversation'),
            ),
          ],
        ),
      ),
    );
  }
}
