import '../models/models.dart';

/// Heuristic parser that turns bank / card / UPI / wallet SMS into
/// transactions and infers a spending category. Tuned to be broad; the
/// user can re-categorise anything from the dashboard.
class ExpenseParser {
  // Amount like: Rs 1,234.50 / INR 1234 / ₹1,234 / AED 50.00 / $12.3
  static final _amount = RegExp(
    r'(?:rs\.?|inr|aed|usd|\$|₹|€|£|sar|qar)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _debitWords = RegExp(
    r'\b(debited|spent|paid|purchase|withdrawn|deducted|debit|sent|txn of|payment of|charged)\b',
    caseSensitive: false,
  );
  static final _creditWords = RegExp(
    r'\b(credited|received|deposited|refund|cashback|salary|credit)\b',
    caseSensitive: false,
  );

  // Merchant hint: "at AMAZON", "to SWIGGY", "VPA ...", "info: UPI/.."
  static final _merchantAt = RegExp(
    r'(?:\bat\b|\bto\b|\bfor\b|\bvia\b)\s+([A-Za-z0-9&.\-* ]{3,30})',
    caseSensitive: false,
  );

  static bool looksFinancial(String body) {
    final b = body.toLowerCase();
    final hasAmount = _amount.hasMatch(body);
    final hasKind = _debitWords.hasMatch(b) || _creditWords.hasMatch(b);
    final hasAcct = b.contains('a/c') ||
        b.contains('acct') ||
        b.contains('account') ||
        b.contains('card') ||
        b.contains('upi') ||
        b.contains('bank') ||
        b.contains('wallet');
    return hasAmount && (hasKind || hasAcct);
  }

  static List<Txn> parse(List<SmsItem> messages) {
    final out = <Txn>[];
    for (final m in messages) {
      final body = m.body;
      if (!looksFinancial(body)) continue;
      final am = _amount.firstMatch(body);
      if (am == null) continue;
      final amount =
          double.tryParse(am.group(1)!.replaceAll(',', '')) ?? 0;
      if (amount <= 0) continue;

      final lower = body.toLowerCase();
      final isCredit = _creditWords.hasMatch(lower) &&
          !_debitWords.hasMatch(lower);

      final merchant = _merchant(body);
      final category =
          isCredit ? 'Income' : _categorise(lower, merchant.toLowerCase());

      out.add(Txn(
        id: 'sms_${m.id}',
        amount: amount,
        category: category,
        merchant: merchant,
        date: m.date,
        isIncome: isCredit,
        raw: body,
      ));
    }
    return out;
  }

  static String _merchant(String body) {
    final mm = _merchantAt.firstMatch(body);
    if (mm != null) {
      var s = mm.group(1)!.trim();
      s = s.replaceAll(RegExp(r'\s+'), ' ');
      if (s.length > 2) {
        // Trim trailing noise words.
        s = s.split(RegExp(r'\b(on|ref|upi|avl|bal|info)\b',
            caseSensitive: false)).first.trim();
        if (s.isNotEmpty) return _titleCase(s);
      }
    }
    return 'Unknown';
  }

  static String _titleCase(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w.length <= 3
          ? w.toUpperCase()
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  static const _rules = <String, List<String>>{
    'Food': [
      'swiggy', 'zomato', 'ubereats', 'dominos', 'kfc', 'mcdonald',
      'restaurant', 'cafe', 'food', 'pizza', 'biryani', 'talabat', 'noon food'
    ],
    'Fuel': [
      'fuel', 'petrol', 'diesel', 'hpcl', 'bpcl', 'iocl', 'indian oil',
      'shell', 'adnoc', 'eppco', 'gas station', 'bharat petroleum'
    ],
    'Groceries': [
      'bigbasket', 'grofers', 'blinkit', 'dmart', 'supermarket', 'grocery',
      'lulu', 'carrefour', 'spar', 'reliance fresh', 'zepto'
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'noon', 'shein', 'mall',
      'store', 'retail', 'lifestyle', 'namshi'
    ],
    'Bills': [
      'electricity', 'water', 'recharge', 'postpaid', 'broadband', 'wifi',
      'airtel', 'jio', 'vodafone', 'du ', 'etisalat', 'dewa', 'bill', 'utility'
    ],
    'Transport': [
      'uber', 'ola', 'careem', 'metro', 'cab', 'taxi', 'irctc', 'railway',
      'bus', 'parking', 'toll', 'salik'
    ],
    'Entertainment': [
      'netflix', 'spotify', 'prime video', 'hotstar', 'bookmyshow', 'cinema',
      'youtube', 'disney', 'game'
    ],
    'Health': [
      'pharmacy', 'hospital', 'clinic', 'medical', 'apollo', 'medplus',
      'aster', 'doctor', 'lab'
    ],
    'Transfers': ['upi', 'imps', 'neft', 'transfer', 'sent to', 'vpa'],
  };

  static String _categorise(String body, String merchant) {
    final hay = '$merchant $body';
    for (final entry in _rules.entries) {
      for (final kw in entry.value) {
        if (hay.contains(kw)) return entry.key;
      }
    }
    return 'Other';
  }
}
