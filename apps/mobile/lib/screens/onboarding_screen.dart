import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/local_store.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Minimal setup: grant permissions and acknowledge recording. No fluff.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    required this.store,
    required this.onDone,
  });

  final AppState state;
  final LocalStore store;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _sms = false;
  bool _mic = false;
  bool _notif = false;
  bool _consent = false;

  Future<void> _finish() async {
    await widget.store.setOnboarded(true);
    await widget.store.setRecordingConsent(_consent);
    await widget.state.bootstrap();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _perm(
            Icons.sms_outlined,
            'SMS',
            'Track spending and dues from bank messages.',
            _sms,
            () async {
              final s = await Permission.sms.request();
              setState(() => _sms = s.isGranted);
            },
          ),
          _perm(
            Icons.mic_none,
            'Microphone',
            'Record voice notes and meetings.',
            _mic,
            () async {
              final s = await Permission.microphone.request();
              setState(() => _mic = s.isGranted);
            },
          ),
          _perm(
            Icons.notifications_none,
            'Notifications',
            'Remind you about payments and meetings.',
            _notif,
            () async {
              final s = await Permission.notification.request();
              setState(() => _notif = s.isGranted);
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I consent to on-device recording and will get consent before recording others.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _finish, child: const Text('Start')),
        ],
      ),
    );
  }

  Widget _perm(IconData icon, String title, String subtitle, bool granted,
          VoidCallback onTap) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(icon, color: AppColors.ink),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: granted
              ? const Icon(Icons.check_circle, color: AppColors.income)
              : TextButton(onPressed: onTap, child: const Text('Allow')),
          onTap: granted ? null : onTap,
        ),
      );
}
