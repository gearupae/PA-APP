import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../services/mail_api.dart';

class ConnectAccountScreen extends StatefulWidget {
  const ConnectAccountScreen({super.key, this.mailApi});

  final MailApi? mailApi;

  @override
  State<ConnectAccountScreen> createState() => _ConnectAccountScreenState();
}

class _ConnectAccountScreenState extends State<ConnectAccountScreen> {
  late final MailApi _api = widget.mailApi ?? MailApi();
  final _hostController = TextEditingController(text: 'imap.example.com');
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<ConnectedAccount> _accounts = [];

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refreshAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await _api.listAccounts();
      if (!mounted) return;
      setState(() => _accounts = accounts);
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauthConnect(Future<OAuthConnectResult> Function() fn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await fn();
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: result.authorizationUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OAuth URL copied (${result.provider}). Open in browser to consent.',
          ),
        ),
      );
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectImap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.connectImap(
        host: _hostController.text.trim(),
        username: _userController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _passwordController.clear();
      await _refreshAccounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IMAP account connected')),
      );
    } on MailApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect(String id) async {
    await _api.disconnectAccount(id);
    await _refreshAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final tokenHint = ApiConfig.accessToken.isEmpty
        ? 'Set ACCESS_TOKEN via --dart-define after POST /auth/login'
        : 'Using configured ACCESS_TOKEN';

    return Scaffold(
      appBar: AppBar(title: const Text('Connect mail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tokenHint, style: Theme.of(context).textTheme.bodySmall),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Text('Providers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : () => _oauthConnect(_api.connectGmail),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Gmail'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : () => _oauthConnect(_api.connectOutlook),
                icon: const Icon(Icons.mail),
                label: const Text('Outlook'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('IMAP', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(labelText: 'Host', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(labelText: 'Username / email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'App password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _connectImap,
            child: const Text('Connect IMAP'),
          ),
          const SizedBox(height: 24),
          Text('Connected accounts', style: Theme.of(context).textTheme.titleMedium),
          if (_loading && _accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No accounts yet.'),
            )
          else
            ..._accounts.map(
              (a) => ListTile(
                title: Text(a.emailAddress ?? a.id),
                subtitle: Text(a.provider),
                trailing: IconButton(
                  icon: const Icon(Icons.link_off),
                  onPressed: _loading ? null : () => _disconnect(a.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
