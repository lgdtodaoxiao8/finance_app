/// Whether a quick-add widget group logs money going OUT (expense) or coming
/// IN (income). A whole widget instance is one flow — the home screen shows a
/// separate "Quick Expense" / "Quick Income" tile, each bound to a group of
/// this flow. Drives the logged transaction `type`, the analytics side that is
/// bumped, and the widget's visual accent (neutral vs green "+").
enum WidgetFlow {
  expense,
  income;

  bool get isIncome => this == WidgetFlow.income;

  /// The transaction `type` string this flow writes.
  String get transactionType => this == WidgetFlow.income ? 'income' : 'expense';

  static WidgetFlow fromName(String? name) => WidgetFlow.values.firstWhere(
    (f) => f.name == name,
    // Legacy groups (and the migrated default group) predate flow → expense.
    orElse: () => WidgetFlow.expense,
  );
}
