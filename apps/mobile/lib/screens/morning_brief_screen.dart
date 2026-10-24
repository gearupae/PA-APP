import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// A 2-minute "morning brief": what's due today, money in/out, dues and
/// open to-dos — assembled from on-device data.
class MorningBriefScreen extends StatelessWidget {
  const MorningBriefScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final now = DateTime.now();
        bool isToday(DateTime d) =>
            d.year == now.year && d.month == now.month && d.day == now.day;
        final todays = state.upcomingReminders
            .where((r) => isToday(r.dueAt) || r.dueAt.isBefore(now))
            .toList();
        final dues = state.dues.take(4).toList();
        final todos = state.openTodos.take(5).toList();
        final name = state.store.userName;

        return Scaffold(
          appBar: AppBar(title: const Text('Morning brief')),
          body: ListView(
            padding: AppTheme.pagePad,
            children: [
              Text(
                name.isEmpty ? 'Here’s your day' : 'Here’s your day, $name',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
              const SizedBox(height: 4),
              Text(dayMonth(now),
                  style: const TextStyle(color: AppColors.slate)),
              const SizedBox(height: 16),

              _moneyRow(),
              const SizedBox(height: 16),

              _card(
                'Due today',
                Icons.today_outlined,
                todays.isEmpty
                    ? _empty('Nothing due today — enjoy it.')
                    : Column(
                        children: todays
                            .take(6)
                            .map((r) => _line(
                                _kindIcon(r.kind),
                                r.title,
                                r.dueAt.isBefore(now)
                                    ? 'overdue'
                                    : dayMonthTime(r.dueAt),
                                r.dueAt.isBefore(now)))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),

              _card(
                'Money due soon',
                Icons.event_available_outlined,
                dues.isEmpty
                    ? _empty('No upcoming dues.')
                    : Column(
                        children: dues
                            .map((d) => _line(
                                Icons.payments_outlined,
                                '${d.currency.isEmpty ? '' : '${d.currency} '}${money(d.amount)} · ${d.source}',
                                'due ${dayMonth(d.dueAt)}',
                                d.dueAt.isBefore(now)))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),

              _card(
                'To-dos',
                Icons.checklist,
                todos.isEmpty
                    ? _empty('No open to-dos.')
                    : Column(
                        children: todos
                            .map((e) => _line(Icons.radio_button_unchecked,
                                e.todo.text, '', false))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _moneyRow() {
    Widget tile(String label, double v, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12)),
                const SizedBox(height: 6),
                Text(money(v),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: c)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tile('In (MTD)', state.monthIncome, AppColors.income),
        const SizedBox(width: 10),
        tile('Out (MTD)', state.monthExpense, AppColors.expense),
      ],
    );
  }

  Widget _card(String title, IconData icon, Widget child) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );

  Widget _line(IconData icon, String text, String trailing, bool warn) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.slate),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(trailing,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: warn ? AppColors.expense : AppColors.slate)),
            ],
          ],
        ),
      );

  Widget _empty(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t, style: const TextStyle(color: AppColors.slate)),
      );

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
}
