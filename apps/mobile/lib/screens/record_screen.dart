import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/note_builder.dart';
import '../services/speech_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'note_detail_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.state});
  final AppState state;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _speech = SpeechService();
  bool _listening = false;
  String _live = '';
  String _buffer = '';

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      final text = (_buffer.isEmpty ? _live : _buffer).trim();
      if (text.isNotEmpty) {
        final note = NoteBuilder.build(text);
        await widget.state.addNote(note);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => NoteDetailScreen(state: widget.state, noteId: note.id),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing was captured — try again.')),
        );
      }
      setState(() {
        _live = '';
        _buffer = '';
      });
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission needed.')),
        );
      }
      return;
    }
    final ok = await _speech.init();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Speech recognition not available on this device.')),
        );
      }
      return;
    }
    setState(() {
      _listening = true;
      _live = '';
      _buffer = '';
    });
    await _speech.start(onResult: (text, isFinal) {
      setState(() {
        _live = text;
        if (isFinal) _buffer = (_buffer + ' ' + text).trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Record')),
          body: Column(
            children: [
              _recorder(),
              const Divider(height: 1),
              Expanded(child: _notesList(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _recorder() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Text(
              _listening
                  ? 'Listening… speak naturally'
                  : 'Tap to record a voice note',
              style: TextStyle(color: AppColors.slate, fontSize: 14),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _listening
                        ? [AppColors.expense, AppColors.pink]
                        : [AppColors.seed, AppColors.violet],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_listening ? AppColors.expense : AppColors.seed)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(_listening ? Icons.stop : Icons.mic,
                    color: Colors.white, size: 36),
              ),
            ),
            if (_listening || _live.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  (_buffer + ' ' + _live).trim().isEmpty
                      ? '…'
                      : (_buffer + ' ' + _live).trim(),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _notesList(AppState state) {
    if (state.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq, size: 48, color: AppColors.slate),
              const SizedBox(height: 12),
              Text(
                'Your voice notes become todos and a mind map automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = state.notes[i];
        final open = n.todos.where((t) => !t.done).length;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.violet.withValues(alpha: 0.14),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.violet, size: 20),
            ),
            title: Text(n.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${n.todos.length} todos · $open open · ${timeAgo(n.createdAt)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) =>
                  NoteDetailScreen(state: widget.state, noteId: n.id),
            )),
          ),
        );
      },
    );
  }
}
