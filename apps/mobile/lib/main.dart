import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/local_store.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.instance();
  final state = AppState(store);
  await state.bootstrap();
  runApp(PaApp(state: state, store: store));
}

class PaApp extends StatelessWidget {
  const PaApp({super.key, required this.state, required this.store});

  final AppState state;
  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PA-APP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: RootGate(state: state, store: store),
    );
  }
}

/// Decides which screen to show: auth -> onboarding -> main app.
class RootGate extends StatefulWidget {
  const RootGate({super.key, required this.state, required this.store});
  final AppState state;
  final LocalStore store;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  Widget build(BuildContext context) {
    if (!widget.store.signedIn) {
      return AuthScreen(
        state: widget.state,
        store: widget.store,
        onDone: () => setState(() {}),
      );
    }
    if (!widget.store.onboarded) {
      return OnboardingScreen(
        state: widget.state,
        store: widget.store,
        onDone: () => setState(() {}),
      );
    }
    return MainShell(
      state: widget.state,
      onSignedOut: () => setState(() {}),
    );
  }
}
