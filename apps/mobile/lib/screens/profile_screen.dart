import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/mail_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'connect_account_screen.dart';
import 'travel_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onSignedOut});
  final AppState state;
  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    final name = state.store.userName;
    final email = state.store.authEmail;
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
                      Text(name.isEmpty ? 'Account' : name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text(email.isEmpty ? 'Offline' : email,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _PermStatusTile(
                    icon: Icons.sms_outlined,
                    title: 'SMS',
                    perm: Permission.sms),
                _PermStatusTile(
                    icon: Icons.mic_none,
                    title: 'Microphone',
                    perm: Permission.microphone),
                _PermStatusTile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    perm: Permission.notification),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flight_outlined, color: AppColors.ink),
              title: const Text('Travel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trips, flights & per-trip spend'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => TravelScreen(state: state))),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.ink),
              title: const Text('Connect email',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(state.emailConnected
                  ? 'Connected · pulling reminders & subscriptions'
                  : 'Gmail, Outlook or IMAP (needs the server)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ConnectAccountScreen(
                          mailApi: MailApi(
                            baseUrl: state.store.apiBaseUrl,
                            accessToken: state.store.authToken,
                          ),
                        )));
                await state.loadEmail();
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.expense),
              title: const Text('Sign out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                await state.recorder.cancel();
                await state.store.signOut();
                onSignedOut();
              },
            ),
          ),
        ],
      ),
    );
  }
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
