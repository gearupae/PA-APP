import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/mind_map_view.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.state, required this.noteId});
  final AppState state;
  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final note = widget.state.notes
            .where((n) => n.id == widget.noteId)
            .cast<Note?>()
            .firstWhere((n) => true, orElse: () => null);
        if (note == null) {
          return const Scaffold(body: Center(child: Text('Note deleted')));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Note'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  widget.state.deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: AppTheme.pagePad,
            children: [
              Text(note.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(dayMonthTime(note.createdAt),
                  style: TextStyle(color: AppColors.slate, fontSize: 13)),
              const SizedBox(height: 20),

              // Todos
              _sectionTitle(Icons.checklist, 'To-dos (${note.todos.length})'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: note.todos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('No action items detected.',
                              style: TextStyle(color: AppColors.slate)),
                        )
                      : Column(
                          children: note.todos
                              .map((t) => _todoTile(note, t))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Mind map
              _sectionTitle(Icons.account_tree_outlined, 'Mind map'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MindMapView(root: note.mindMap),
                ),
              ),
              const SizedBox(height: 20),

              // Transcript
              _sectionTitle(Icons.notes, 'Transcript'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(note.transcript,
                      style: const TextStyle(height: 1.6)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 20, color: AppColors.seed),
          const SizedBox(width: 8),
          Text(text,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _todoTile(Note note, Todo t) => ListTile(
        leading: Checkbox(
          value: t.done,
          onChanged: (v) {
            setState(() => t.done = v ?? false);
            widget.state.updateNote(note);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        title: Text(
          t.text,
          style: TextStyle(
            decoration: t.done ? TextDecoration.lineThrough : null,
            color: t.done ? AppColors.slate : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.alarm_add_outlined, size: 20),
          tooltip: 'Add reminder',
          onPressed: () {
            widget.state.addReminder(Reminder(
              id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
              title: t.text,
              dueAt: DateTime.now().add(const Duration(hours: 2)),
              kind: ReminderKind.general,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder added (in 2 hours)')),
            );
          },
        ),
      );
}
