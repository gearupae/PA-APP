import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/models.dart';
import '../services/expense_parser.dart';
import '../services/local_store.dart';
import '../services/reminder_extractor.dart';
import '../services/sms_service.dart';

/// App-wide state: data loading, permissions, derived dashboard figures.
class AppState extends ChangeNotifier {
  AppState(this.store);

  final LocalStore store;
  final SmsService _sms = SmsService();

  List<SmsItem> messages = [];
  List<Txn> txns = []; // parsed (from SMS) + manual, with overrides applied
  List<Note> notes = [];
  List<Reminder> reminders = [];

  bool smsGranted = false;
  bool loadingSms = false;

  Future<void> bootstrap() async {
    notes = store.notes;
    reminders = store.reminders;
    reminders.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    smsGranted = await Permission.sms.isGranted;
    _rebuildTxns();
    notifyListeners();
    if (smsGranted) {
      await refreshSms();
    }
  }

  // ---- SMS + transactions ----
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    smsGranted = status.isGranted;
    notifyListeners();
    if (smsGranted) await refreshSms();
    return smsGranted;
  }

  Future<void> refreshSms() async {
    if (!smsGranted) return;
    loadingSms = true;
    notifyListeners();
    messages = await _sms.getInbox(limit: 800);
    _rebuildTxns();
    loadingSms = false;
    notifyListeners();
  }

  void _rebuildTxns() {
    final overrides = store.categoryOverrides;
    final parsed = ExpenseParser.parse(messages);
    final all = <Txn>[...parsed, ...store.manualTxns];
    for (final t in all) {
      final o = overrides[t.id];
      if (o != null) t.category = o;
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    txns = all;
  }

  Future<void> setCategory(Txn t, String category) async {
    await store.setCategoryOverride(t.id, category);
    t.category = category;
    notifyListeners();
  }

  Future<void> addManualTxn(Txn t) async {
    final list = store.manualTxns..add(t);
    await store.saveManualTxns(list);
    _rebuildTxns();
    notifyListeners();
  }

  // ---- derived dashboard figures (current calendar month) ----
  bool _sameMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  List<Txn> get monthTxns => txns.where((t) => _sameMonth(t.date)).toList();

  double get monthExpense => monthTxns
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get monthIncome =>
      monthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get monthSavings => monthIncome - monthExpense;

  /// Expense totals by category, highest first.
  List<MapEntry<String, double>> get categoryBreakdown {
    final map = <String, double>{};
    for (final t in monthTxns.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Simple, friendly money suggestions from the current month's data.
  List<String> get suggestions {
    final out = <String>[];
    final breakdown = categoryBreakdown;
    if (monthTxns.isEmpty) {
      return [
        'No transactions detected yet this month. Grant SMS access or add one manually to see insights.'
      ];
    }
    if (monthExpense > 0 && breakdown.isNotEmpty) {
      final top = breakdown.first;
      final pct = (top.value / monthExpense * 100).round();
      out.add(
          '${top.key} is your biggest spend this month at $pct% of expenses.');
    }
    if (monthIncome > 0) {
      final rate = (monthSavings / monthIncome * 100).round();
      if (monthSavings < 0) {
        out.add('You spent more than you earned this month — review bills and shopping.');
      } else if (rate < 20) {
        out.add('Savings rate is $rate%. Aim for 20%+ by trimming your top category.');
      } else {
        out.add('Nice — you saved $rate% of income this month. Keep it up!');
      }
    }
    final food = breakdown.where((e) => e.key == 'Food').fold(0.0, (s, e) => s + e.value);
    if (food > 0 && monthExpense > 0 && food / monthExpense > 0.25) {
      out.add('Food delivery is over a quarter of spending — cooking a few meals could save a lot.');
    }
    if (out.isEmpty) out.add('Spending looks balanced this month. 👍');
    return out;
  }

  // ---- notes ----
  Future<void> addNote(Note n) async {
    notes = [n, ...notes];
    await store.saveNotes(notes);
    notifyListeners();
  }

  Future<void> updateNote(Note n) async {
    final i = notes.indexWhere((x) => x.id == n.id);
    if (i >= 0) notes[i] = n;
    await store.saveNotes(notes);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
    await store.saveNotes(notes);
    notifyListeners();
  }

  Future<void> toggleTodo(Note note, Todo todo) async {
    todo.done = !todo.done;
    await updateNote(note);
  }

  // ---- reminders (manual + auto-extracted from SMS) ----
  bool _isAuto(String id) => id.startsWith('auto_');

  /// Reminders pulled out of SMS, minus any the user dismissed, with the
  /// stored done-state applied.
  List<Reminder> get autoReminders {
    final dismissed = store.dismissedAutoReminders;
    final done = store.doneAutoReminders;
    return ReminderExtractor.extract(messages)
        .where((r) => !dismissed.contains(r.id))
        .map((r) => r..done = done.contains(r.id))
        .toList();
  }

  /// All reminders (manual + auto), sorted by due date.
  List<Reminder> get allReminders {
    final list = [...reminders, ...autoReminders]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  List<Reminder> get upcomingReminders =>
      allReminders.where((r) => !r.done).toList();

  Future<void> addReminder(Reminder r) async {
    reminders = [...reminders, r]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await store.saveReminders(reminders);
    notifyListeners();
  }

  /// Parse a transcript and persist any reminders found; returns the count.
  Future<int> addRemindersFromText(String text) async {
    final found = ReminderExtractor.fromText(text);
    if (found.isEmpty) return 0;
    reminders = [...reminders, ...found]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await store.saveReminders(reminders);
    notifyListeners();
    return found.length;
  }

  Future<void> toggleReminder(Reminder r) async {
    if (_isAuto(r.id)) {
      r.done = !r.done;
      await store.setDoneAutoReminder(r.id, r.done);
    } else {
      r.done = !r.done;
      await store.saveReminders(reminders);
    }
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    if (_isAuto(id)) {
      await store.dismissAutoReminder(id);
    } else {
      reminders.removeWhere((r) => r.id == id);
      await store.saveReminders(reminders);
    }
    notifyListeners();
  }

  // ---- open to-dos across all notes (for the dashboard) ----
  List<({Note note, Todo todo})> get openTodos {
    final out = <({Note note, Todo todo})>[];
    for (final n in notes) {
      for (final t in n.todos) {
        if (!t.done) out.add((note: n, todo: t));
      }
    }
    return out;
  }

  // ---- important messages (non-financial, flagged) ----
  static final _importantRe = RegExp(
    r'\b(otp|verify|urgent|overdue|due|payment|invoice|subscription|renew|'
    r'expiring|expire|delivery|appointment|meeting|interview|refund|alert|'
    r'last date|reminder|support|enquiry|inquiry|quote)\b',
    caseSensitive: false,
  );

  List<SmsItem> get importantMessages =>
      messages.where((m) => _importantRe.hasMatch(m.body)).toList();
}
