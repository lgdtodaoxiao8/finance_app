part of 'add_currency_cubit.dart';

enum AddCurrencyStatus { loading, ready, error }

class AddCurrencyState extends Equatable {
  const AddCurrencyState({
    this.status = AddCurrencyStatus.loading,
    this.currencies = const [],
    this.selectedId,
    this.baseSymbol,
    this.baseIsNotSet = false,
    this.rate = 0,
    this.sending = false,
    this.savedId,
    this.error,
  });

  final AddCurrencyStatus status;
  final List<Currency> currencies;
  final int? selectedId;
  final String? baseSymbol;

  /// True when no base currency exists yet → this screen sets the base.
  final bool baseIsNotSet;
  final double rate;
  final bool sending;
  final int? savedId;
  final String? error;

  Currency? get selected {
    for (final c in currencies) {
      if (c.currencyId == selectedId) return c;
    }
    return null;
  }

  AddCurrencyState copyWith({
    AddCurrencyStatus? status,
    List<Currency>? currencies,
    int? selectedId,
    String? baseSymbol,
    bool? baseIsNotSet,
    double? rate,
    bool? sending,
    int? savedId,
    String? error,
  }) {
    return AddCurrencyState(
      status: status ?? this.status,
      currencies: currencies ?? this.currencies,
      selectedId: selectedId ?? this.selectedId,
      baseSymbol: baseSymbol ?? this.baseSymbol,
      baseIsNotSet: baseIsNotSet ?? this.baseIsNotSet,
      rate: rate ?? this.rate,
      sending: sending ?? this.sending,
      savedId: savedId ?? this.savedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currencies,
    selectedId,
    baseSymbol,
    baseIsNotSet,
    rate,
    sending,
    savedId,
    error,
  ];
}
