import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';

/// Builds a compact, base-currency spending summary for the AI features (the
/// insights coach and the "Ask your money" chat). All the maths is done locally
/// and for free; the AI only narrates it. [language] is the BCP-47 code the AI
/// must answer in; [recentCount] caps how many recent transactions are sent.
Future<Map<String, dynamic>> buildSpendingSummary({
  required String language,
  int recentCount = 15,
}) async {
  final txns = await getIt<TransactionRepository>().getAllWithDetails();
  final base = await getIt<CurrencyRepository>().getBase();

  double income = 0, expense = 0;
  final byCategory = <String, double>{};
  for (final t in txns) {
    if (t.isIncome) income += t.amountInBase;
    if (t.isExpense) {
      expense += t.amountInBase;
      final name = t.categoryName ?? 'Uncategorized';
      byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
    }
  }

  final categories =
      byCategory.entries
          .map((e) => {'name': e.key, 'amount': _round(e.value)})
          .toList()
        ..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));

  final recent = txns.reversed
      .take(recentCount)
      .map(
        (t) => {
          'category': t.categoryName,
          'amount': _round(t.amountInBase),
          'type': t.type,
          'date': t.date.toIso8601String().split('T').first,
        },
      )
      .toList();

  return {
    'language': language,
    'baseCurrency': base?.currencyCode ?? '',
    'income': _round(income),
    'expense': _round(expense),
    'balance': _round(income - expense),
    'byCategory': categories,
    'recent': recent,
  };
}

double _round(double v) => (v * 100).roundToDouble() / 100;
