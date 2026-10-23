import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import 'record_screen.dart';
import 'reminders_local_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.state, required this.onSignedOut});

  final AppState state;
  final VoidCallback onSignedOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final rec = widget.state.recorder;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.detached) {
      if (rec.active) rec.stopAndSave();
    } else if (s == AppLifecycleState.resumed) {
      _maybeAutoStart();
    }
  }

  // Auto-start capture every time the app is in front (if consented + allowed).
  Future<void> _maybeAutoStart() async {
    final rec = widget.state.recorder;
    if (rec.active || rec.starting) return;
    if (!widget.state.store.recordingConsent) return;
    if (!await Permission.microphone.isGranted) return;
    await rec.start();
  }

  void _openRecorder() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RecordScreen(state: widget.state),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = [
      DashboardScreen(state: s, onRecord: _openRecorder),
      RemindersLocalScreen(state: s),
      NotesScreen(state: s, onRecord: _openRecorder),
      ProfileScreen(state: s, onSignedOut: widget.onSignedOut),
    ];

    return Scaffold(
      body: Column(
        children: [
          _RecordingBanner(state: s, onTap: _openRecorder),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      floatingActionButton: _MicButton(onTap: _openRecorder),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: 'Reminders'),
          NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: 'Notes'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner({required this.state, required this.onTap});
  final AppState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state.recorder,
      builder: (context, _) {
        final rec = state.recorder;
        if (!rec.active && !rec.starting) return const SizedBox.shrink();
        return SafeArea(
          bottom: false,
          child: Material(
            color: AppColors.red,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      rec.starting ? 'Starting…' : 'Recording · ${rec.clock}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final id = await rec.stopAndSave();
                        if (context.mounted && id != null) {
                          final n = rec.lastReminderCount;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(n > 0
                                ? 'Note saved · $n reminder${n == 1 ? '' : 's'}'
                                : 'Note saved'),
                          ));
                        }
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
