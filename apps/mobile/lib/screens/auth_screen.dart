import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/local_store.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.state,
    required this.store,
    required this.onDone,
  });

  final AppState state;
  final LocalStore store;
  final VoidCallback onDone;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthService _auth = AuthService(widget.store);
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _serverUrl = TextEditingController();

  bool _signUp = true;
  bool _busy = false;
  bool _showServer = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _serverUrl.text = widget.store.apiBaseUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _serverUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    if (_showServer && _serverUrl.text.trim().isNotEmpty) {
      await widget.store.setApiBaseUrl(_serverUrl.text.trim());
    }
    try {
      if (_signUp) {
        await _auth.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await _auth.login(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      widget.onDone();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offline() async {
    await widget.store.setOfflineMode(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text(
                  _signUp ? 'Create your account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      if (_signUp) ...[
                        _field(_name, 'Name', Icons.person_outline,
                            cap: TextCapitalization.words),
                        const SizedBox(height: 12),
                      ],
                      _field(_email, 'Email', Icons.email_outlined,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _field(_password, 'Password', Icons.lock_outline,
                          obscure: true),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.expense)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_signUp ? 'Sign up' : 'Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _signUp = !_signUp;
                    _error = null;
                  }),
                  child: Text(
                    _signUp
                        ? 'Already have an account? Sign in'
                        : "New here? Create an account",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_showServer) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _serverUrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'https://your-server:8000',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _showServer = !_showServer),
                      child: const Text('Server settings',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: _offline,
                      child: const Text('Continue offline',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false,
      TextInputType? keyboard,
      TextCapitalization cap = TextCapitalization.none}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      textCapitalization: cap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
