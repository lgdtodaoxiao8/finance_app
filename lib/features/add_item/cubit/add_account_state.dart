part of 'add_account_cubit.dart';

enum AddAccountStatus { loading, ready, error }

class AddAccountState extends Equatable {
  const AddAccountState({
    this.status = AddAccountStatus.loading,
    this.currencies = const [],
    this.selectedCurrencyId,
    this.icon,
    this.kind = 'general',
    this.interestRate,
    this.maturityDate,
    this.currentValue,
    this.sending = false,
    this.savedId,
    this.error,
  });

  final AddAccountStatus status;
  final List<Currency> currencies;
  final int? selectedCurrencyId;
  final IconData? icon;

  /// 'general' | 'savings' | 'investment'.
  final String kind;
  final double? interestRate;
  final DateTime? maturityDate;
  final double? currentValue;

  final bool sending;
  final int? savedId;
  final String? error;

  bool get isSavings => kind == 'savings';
  bool get isInvestment => kind == 'investment';

  AddAccountState copyWith({
    AddAccountStatus? status,
    List<Currency>? currencies,
    int? selectedCurrencyId,
    IconData? icon,
    String? kind,
    double? interestRate,
    bool clearInterestRate = false,
    DateTime? maturityDate,
    bool clearMaturityDate = false,
    double? currentValue,
    bool clearCurrentValue = false,
    bool? sending,
    int? savedId,
    String? error,
  }) {
    return AddAccountState(
      status: status ?? this.status,
      currencies: currencies ?? this.currencies,
      selectedCurrencyId: selectedCurrencyId ?? this.selectedCurrencyId,
      icon: icon ?? this.icon,
      kind: kind ?? this.kind,
      interestRate: clearInterestRate
          ? null
          : (interestRate ?? this.interestRate),
      maturityDate: clearMaturityDate
          ? null
          : (maturityDate ?? this.maturityDate),
      currentValue: clearCurrentValue
          ? null
          : (currentValue ?? this.currentValue),
      sending: sending ?? this.sending,
      savedId: savedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currencies,
    selectedCurrencyId,
    icon,
    kind,
    interestRate,
    maturityDate,
    currentValue,
    sending,
    savedId,
    error,
  ];
}
