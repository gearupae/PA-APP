import 'package:flutter/material.dart';

import '../state/app_state.dart';
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

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
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
