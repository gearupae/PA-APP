import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'connect_account_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final name = state.store.userName;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: Text(
                    name.isEmpty ? '🙂' : name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Welcome' : name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const Text('Personal assistant',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _group('Email (beta)', [
            _tile(
              Icons.mark_email_read_outlined,
              'Connect Gmail / Outlook / IMAP',
              'Pulls reminders & important mail (needs the server).',
              () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ConnectAccountScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          _group('Permissions', [
            _PermStatusTile(
                icon: Icons.sms_outlined, title: 'SMS access', perm: Permission.sms),
            _PermStatusTile(
                icon: Icons.mic_none, title: 'Microphone', perm: Permission.microphone),
            _PermStatusTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                perm: Permission.notification),
          ]),
          const SizedBox(height: 16),
          _group('About', [
            _tile(Icons.privacy_tip_outlined, 'Your data stays on device',
                'SMS, notes and reminders never leave your phone.', null),
            _tile(Icons.info_outline, 'Call recording',
                'Not available — modern Android blocks third-party call recording.',
                null),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.slate)),
          ),
          Card(child: Column(children: children)),
        ],
      );

  Widget _tile(IconData icon, String title, String subtitle,
          VoidCallback? onTap) =>
      ListTile(
        leading: Icon(icon, color: AppColors.ink),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _PermStatusTile extends StatefulWidget {
  const _PermStatusTile(
      {required this.icon, required this.title, required this.perm});
  final IconData icon;
  final String title;
  final Permission perm;

  @override
  State<_PermStatusTile> createState() => _PermStatusTileState();
}

class _PermStatusTileState extends State<_PermStatusTile> {
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    widget.perm.isGranted.then((v) {
      if (mounted) setState(() => _granted = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: AppColors.ink),
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: _granted
          ? const Icon(Icons.check_circle, color: AppColors.income)
          : TextButton(
              onPressed: () async {
                final s = await widget.perm.request();
                if (mounted) setState(() => _granted = s.isGranted);
              },
              child: const Text('Allow'),
            ),
    );
  }
}
