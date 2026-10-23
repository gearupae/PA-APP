import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/local_store.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.state, required this.store});

  final AppState state;
  final LocalStore store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  bool _micGranted = false;
  bool _smsGranted = false;
  bool _notifGranted = false;
  bool _consent = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    await widget.store.setOnboarded(true);
    await widget.store.setUserName(_nameController.text.trim());
    await widget.store.setRecordingConsent(_consent);
    await widget.state.bootstrap();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => MainShell(state: widget.state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.seed
                            : AppColors.slate.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcome(),
                  _nameStep(),
                  _permissionsStep(),
                  _consentStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _page == 3 ? _finish : _next,
                  child: Text(_page == 3 ? 'Get started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 8), child: child);

  Widget _welcome() => _pad(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.seed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.seed, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Your personal assistant',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Track your money, catch important messages, set reminders, and turn conversations into clear notes — all in one calm place.',
              style: TextStyle(
                  fontSize: 16, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 24),
            _feature(Icons.pie_chart_outline, 'See where your money goes'),
            _feature(Icons.mark_email_unread_outlined,
                'Never miss an important message'),
            _feature(Icons.mic_none, 'Voice notes → todos & mind maps'),
          ],
        ),
      );

  Widget _feature(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.seed, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );

  Widget _nameStep() => _pad(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("What should we call you?",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Just so the app feels like yours.',
                style: TextStyle(fontSize: 15, color: AppColors.slate)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
      );

  Widget _permissionsStep() => _pad(
        ListView(
          children: [
            const SizedBox(height: 8),
            const Text('Allow a few things',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Everything stays on your phone. You can change these anytime in Settings.',
              style: TextStyle(fontSize: 15, color: AppColors.slate),
            ),
            const SizedBox(height: 20),
            _permTile(
              icon: Icons.sms_outlined,
              title: 'Read SMS',
              subtitle:
                  'To auto-detect bank spends and flag important messages.',
              granted: _smsGranted,
              onTap: () async {
                final s = await Permission.sms.request();
                setState(() => _smsGranted = s.isGranted);
              },
            ),
            _permTile(
              icon: Icons.mic_none,
              title: 'Microphone',
              subtitle: 'To record voice notes and transcribe them.',
              granted: _micGranted,
              onTap: () async {
                final s = await Permission.microphone.request();
                setState(() => _micGranted = s.isGranted);
              },
            ),
            _permTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'To remind you about payments and meetings.',
              granted: _notifGranted,
              onTap: () async {
                final s = await Permission.notification.request();
                setState(() => _notifGranted = s.isGranted);
              },
            ),
          ],
        ),
      );

  Widget _permTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(icon, color: AppColors.seed),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: granted
              ? const Icon(Icons.check_circle, color: AppColors.income)
              : TextButton(onPressed: onTap, child: const Text('Allow')),
          onTap: granted ? null : onTap,
        ),
      );

  Widget _consentStep() => _pad(
        ListView(
          children: [
            const SizedBox(height: 8),
            const Text('Recording & privacy',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This app records in-app voice notes only. Modern Android does not allow apps to record phone calls, so call recording is not available — use speakerphone and a voice note instead.',
                      style: TextStyle(color: AppColors.slate, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand my voice notes are recorded and transcribed on this device, and I will get consent before recording other people.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
}
