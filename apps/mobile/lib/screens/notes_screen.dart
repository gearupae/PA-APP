import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.state, required this.onRecord});
  final AppState state;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Notes')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onRecord,
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.mic),
            label: const Text('Record'),
          ),
          body: state.notes.isEmpty
              ? _empty(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = state.notes[i];
                    final open = n.todos.where((t) => !t.done).length;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.violet.withValues(alpha: 0.14),
                          child: const Icon(Icons.description_outlined,
                              color: AppColors.violet, size: 20),
                        ),
                        title: Text(n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${n.todos.length} to-dos · $open open · ${timeAgo(n.createdAt)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NoteDetailScreen(
                                state: state, noteId: n.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.graphic_eq, size: 52, color: AppColors.slate),
              const SizedBox(height: 14),
              const Text('No notes yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Tap the red mic to record. Your voice turns into to-dos and a mind map automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.mic),
                label: const Text('Record a note'),
              ),
            ],
          ),
        ),
      );
}
