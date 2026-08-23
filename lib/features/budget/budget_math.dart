import 'package:finance_app/data/models/transaction_details.dart';

/// This CALENDAR month's expenses (base currency): total + per category.
/// Budgets reset with the calendar month, and this is expense-only, so the
/// "no income before payday" issue that affects rolling-month income doesn't
/// apply here.
({double total, Map<int, double> byCategory}) monthlySpend(
  List<TransactionDetails> txns, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final start = DateTime(today.year, today.month);
  var total = 0.0;
  final byCategory = <int, double>{};
  for (final t in txns) {
    if (!t.isExpense || t.isCanceled) continue;
    if (t.date.isBefore(start)) continue;
    total += t.amountInBase;
    final id = t.categoryId;
    if (id != null) byCategory[id] = (byCategory[id] ?? 0) + t.amountInBase;
  }
  return (total: total, byCategory: byCategory);
}
