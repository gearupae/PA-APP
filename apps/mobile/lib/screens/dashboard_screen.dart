import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/donut_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final name = state.store.userName;
        final month = DateFormat('MMMM').format(DateTime.now());
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: state.refreshSms,
              child: ListView(
                padding: AppTheme.pagePad,
                children: [
                  _header(name, month),
                  const SizedBox(height: 16),
                  if (!state.smsGranted) _smsPrompt(context),
                  if (!state.smsGranted) const SizedBox(height: 12),
                  _summaryRow(),
                  const SizedBox(height: 16),
                  _spendCard(context),
                  const SizedBox(height: 16),
                  _suggestions(),
                  const SizedBox(height: 16),
                  _recent(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addTxn(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        );
      },
    );
  }

  Widget _header(String name, String month) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Hello 👋' : 'Hello, $name 👋',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text("Here's your $month overview",
              style: TextStyle(color: AppColors.slate, fontSize: 15)),
        ],
      );

  Widget _smsPrompt(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.seed, AppColors.violet]),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            const Icon(Icons.sms, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Allow SMS to auto-track your spending from bank messages.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: AppColors.seed),
              onPressed: state.requestSmsPermission,
              child: const Text('Allow'),
            ),
          ],
        ),
      );

  Widget _summaryRow() => Row(
        children: [
          _statCard('Spent', state.monthExpense, AppColors.expense,
              Icons.arrow_upward),
          const SizedBox(width: 12),
          _statCard('Earned', state.monthIncome, AppColors.income,
              Icons.arrow_downward),
          const SizedBox(width: 12),
          _statCard('Saved', state.monthSavings, AppColors.seed,
              Icons.savings_outlined),
        ],
      );

  Widget _statCard(String label, double value, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(money(value),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(color: AppColors.slate, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _spendCard(BuildContext context) {
    final breakdown = state.categoryBreakdown;
    final slices = breakdown
        .take(6)
        .map((e) => DonutSlice(e.key, e.value, AppColors.forCategory(e.key)))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending by category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (breakdown.isEmpty)
              _empty('No expenses detected this month yet.')
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }

  Widget _legend(String cat, double value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
            Expanded(
                child: Text(cat, style: const TextStyle(fontSize: 13))),
            Text(money(value),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _suggestions() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lightbulb_outline, color: AppColors.amber),
                  SizedBox(width: 8),
                  Text('Smart suggestions',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...state.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber)),
                        Expanded(
                            child: Text(s,
                                style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );

  Widget _recent(BuildContext context) {
    final recent = state.monthTxns.take(8).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              _empty('Transactions from bank SMS will appear here.')
            else
              ...recent.map((t) => _txnTile(context, t)),
          ],
        ),
      ),
    );
  }

  Widget _txnTile(BuildContext context, Txn t) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => _recategorise(context, t),
        leading: CircleAvatar(
          backgroundColor:
              AppColors.forCategory(t.category).withValues(alpha: 0.15),
          child: Icon(_iconFor(t.category),
              color: AppColors.forCategory(t.category), size: 20),
        ),
        title: Text(t.merchant,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${t.category} · ${timeAgo(t.date)}'),
        trailing: Text(
          '${t.isIncome ? '+' : '-'}${money(t.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: t.isIncome ? AppColors.income : const Color(0xFF1A1D29),
          ),
        ),
      );

  IconData _iconFor(String c) {
    switch (c) {
      case 'Food':
        return Icons.restaurant;
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Groceries':
        return Icons.shopping_basket;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt_long;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Health':
        return Icons.favorite_border;
      case 'Income':
        return Icons.payments_outlined;
      case 'Transfers':
        return Icons.swap_horiz;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate)),
        ),
      );

  void _recategorise(BuildContext context, Txn t) {
    final cats = AppColors.categoryColors.keys.toList();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Categorise "${t.merchant}"',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: t.category == c,
                        onSelected: (_) {
                          state.setCategory(t, c);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addTxn(BuildContext context) {
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
                  _typeChip('Expense', !isIncome,
                      () => setM(() => isIncome = false)),
                  const SizedBox(width: 8),
                  _typeChip(
                      'Income', isIncome, () => setM(() => isIncome = true)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Widget _typeChip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}
