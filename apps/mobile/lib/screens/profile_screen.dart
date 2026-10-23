import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

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
