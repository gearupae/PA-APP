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
}
