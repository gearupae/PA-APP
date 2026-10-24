import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

class RemindersLocalScreen extends StatelessWidget {
  const RemindersLocalScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final all = state.allReminders;
        final pending = all.where((r) => !r.done).toList();
        final done = all.where((r) => r.done).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Reminders')),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_alarm),
              label: const Text('New'),
            ),
          ),
          body: all.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  children: [
                    if (pending.isNotEmpty) _section('Upcoming'),
                    ...pending.map((r) => _tile(context, r)),
                    if (done.isNotEmpty) _section('Done'),
                    ...done.map((r) => _tile(context, r)),
                  ],
                ),
        );
      },
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.slate)),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alarm_off, size: 56, color: AppColors.slate),
              const SizedBox(height: 16),
              const Text('No reminders yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Add payment due dates, meetings, or anything else.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate)),
            ],
          ),
        ),
      );

  Color _kindColor(ReminderKind k) {
    switch (k) {
      case ReminderKind.payment:
        return AppColors.expense;
      case ReminderKind.meeting:
        return AppColors.violet;
      case ReminderKind.general:
        return AppColors.teal;
    }
  }

  IconData _kindIcon(ReminderKind k) {
    switch (k) {
      case ReminderKind.payment:
        return Icons.payments_outlined;
      case ReminderKind.meeting:
        return Icons.groups_outlined;
      case ReminderKind.general:
        return Icons.push_pin_outlined;
    }
  }

  Widget _tile(BuildContext context, Reminder r) {
    final overdue = !r.done && r.dueAt.isBefore(DateTime.now());
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => state.deleteReminder(r.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _kindColor(r.kind).withValues(alpha: 0.18),
            child: Icon(_kindIcon(r.kind), color: _kindColor(r.kind), size: 20),
          ),
          title: Text(
            r.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: r.done ? TextDecoration.lineThrough : null,
              color: r.done ? AppColors.slate : null,
            ),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  dayMonthTime(r.dueAt),
                  style: TextStyle(
                      color: overdue ? AppColors.expense : AppColors.slate,
                      fontWeight: overdue ? FontWeight.w600 : null),
                ),
              ),
              if (r.id.startsWith('auto_')) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tag,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('from SMS',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.slate)),
                ),
              ],
            ],
          ),
          trailing: Checkbox(
            value: r.done,
            onChanged: (_) => state.toggleReminder(r),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final titleC = TextEditingController();
    ReminderKind kind = ReminderKind.payment;
    DateTime due = DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: titleC,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'What to remember',
                    prefixIcon: Icon(Icons.edit_outlined)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: ReminderKind.values
                    .map((k) => ChoiceChip(
                          label: Text(k.name[0].toUpperCase() +
                              k.name.substring(1)),
                          selected: kind == k,
                          onSelected: (_) => setM(() => kind = k),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text('Due: ${dayMonthTime(due)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: due,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d == null) return;
                  if (!ctx.mounted) return;
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(due),
                  );
                  setM(() => due = DateTime(
                      d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleC.text.trim().isEmpty) return;
                    state.addReminder(Reminder(
                      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleC.text.trim(),
                      dueAt: due,
                      kind: kind,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
