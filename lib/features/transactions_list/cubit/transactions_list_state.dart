part of 'transactions_list_cubit.dart';

enum TransactionsStatus { loading, ready, error }

class TransactionsListState extends Equatable {
  const TransactionsListState({
    this.status = TransactionsStatus.loading,
    this.transactions = const [],
    this.preset = PeriodPreset.month,
    this.customRange,
    this.error,
  });

  final TransactionsStatus status;
  final List<TransactionDetails> transactions;
  final PeriodPreset preset;
  final DateTimeRange? customRange;
  final String? error;

  /// Active date window for [preset].
  DateTimeRange get range => computeRange(preset, customRange: customRange);

  /// Transactions falling inside [range].
  List<TransactionDetails> get filtered =>
      filterByRange(transactions, range.start, range.end);

  /// Grouped buckets for the current window.
  List<TransactionGroup> get groups =>
      groupTransactions(filtered, range.start, range.end, preset);

  /// Income/expense totals for the current window.
  Map<String, double> get totals => report(filtered);

  TransactionsListState copyWith({
    TransactionsStatus? status,
    List<TransactionDetails>? transactions,
    PeriodPreset? preset,
    DateTimeRange? customRange,
    String? error,
  }) {
    return TransactionsListState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      preset: preset ?? this.preset,
      customRange: customRange ?? this.customRange,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    preset,
    customRange,
    error,
  ];
}
