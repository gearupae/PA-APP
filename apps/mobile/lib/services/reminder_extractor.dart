import '../models/models.dart';

/// Pulls actionable reminders out of SMS: bill due dates, appointments,
/// meetings and subscription renewals. Each reminder gets a stable id
/// derived from the source message so it is not duplicated on refresh.
class ReminderExtractor {
  static final _months = <String, int>{
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static final _payment = RegExp(
    r'\b(due|payment due|pay by|last date|overdue|outstanding|bill|emi|installment|minimum amount due|total amount due)\b',
    caseSensitive: false,
  );
  static final _meeting = RegExp(
    r'\b(appointment|meeting|scheduled|interview|booking|booked|visit|demo|call with)\b',
    caseSensitive: false,
  );
  static final _renewal = RegExp(
    r'\b(renew|renewal|expir(e|es|ing|y)|subscription|validity|recharge)\b',
    caseSensitive: false,
  );

  static List<Reminder> extract(List<SmsItem> messages) {
    final out = <Reminder>[];
    final seen = <String>{};
    for (final m in messages) {
      final body = m.body;
      final lower = body.toLowerCase();
      ReminderKind? kind;
      if (_payment.hasMatch(lower)) {
        kind = ReminderKind.payment;
      } else if (_meeting.hasMatch(lower)) {
        kind = ReminderKind.meeting;
      } else if (_renewal.hasMatch(lower)) {
        kind = ReminderKind.payment;
      }
      if (kind == null) continue;

      final due = _findDate(body, m.date);
      if (due == null) continue; // need a concrete date to be useful
      if (due.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        continue; // skip clearly past items
      }

      final id = 'auto_${m.id}';
      if (!seen.add(id)) continue;
      out.add(Reminder(
        id: id,
        title: _title(body, m.address),
        dueAt: due,
        kind: kind,
      ));
    }
    out.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return out;
  }

  static String _title(String body, String sender) {
    var t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 70) t = '${t.substring(0, 68)}…';
    final from = sender.isEmpty ? '' : '$sender: ';
    return '$from$t';
  }

  /// Tries dd/mm/yyyy, dd-mm-yy, "25 Oct", "Oct 25", "25th October".
  static DateTime? _findDate(String body, DateTime received) {
    // Numeric d/m/y or d-m-y
    final num = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b')
        .firstMatch(body);
    if (num != null) {
      final d = int.parse(num.group(1)!);
      final mo = int.parse(num.group(2)!);
      var y = int.parse(num.group(3)!);
      if (y < 100) y += 2000;
      final dt = _safe(y, mo, d);
      if (dt != null) return dt;
    }

    // "25 Oct" / "25th October 2026"
    final dm = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})(?:\s+(\d{4}))?',
    ).firstMatch(body);
    if (dm != null) {
      final d = int.parse(dm.group(1)!);
      final mo = _monthFromWord(dm.group(2)!);
      if (mo != null) {
        final y = dm.group(3) != null
            ? int.parse(dm.group(3)!)
            : _yearFor(mo, d, received);
        final dt = _safe(y, mo, d);
        if (dt != null) return dt;
      }
    }

    // "Oct 25" / "October 25th"
    final md = RegExp(
      r'\b([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?',
    ).firstMatch(body);
    if (md != null) {
      final mo = _monthFromWord(md.group(1)!);
      if (mo != null) {
        final d = int.parse(md.group(2)!);
        final y = md.group(3) != null
            ? int.parse(md.group(3)!)
            : _yearFor(mo, d, received);
        final dt = _safe(y, mo, d);
        if (dt != null) return dt;
      }
    }
    return null;
  }

  static int? _monthFromWord(String word) {
    final w = word.toLowerCase();
    for (final key in _months.keys) {
      if (w.startsWith(key)) return _months[key];
    }
    return null;
  }

  static int _yearFor(int month, int day, DateTime received) {
    final candidate = DateTime(received.year, month, day);
    // If the date already passed well before the message, assume next year.
    if (candidate.isBefore(received.subtract(const Duration(days: 2)))) {
      return received.year + 1;
    }
    return received.year;
  }

  static DateTime? _safe(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    try {
      final dt = DateTime(y, m, d, 9);
      if (dt.month != m) return null; // overflowed (e.g. 31 Feb)
      return dt;
    } catch (_) {
      return null;
    }
  }
}
