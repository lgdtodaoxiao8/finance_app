part of 'analytics_cubit.dart';

enum AnalyticsStatus { loading, ready, error }

/// Aggregated spending for one category (amounts already in base currency).
class CategorySpend extends Equatable {
  const CategorySpend({
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
  });

  final String name;
  final Color color;
  final IconData icon;
  final double total;

  @override
  List<Object?> get props => [name, color, icon, total];
}

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.status = AnalyticsStatus.loading,
    this.transactions = const [],
    this.preset = PeriodPreset.month,
    this.customRange,
    this.baseSymbol,
    this.error,
  });

  final AnalyticsStatus status;
  final List<TransactionDetails> transactions;
  final PeriodPreset preset;
  final DateTimeRange? customRange;
  final String? baseSymbol;
  final String? error;

  DateTimeRange get range => computeRange(preset, customRange: customRange);

  List<TransactionDetails> get _filtered =>
      filterByRange(transactions, range.start, range.end);

  double get totalIncome => _filtered
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amountInBase);

  double get totalExpense => _filtered
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amountInBase);

  double get balance => totalIncome - totalExpense;

  /// Expense breakdown by category, biggest first.
  List<CategorySpend> get categorySpends {
    final totals = <String, double>{};
    final meta = <String, ({Color color, IconData icon})>{};

    for (final t in _filtered.where((t) => t.isExpense)) {
      final name = t.categoryName ?? 'Uncategorized';
      totals.update(
        name,
        (v) => v + t.amountInBase,
        ifAbsent: () => t.amountInBase,
      );
      meta[name] ??= (color: t.categoryColor, icon: t.categoryIcon);
    }

    final result = [
      for (final entry in totals.entries)
        CategorySpend(
          name: entry.key,
          color: meta[entry.key]!.color,
          icon: meta[entry.key]!.icon,
          total: entry.value,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  bool get hasExpenses => totalExpense > 0;

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    List<TransactionDetails>? transactions,
    PeriodPreset? preset,
    DateTimeRange? customRange,
    String? baseSymbol,
    String? error,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      preset: preset ?? this.preset,
      customRange: customRange ?? this.customRange,
      baseSymbol: baseSymbol ?? this.baseSymbol,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    preset,
    customRange,
    baseSymbol,
    error,
  ];
}
