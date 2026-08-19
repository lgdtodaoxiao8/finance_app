import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';

/// Builds a compact, base-currency spending summary for the AI features (the
/// insights coach and the "Ask your money" chat). All the maths is done locally
/// and for free; the AI only narrates it.
///
/// Top-level `income`/`expense`/`balance`/`byCategory` are ALL-TIME totals over
/// every recorded transaction (what the "Ask your money" chat + the cache
/// signature read) — UNLESS [monthlyDigest] is set, in which case they cover the
/// last 30 days and `period`/`netWorth` are added: the insights coach is a
/// MONTHLY digest, so it must not narrate all-time figures as if they were the
/// period. `dataFrom`/`dataTo`/`transactionCount` tell the model what it does
/// and doesn't cover, and `periods` holds date-ranged buckets — so period
/// questions get the right window and questions outside the data can be refused
/// instead of hallucinated. [language] is the BCP-47 code the AI answers in;
/// [recentCount] caps the recent list.
Future<Map<String, dynamic>> buildSpendingSummary({
  required String language,
  int recentCount = 15,
  bool monthlyDigest = false,
}) async {
  final txns = await getIt<TransactionRepository>().getAllWithDetails();
  final base = await getIt<CurrencyRepository>().getBase();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last7Start = today.subtract(const Duration(days: 6));
  final last30Start = today.subtract(const Duration(days: 29));
  // The app's canonical rolling "Month" window (a month ago → today) — the SAME
  // one the Home tiles/stat strip/dashboard use, so the digest never disagrees
  // with them (last-30-days can miss a boundary payday and read negative).
  final rollingMonthStart = DateTime(now.year, now.month - 1, now.day);
  final thisMonthStart = DateTime(now.year, now.month);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
  final thisYearStart = DateTime(now.year);

  final all = _Bucket();
  final last7 = _Bucket();
  final last30 = _Bucket();
  final rollingMonth = _Bucket();
  final thisMonth = _Bucket();
  final lastMonth = _Bucket();
  final thisYear = _Bucket();

  DateTime? earliest, latest;
  for (final t in txns) {
    all.add(t);
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    if (earliest == null || d.isBefore(earliest)) earliest = d;
    if (latest == null || d.isAfter(latest)) latest = d;
    if (!d.isBefore(last7Start)) last7.add(t);
    if (!d.isBefore(last30Start)) last30.add(t);
    if (!d.isBefore(rollingMonthStart)) rollingMonth.add(t);
    if (!d.isBefore(thisMonthStart)) thisMonth.add(t);
    if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
      lastMonth.add(t);
    }
    if (!d.isBefore(thisYearStart)) thisYear.add(t);
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

  final primary = monthlyDigest ? rollingMonth : all;
  final map = <String, dynamic>{
    'language': language,
    'baseCurrency': base?.currencyCode ?? '',
    'today': _ymd(today),
    'income': _round(primary.income),
    'expense': _round(primary.expense),
    'balance': _round(primary.income - primary.expense),
    'byCategory': primary.categoryList(),
    'recent': recent,
  };

  if (monthlyDigest) {
    // A focused monthly picture: the figures above are the last 30 days, plus
    // the overall net worth. Deliberately NO year-spanning periods/coverage —
    // the digest must not slip into narrating all-time numbers.
    map['period'] = {'from': _ymd(rollingMonthStart), 'to': _ymd(today)};
    map['netWorth'] = _round(all.income - all.expense);
  } else {
    // Chat: all-time primary + coverage + date-ranged buckets, so period
    // questions land on the right window and out-of-range ones are refused.
    map['transactionCount'] = txns.length;
    map['dataFrom'] = earliest == null ? null : _ymd(earliest);
    map['dataTo'] = latest == null ? null : _ymd(latest);
    map['periods'] = {
      'last7Days': last7.toJson(
        from: _ymd(last7Start),
        to: _ymd(today),
        withCategories: true,
      ),
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
      'thisYear': thisYear.toJson(
        from: _ymd(thisYearStart),
        to: _ymd(today),
        withCategories: false,
      ),
    };
  }
  return map;
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
    // Net for the window (income − expense) so goal / savings-rate maths is
    // exact without the model having to subtract.
    'net': _round(income - expense),
    if (withCategories) 'byCategory': categoryList(),
  };
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

double _round(double v) => (v * 100).roundToDouble() / 100;
