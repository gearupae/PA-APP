import 'package:flutter/material.dart';

import 'inbox_screen.dart';
import 'record_screen.dart';

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
