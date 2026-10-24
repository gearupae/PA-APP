import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/dues_extractor.dart';
import '../services/mail_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/donut_chart.dart';
import 'assistant_screen.dart';
import 'connect_account_screen.dart';
import 'morning_brief_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final name = state.store.userName;
        final reminders = state.upcomingReminders;
        final todos = state.openTodos;
        return Scaffold(
          appBar: AppBar(
            title: Text(name.isEmpty ? 'Good day' : 'Good day, $name'),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Assistant',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AssistantScreen(state: state),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.refreshSms,
            child: ListView(
              padding: AppTheme.pagePad,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MorningBriefScreen(state: state),
                    ),
                  ),
                  child: _actionNeeded(reminders.length, todos.length),
                ),
                const SizedBox(height: 16),
                if (!state.smsGranted) ...[
                  _smsPrompt(),
                  const SizedBox(height: 16),
                ],
                _duesSection(),
                _emailSection(context),
                _remindersSection(reminders),
                _todosSection(todos),
                _promisesSection(),
                _moneySection(context),
                _suggestions(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Action needed (soft sage hero card) ----
  Widget _actionNeeded(int reminders, int todos) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Action needed',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 5),
                  Text(
                    '$reminders reminders · $todos to-dos',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 19),
            ),
          ],
        ),
      );

  Widget _smsPrompt() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.sms_outlined, color: AppColors.accent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Allow SMS to auto-track spending and pull reminders from your messages.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: state.requestSmsPermission,
              child: const Text('Allow'),
            ),
          ],
        ),
      );

  // ---- Reminders ----
  Widget _remindersSection(List<Reminder> reminders) {
    return _section(
      'Reminders',
      Icons.notifications_none,
      child: reminders.isEmpty
          ? _emptyLine('No upcoming reminders.')
          : Column(
              children: reminders
                  .take(3)
                  .map((r) => _reminderTile(r))
                  .toList(),
            ),
    );
  }

  Widget _reminderTile(Reminder r) {
    final overdue = r.dueAt.isBefore(DateTime.now());
    final auto = r.id.startsWith('auto_');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        r.kind == ReminderKind.payment
            ? Icons.payments_outlined
            : r.kind == ReminderKind.meeting
                ? Icons.groups_outlined
                : Icons.push_pin_outlined,
        color: AppColors.ink,
      ),
      title: Text(r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Text(dayMonth(r.dueAt),
              style: TextStyle(
                  color: overdue ? AppColors.expense : AppColors.slate,
                  fontWeight: overdue ? FontWeight.w700 : null)),
          if (auto) ...[
            const SizedBox(width: 6),
            _miniTag('from SMS'),
          ],
        ],
      ),
      trailing: Checkbox(
        value: r.done,
        onChanged: (_) => state.toggleReminder(r),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ---- To-dos ----
  Widget _todosSection(List<({Note note, Todo todo})> todos) {
    return _section(
      'To-dos',
      Icons.checklist,
      child: todos.isEmpty
          ? _emptyLine('No open to-dos. Record a voice note to create some.')
          : Column(
              children: todos
                  .take(4)
                  .map((e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Checkbox(
                          value: false,
                          onChanged: (_) =>
                              state.toggleTodo(e.note, e.todo),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        title: Text(e.todo.text,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
            ),
    );
  }

  // ---- Promises (from voice notes) ----
  Widget _promisesSection() {
    final promises = state.promises.take(4).toList();
    if (promises.isEmpty) return const SizedBox.shrink();
    return _section(
      'You promised',
      Icons.handshake_outlined,
      child: Column(
        children: promises
            .map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.subdirectory_arrow_right,
                          size: 16, color: AppColors.slate),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(p.text,
                              maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ---- Money metrics ----
  Widget _moneySection(BuildContext context) {
    final breakdown = state.categoryBreakdown;
    final slices = breakdown
        .take(6)
        .map((e) => DonutSlice(e.key, e.value, AppColors.forCategory(e.key)))
        .toList();
    return _section(
      'This month',
      Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          Row(
            children: [
              _stat('Spent', state.monthExpense, AppColors.expense),
              const SizedBox(width: 10),
              _stat('Earned', state.monthIncome, AppColors.income),
              const SizedBox(width: 10),
              _stat('Saved', state.monthSavings, AppColors.ink),
            ],
          ),
          if (state.businessOwes > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_center_outlined,
                      size: 18, color: AppColors.ink),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Business owes you',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  Text(money(state.businessOwes),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (breakdown.isEmpty)
            _emptyLine('Spending by category will appear from your SMS.')
          else
            Row(
              children: [
                DonutChart(
                  slices: slices,
                  centerTop: 'Spent',
                  centerBottom: money(state.monthExpense),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: breakdown
                        .take(6)
                        .map((e) => _legend(e.key, e.value))
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(money(value),
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink)),
              ),
            ],
          ),
        ),
      );

  Widget _legend(String cat, double value) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.forCategory(cat),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(cat, style: const TextStyle(fontSize: 13))),
            Text(money(value),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // ---- Important email (summaries only: subject + sender) ----
  Widget _emailSection(BuildContext context) {
    if (!state.emailConnected) {
      // Only nudge to connect; no clutter if offline.
      if (state.store.authToken.isEmpty) return const SizedBox.shrink();
      return _section(
        'Email',
        Icons.mark_email_unread_outlined,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_link, color: AppColors.ink),
          title: const Text('Connect your email'),
          subtitle: const Text('Pull reminders, subscriptions & important mail'),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ConnectAccountScreen(
                      mailApi: MailApi(
                        baseUrl: state.store.apiBaseUrl,
                        accessToken: state.store.authToken,
                      ),
                    )));
            await state.loadEmail();
          },
        ),
      );
    }
    final emails = state.importantEmails.take(4).toList();
    final subs = state.emailSubscriptions.take(3).toList();
    if (emails.isEmpty && subs.isEmpty) return const SizedBox.shrink();
    return _section(
      'Important email',
      Icons.mark_email_unread_outlined,
      child: Column(
        children: [
          ...emails.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.priority_high, color: AppColors.amber),
                title: Text(m.subject.isEmpty ? '(no subject)' : m.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m.fromAddress,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
          ...subs.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.subscriptions_outlined, color: AppColors.violet),
                title: Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.suggestedDueAt != null
                    ? 'Renews ${dayMonth(s.suggestedDueAt!)}'
                    : 'Subscription'),
              )),
        ],
      ),
    );
  }

  // ---- Dues (summarised, not raw messages) ----
  Widget _duesSection() {
    final dues = state.dues.take(4).toList();
    if (dues.isEmpty) return const SizedBox.shrink();
    return _section(
      'Dues',
      Icons.event_available_outlined,
      child: Column(
        children: dues.map(_dueTile).toList(),
      ),
    );
  }

  Widget _dueTile(Due d) {
    final overdue = d.dueAt.isBefore(DateTime.now());
    final amount = d.currency.isEmpty
        ? money(d.amount)
        : '${d.currency} ${money(d.amount)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.payments_outlined,
              color: overdue ? AppColors.expense : AppColors.ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(d.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.slate, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (overdue ? AppColors.expense : AppColors.ink)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              overdue ? 'overdue · ${dayMonth(d.dueAt)}' : 'due ${dayMonth(d.dueAt)}',
              style: TextStyle(
                  color: overdue ? AppColors.expense : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestions() => _section(
        'Suggestions',
        Icons.lightbulb_outline,
        child: Column(
          children: state.suggestions
              .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber)),
                        Expanded(
                            child:
                                Text(s, style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );

  // ---- helpers ----
  Widget _section(String title, IconData icon,
      {required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.cardShadow,
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
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _emptyLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: TextStyle(color: AppColors.slate)),
      );

  Widget _miniTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.tag,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 10, color: AppColors.slate)),
      );
}
