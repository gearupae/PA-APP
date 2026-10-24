import 'package:flutter/material.dart';

import '../services/ai_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class _Msg {
  _Msg(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late final AiApi _ai = AiApi(widget.state.store);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // A short snapshot so answers can reference the user's data.
  String _context() {
    final s = widget.state;
    final dues = s.dues
        .take(3)
        .map((d) =>
            '${d.currency.isEmpty ? '' : '${d.currency} '}${d.amount.round()} due ${d.dueAt.day}/${d.dueAt.month} (${d.source})')
        .join('; ');
    final rem = s.upcomingReminders.take(3).map((r) => r.title).join('; ');
    return 'Spent this month: ${s.monthExpense.round()}. '
        'Earned: ${s.monthIncome.round()}. '
        'Upcoming dues: ${dues.isEmpty ? 'none' : dues}. '
        'Reminders: ${rem.isEmpty ? 'none' : rem}.';
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    if (!_ai.enabled) {
      setState(() => _messages.add(_Msg(
          'Sign in (Profile) to use the assistant — it runs on your server.',
          false)));
      return;
    }
    setState(() {
      _messages.add(_Msg(q, true));
      _busy = true;
      _input.clear();
    });
    _scrollDown();
    final ans = await _ai.ask(q, context: _context());
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(
          ans ?? 'Could not reach the assistant. Check your connection.',
          false));
      _busy = false;
    });
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _empty()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _bubble(_messages[i]),
                  ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Thinking…', style: TextStyle(color: AppColors.slate)),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 48, color: AppColors.slate),
              const SizedBox(height: 12),
              const Text('Ask your assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Try: "What’s due this week?" or "Summarise my spending."',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );

  Widget _bubble(_Msg m) => Align(
        alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: m.fromUser ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: m.fromUser ? null : Border.all(color: AppColors.line),
          ),
          child: Text(m.text,
              style: TextStyle(
                  color: m.fromUser ? Colors.white : AppColors.ink,
                  height: 1.4)),
        ),
      );

  Widget _composer() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask anything…',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                      color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
}
