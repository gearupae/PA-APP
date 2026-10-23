import '../models/models.dart';
import 'reminder_extractor.dart';

class Due {
  Due({
    required this.amount,
    required this.currency,
    required this.dueAt,
    required this.source,
  });

  final double amount;
  final String currency; // e.g. AED, INR, "" if unknown
  final DateTime dueAt;
  final String source;
}

/// Finds upcoming "dues" in SMS — a payable amount with a due date — so the
/// dashboard can summarise them (e.g. "AED 400 · due 20 Oct").
class DuesExtractor {
  static final _amount = RegExp(
    r'\b(rs\.?|inr|aed|usd|sar|qar|\$|₹|€|£)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final _dueWord = RegExp(
    r'\b(due|pay by|payment due|last date|before|overdue|outstanding|minimum amount due|total amount due|bill|emi|installment)\b',
    caseSensitive: false,
  );

  static const _symbol = <String, String>{
    r'$': 'USD', '₹': 'INR', '€': 'EUR', '£': 'GBP', 'rs': 'INR', 'rs.': 'INR',
  };

  static List<Due> extract(List<SmsItem> messages) {
    final out = <Due>[];
    for (final m in messages) {
      final body = m.body;
      if (!_dueWord.hasMatch(body.toLowerCase())) continue;
      final am = _amount.firstMatch(body);
      if (am == null) continue;
      final amount =
          double.tryParse(am.group(2)!.replaceAll(',', '')) ?? 0;
      if (amount <= 0) continue;
      final due = ReminderExtractor.findDate(body, m.date);
      if (due == null) continue;
      if (due.isBefore(DateTime.now().subtract(const Duration(days: 2)))) {
        continue;
      }
      final cur = _normCurrency(am.group(1)!);
      out.add(Due(
        amount: amount,
        currency: cur,
        dueAt: due,
        source: m.address.isEmpty ? 'Bill' : m.address,
      ));
    }
    out.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return out;
  }

  static String _normCurrency(String raw) {
    final r = raw.toLowerCase().trim();
    if (_symbol.containsKey(r)) return _symbol[r]!;
    return raw.toUpperCase();
  }
}
