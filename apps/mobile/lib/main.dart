import 'package:flutter/material.dart';

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
      theme: AppTheme.light(),
      home: store.onboarded
          ? MainShell(state: state)
          : OnboardingScreen(state: state, store: store),
    );
  }
}
