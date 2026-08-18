import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';

/// Builds a compact, base-currency spending summary for the AI features (the
/// insights coach and the "Ask your money" chat). All the maths is done locally
/// and for free; the AI only narrates it.
///
/// Top-level `income`/`expense`/`balance`/`byCategory` are ALL-TIME totals over
/// every recorded transaction — kept stable because the insights coach (and its
/// cache signature) reads them. `periods` adds date-ranged buckets so a period
/// question ("how much this month?") is answered with that period's figure, not
/// the all-time total. [language] is the BCP-47 code the AI answers in;
/// [recentCount] caps how many recent transactions are sent.
Future<Map<String, dynamic>> buildSpendingSummary({
  required String language,
  int recentCount = 15,
}) async {
  final txns = await getIt<TransactionRepository>().getAllWithDetails();
  final base = await getIt<CurrencyRepository>().getBase();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last30Start = today.subtract(const Duration(days: 29));
  final thisMonthStart = DateTime(now.year, now.month);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

  final all = _Bucket();
  final last30 = _Bucket();
  final thisMonth = _Bucket();
  final lastMonth = _Bucket();

  for (final t in txns) {
    all.add(t);
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    if (!d.isBefore(last30Start)) last30.add(t);
    if (!d.isBefore(thisMonthStart)) thisMonth.add(t);
    if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
      lastMonth.add(t);
    }
  }

  final recent = txns.reversed
      .take(recentCount)
      .map(
        (t) => {
          'category': t.categoryName,
          'amount': _round(t.amountInBase),
          'type': t.type,
          'date': _ymd(t.date),
        },
      )
      .toList();

  return {
    'language': language,
    'baseCurrency': base?.currencyCode ?? '',
    'today': _ymd(today),
    // All-time totals (what the insights coach + cache signature read).
    'income': _round(all.income),
    'expense': _round(all.expense),
    'balance': _round(all.income - all.expense),
    'byCategory': all.categoryList(),
    // Date-ranged buckets so period questions get the right window.
    'periods': {
      'last30Days': last30.toJson(
        from: _ymd(last30Start),
        to: _ymd(today),
        withCategories: true,
      ),
      'thisCalendarMonth': thisMonth.toJson(
        from: _ymd(thisMonthStart),
        to: _ymd(today),
        withCategories: true,
      ),
      'lastCalendarMonth': lastMonth.toJson(
        from: _ymd(lastMonthStart),
        to: _ymd(lastMonthEnd),
        withCategories: false,
      ),
    },
    'recent': recent,
  };
}

/// Accumulates income / expense / per-category expense for one time window.
class _Bucket {
  double income = 0;
  double expense = 0;
  final Map<String, double> byCategory = {};

  void add(TransactionDetails t) {
    if (t.isIncome) income += t.amountInBase;
    if (t.isExpense) {
      expense += t.amountInBase;
      final name = t.categoryName ?? 'Uncategorized';
      byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
    }
  }

  List<Map<String, dynamic>> categoryList() =>
      byCategory.entries
          .map((e) => {'name': e.key, 'amount': _round(e.value)})
          .toList()
        ..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));

  Map<String, dynamic> toJson({
    required String from,
    required String to,
    required bool withCategories,
  }) => {
    'from': from,
    'to': to,
    'income': _round(income),
    'expense': _round(expense),
    if (withCategories) 'byCategory': categoryList(),
  };
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

double _round(double v) => (v * 100).roundToDouble() / 100;
