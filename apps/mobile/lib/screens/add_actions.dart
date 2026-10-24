import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// Shared "add" flows so one global + button behaves the same everywhere.

void showQuickAdd(
  BuildContext context,
  AppState state, {
  required VoidCallback onRecord,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Add',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          _quickTile(ctx, Icons.alarm_add_outlined, 'New reminder',
              'Payment, meeting or anything', () {
            Navigator.pop(ctx);
            showAddReminder(context, state);
          }),
          _quickTile(ctx, Icons.add_card_outlined, 'Add transaction',
              'Log an expense or income', () {
            Navigator.pop(ctx);
            showAddTransaction(context, state);
          }),
          _quickTile(ctx, Icons.mic_none, 'Record a note',
              'Voice → to-dos & mind map', () {
            Navigator.pop(ctx);
            onRecord();
          }),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Widget _quickTile(BuildContext ctx, IconData icon, String title,
        String subtitle, VoidCallback onTap) =>
    ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );

// ---- Add transaction ----
void showAddTransaction(BuildContext context, AppState state) {
  final amountC = TextEditingController();
  final merchantC = TextEditingController();
  String category = 'Food';
  bool isIncome = false;

  showModalBottomSheet<void>(
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
            const Text('Add transaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: !isIncome,
                  onSelected: (_) => setM(() => isIncome = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: isIncome,
                  onSelected: (_) => setM(() => isIncome = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount', prefixIcon: Icon(Icons.numbers)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: merchantC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Merchant / source',
                  prefixIcon: Icon(Icons.store_outlined)),
            ),
            const SizedBox(height: 12),
            if (!isIncome)
              Wrap(
                spacing: 8,
                children: AppColors.categoryColors.keys
                    .where((c) => c != 'Other')
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: category == c,
                          onSelected: (_) => setM(() => category = c),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final amt = double.tryParse(amountC.text.trim());
                  if (amt == null || amt <= 0) return;
                  state.addManualTxn(Txn(
                    id: 'man_${DateTime.now().millisecondsSinceEpoch}',
                    amount: amt,
                    category: isIncome ? 'Income' : category,
                    merchant: merchantC.text.trim().isEmpty
                        ? (isIncome ? 'Income' : 'Manual')
                        : merchantC.text.trim(),
                    date: DateTime.now(),
                    isIncome: isIncome,
                    manual: true,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---- Add reminder ----
void showAddReminder(BuildContext context, AppState state) {
  final titleC = TextEditingController();
  ReminderKind kind = ReminderKind.payment;
  DateTime due = DateTime.now().add(const Duration(hours: 1));

  showModalBottomSheet<void>(
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
                        label: Text(
                            k.name[0].toUpperCase() + k.name.substring(1)),
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
