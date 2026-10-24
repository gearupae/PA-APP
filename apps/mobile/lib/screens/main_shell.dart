import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'add_actions.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // If a recording is in progress and the app goes to the background,
    // stop and save it (capture is foreground-only).
    final rec = widget.state.recorder;
    if ((s == AppLifecycleState.paused || s == AppLifecycleState.detached) &&
        rec.active) {
      rec.stopAndSave();
    }
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
      DashboardScreen(state: s),
      RemindersLocalScreen(state: s),
      NotesScreen(state: s, onRecord: _openRecorder),
      ProfileScreen(state: s, onSignedOut: widget.onSignedOut),
    ];

    // Only Reminders (1) and Notes (2) get the + button.
    VoidCallback? addAction;
    if (_index == 1) {
      addAction = () => showAddReminder(context, s);
    } else if (_index == 2) {
      addAction = _openRecorder;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton:
          addAction == null ? null : _AddButton(onTap: addAction),
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

/// Consistent red "+" action button, same on every page (reference style).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
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
                color: AppColors.red.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
