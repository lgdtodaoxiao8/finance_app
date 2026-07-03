import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';

/// One category slice shown on the home-screen widget.
class WidgetCategory {
  const WidgetCategory({
    required this.name,
    required this.value,
    required this.colorValue,
  });

  final String name;
  final double value;
  final int colorValue;
}

/// Compact, glanceable data published to the native home-screen widget.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.income,
    required this.expense,
    required this.balance,
    required this.baseSymbol,
    required this.topCategories,
  });

  final double income;
  final double expense;
  final double balance;
  final String baseSymbol;
  final List<WidgetCategory> topCategories;
}

/// Builds the widget snapshot for the current month window (mirrors the app's
/// analytics), converting everything to the base currency.
WidgetSnapshot buildWidgetSnapshot(
  List<TransactionDetails> transactions, {
  required String baseSymbol,
  int maxCategories = 3,
}) {
  final range = computeRange(PeriodPreset.month);
  final filtered = filterByRange(transactions, range.start, range.end);
  final totals = report(filtered);
  final income = totals['income'] ?? 0;
  final expense = totals['expense'] ?? 0;

  final byCategory = <String, double>{};
  final colors = <String, int>{};
  for (final t in filtered.where((t) => t.isExpense)) {
    final name = t.categoryName ?? 'Uncategorized';
    byCategory.update(
      name,
      (v) => v + t.amountInBase,
      ifAbsent: () => t.amountInBase,
    );
    colors[name] ??= t.categoryColorValue ?? 0xFF9E9E9E;
  }

  final categories =
      [
        for (final e in byCategory.entries)
          WidgetCategory(name: e.key, value: e.value, colorValue: colors[e.key]!),
      ]..sort((a, b) => b.value.compareTo(a.value));

  return WidgetSnapshot(
    income: income,
    expense: expense,
    balance: income - expense,
    baseSymbol: baseSymbol,
    topCategories: categories.take(maxCategories).toList(),
  );
}
