import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'note_detail_screen.dart';

/// Live view of the shared recorder. Opening it starts capture if idle;
/// stopping saves the note (to-dos + mind map) and reminders.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.state});
  final AppState state;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  Future<void> _start() async {
    final rec = widget.state.recorder;
    final ok = await rec.start();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(rec.lastError ??
              'Microphone or speech recognition not available.'),
          duration: const Duration(seconds: 5)));
    }
  }

  Future<void> _stop() async {
    final rec = widget.state.recorder;
    final id = await rec.stopAndSave();
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(rec.lastError ??
            'No speech was captured. Speak clearly and check the mic.'),
        duration: const Duration(seconds: 4),
      ));
      Navigator.of(context).pop();
      return;
    }
    final n = rec.lastReminderCount;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NoteDetailScreen(state: widget.state, noteId: id),
    ));
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$n reminder${n == 1 ? '' : 's'} added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.state.recorder;
    return Scaffold(
      appBar: AppBar(title: const Text('Recording')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: rec,
          builder: (context, _) {
            return Column(
              children: [
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (rec.active) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: AppColors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      rec.active
                          ? 'Listening · ${rec.clock}'
                          : rec.starting
                              ? 'Starting…'
                              : 'Tap to start',
                      style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: rec.text.isEmpty && rec.lastError != null
                          ? Text(
                              rec.lastError!,
                              style: const TextStyle(
                                  fontSize: 15, color: AppColors.expense),
                            )
                          : Text(
                              rec.text.isEmpty ? '…' : rec.text,
                              style:
                                  const TextStyle(fontSize: 19, height: 1.5),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: GestureDetector(
                    onTap: rec.active ? _stop : _start,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rec.active ? AppColors.ink : AppColors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (rec.active ? AppColors.ink : AppColors.red)
                                .withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(rec.active ? Icons.stop : Icons.mic,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(rec.active ? 'Tap to stop & save' : '',
                      style: const TextStyle(color: AppColors.slate)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
