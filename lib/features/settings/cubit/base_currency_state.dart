part of 'base_currency_cubit.dart';

enum BaseCurrencyStatus { loading, ready, error }

class BaseCurrencyState extends Equatable {
  const BaseCurrencyState({
    this.status = BaseCurrencyStatus.loading,
    this.currencies = const [],
    this.selectedId,
    this.baseSymbol,
    this.isFirstSetup = false,
    this.needToEnterRate = false,
    this.rateToBase,
    this.sending = false,
    this.success = false,
    this.error,
  });

  final BaseCurrencyStatus status;
  final List<Currency> currencies;
  final int? selectedId;

  /// Symbol of the currently active base currency (for the rate hint).
  final String? baseSymbol;

  /// True when no base currency exists yet (first-time onboarding).
  final bool isFirstSetup;

  /// True when the selected currency has no rate and one must be entered.
  final bool needToEnterRate;
  final double? rateToBase;

  final bool sending;
  final bool success;
  final String? error;

  Currency? get selected {
    for (final c in currencies) {
      if (c.currencyId == selectedId) return c;
    }
    return null;
  }

  BaseCurrencyState copyWith({
    BaseCurrencyStatus? status,
    List<Currency>? currencies,
    int? selectedId,
    String? baseSymbol,
    bool? isFirstSetup,
    bool? needToEnterRate,
    double? rateToBase,
    bool? sending,
    bool? success,
    String? error,
  }) {
    return BaseCurrencyState(
      status: status ?? this.status,
      currencies: currencies ?? this.currencies,
      selectedId: selectedId ?? this.selectedId,
      baseSymbol: baseSymbol ?? this.baseSymbol,
      isFirstSetup: isFirstSetup ?? this.isFirstSetup,
      needToEnterRate: needToEnterRate ?? this.needToEnterRate,
      rateToBase: rateToBase ?? this.rateToBase,
      sending: sending ?? this.sending,
      success: success ?? this.success,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currencies,
    selectedId,
    baseSymbol,
    isFirstSetup,
    needToEnterRate,
    rateToBase,
    sending,
    success,
    error,
  ];
}
