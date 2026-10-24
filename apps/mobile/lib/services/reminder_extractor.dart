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
  // Licences / documents: visa, Emirates ID, passport, driving licence, etc.
  static final _document = RegExp(
    r'\b(visa|emirates id|eid|passport|licen[cs]e|permit|registration|mulkiya|'
    r'certificate|tenancy|ejari|labour card|work permit|id card)\b',
    caseSensitive: false,
  );
  // Maintenance: car service, AC, appliances, warranty.
  static final _maintenance = RegExp(
    r'\b(service due|maintenance|oil change|ac service|a/c service|servicing|'
    r'warranty|inspection|next service|filter change)\b',
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
      } else if (_renewal.hasMatch(lower) ||
          _document.hasMatch(lower) ||
          _maintenance.hasMatch(lower)) {
        // Renewals, licence/document expiry and maintenance are time-bound
        // "life admin" reminders.
        kind = _payment.hasMatch(lower)
            ? ReminderKind.payment
            : ReminderKind.general;
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

  static final _weekdays = <String, int>{
    'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
    'friday': 5, 'saturday': 6, 'sunday': 7,
  };

  /// Extract reminders from a free-text transcript (voice note / meeting).
  /// Understands explicit dates plus "tomorrow", "today", weekdays and times.
  static List<Reminder> fromText(String text, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final out = <Reminder>[];
    var i = 0;
    for (final s in sentences) {
      final lower = s.toLowerCase();
      ReminderKind? kind;
      if (_meeting.hasMatch(lower) ||
          lower.contains('remind') ||
          lower.contains('follow up') ||
          lower.contains('follow-up')) {
        kind = ReminderKind.meeting;
      } else if (_payment.hasMatch(lower) || _renewal.hasMatch(lower)) {
        kind = ReminderKind.payment;
      } else if (_document.hasMatch(lower) || _maintenance.hasMatch(lower)) {
        kind = ReminderKind.general;
      }
      if (kind == null) continue;
      final when = _findWhen(s, base);
      if (when == null) continue;
      out.add(Reminder(
        id: 'rem_${base.millisecondsSinceEpoch}_${i++}',
        title: _trimText(s),
        dueAt: when,
        kind: kind,
      ));
    }
    return out;
  }

  static String _trimText(String s) {
    var t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isNotEmpty) t = '${t[0].toUpperCase()}${t.substring(1)}';
    if (t.length > 80) t = '${t.substring(0, 78)}…';
    return t;
  }

  static DateTime? _findWhen(String text, DateTime base) {
    final lower = text.toLowerCase();
    final time = _findTime(lower); // (hour, minute) or null
    final h = time?.$1 ?? 9;
    final m = time?.$2 ?? 0;

    if (lower.contains('tomorrow')) {
      final d = base.add(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day, h, m);
    }
    if (lower.contains('today') || lower.contains('tonight')) {
      return DateTime(base.year, base.month, base.day, h, m);
    }
    for (final entry in _weekdays.entries) {
      if (lower.contains(entry.key)) {
        var add = (entry.value - base.weekday) % 7;
        if (add == 0) add = 7; // next week's same day
        final d = base.add(Duration(days: add));
        return DateTime(d.year, d.month, d.day, h, m);
      }
    }
    final explicit = _findDate(text, base);
    if (explicit != null) {
      return DateTime(explicit.year, explicit.month, explicit.day, h, m);
    }
    // Time only ("at 3pm") -> today, or tomorrow if already past.
    if (time != null) {
      var dt = DateTime(base.year, base.month, base.day, h, m);
      if (dt.isBefore(base)) dt = dt.add(const Duration(days: 1));
      return dt;
    }
    return null;
  }

  static (int, int)? _findTime(String lower) {
    final mt = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b').firstMatch(lower);
    if (mt != null) {
      var h = int.parse(mt.group(1)!);
      final min = mt.group(2) != null ? int.parse(mt.group(2)!) : 0;
      final ap = mt.group(3)!;
      if (ap == 'pm' && h < 12) h += 12;
      if (ap == 'am' && h == 12) h = 0;
      if (h <= 23 && min <= 59) return (h, min);
    }
    final at = RegExp(r'\bat\s+(\d{1,2})(?::(\d{2}))?\b').firstMatch(lower);
    if (at != null) {
      final h = int.parse(at.group(1)!);
      final min = at.group(2) != null ? int.parse(at.group(2)!) : 0;
      if (h <= 23 && min <= 59) return (h, min);
    }
    return null;
  }

  static String _title(String body, String sender) {
    var t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 70) t = '${t.substring(0, 68)}…';
    final from = sender.isEmpty ? '' : '$sender: ';
    return '$from$t';
  }

  /// Public wrapper around the date finder for reuse (e.g. dues parsing).
  static DateTime? findDate(String body, DateTime received) =>
      _findDate(body, received);

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
