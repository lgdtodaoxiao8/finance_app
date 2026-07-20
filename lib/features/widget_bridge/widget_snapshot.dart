import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';

/// One category slice shown on the home-screen widget.
class WidgetCategory {
  const WidgetCategory({
    required this.name,
    required this.value,
    required this.colorValue,
    required this.iconCode,
  });

  final String name;
  final double value;
  final int colorValue;

  /// MaterialIcons codepoint — the widget renders the real glyph.
  final int iconCode;
}

/// One recent transaction shown on the large widget.
class WidgetRecent {
  const WidgetRecent({
    required this.name,
    required this.amount,
    required this.isExpense,
    required this.colorValue,
    required this.iconCode,
    required this.dateMs,
  });

  final String name;
  final double amount;
  final bool isExpense;
  final int colorValue;
  final int iconCode;
  final int dateMs;
}

/// Compact, glanceable data published to the native home-screen widget.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.income,
    required this.expense,
    required this.todayExpense,
    required this.balance,
    required this.baseSymbol,
    required this.topCategories,
    required this.recent,
  });

  final double income;
  final double expense;

  /// Spent today — the most glanceable number of all.
  final double todayExpense;
  final double balance;
  final String baseSymbol;
  final List<WidgetCategory> topCategories;
  final List<WidgetRecent> recent;
}

/// Builds the widget snapshot for the current month window (mirrors the app's
/// analytics), converting everything to the base currency.
WidgetSnapshot buildWidgetSnapshot(
  List<TransactionDetails> transactions, {
  required String baseSymbol,
  int maxCategories = 3,
  int maxRecent = 3,
}) {
  final range = computeRange(PeriodPreset.month);
  final filtered = filterByRange(transactions, range.start, range.end);
  final totals = report(filtered);
  final income = totals['income'] ?? 0;
  final expense = totals['expense'] ?? 0;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  var todayExpense = 0.0;
  for (final t in filtered.where((t) => t.isExpense)) {
    if (!t.date.isBefore(todayStart)) todayExpense += t.amountInBase;
  }

  final byCategory = <String, double>{};
  final colors = <String, int>{};
  final icons = <String, int>{};
  for (final t in filtered.where((t) => t.isExpense)) {
    final name = t.categoryName ?? 'Uncategorized';
    byCategory.update(
      name,
      (v) => v + t.amountInBase,
      ifAbsent: () => t.amountInBase,
    );
    colors[name] ??= t.categoryColorValue ?? 0xFF9E9E9E;
    icons[name] ??= t.categoryIconCode ?? 0;
  }

  final categories = [
    for (final e in byCategory.entries)
      WidgetCategory(
        name: e.key,
        value: e.value,
        colorValue: colors[e.key]!,
        iconCode: icons[e.key]!,
      ),
  ]..sort((a, b) => b.value.compareTo(a.value));

  final newestFirst = [...transactions]
    ..sort((a, b) => b.date.compareTo(a.date));
  final recent = [
    for (final t in newestFirst.take(maxRecent))
      WidgetRecent(
        name: t.categoryName ?? 'Uncategorized',
        amount: t.amountInBase,
        isExpense: t.isExpense,
        colorValue: t.categoryColorValue ?? 0xFF9E9E9E,
        iconCode: t.categoryIconCode ?? 0,
        dateMs: t.date.millisecondsSinceEpoch,
      ),
  ];

  return WidgetSnapshot(
    income: income,
    expense: expense,
    todayExpense: todayExpense,
    balance: income - expense,
    baseSymbol: baseSymbol,
    topCategories: categories.take(maxCategories).toList(),
    recent: recent,
  );
}
