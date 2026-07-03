part of 'add_account_cubit.dart';

enum AddAccountStatus { loading, ready, error }

class AddAccountState extends Equatable {
  const AddAccountState({
    this.status = AddAccountStatus.loading,
    this.currencies = const [],
    this.selectedCurrencyId,
    this.icon,
    this.sending = false,
    this.savedId,
    this.error,
  });

  final AddAccountStatus status;
  final List<Currency> currencies;
  final int? selectedCurrencyId;
  final IconData? icon;
  final bool sending;
  final int? savedId;
  final String? error;

  AddAccountState copyWith({
    AddAccountStatus? status,
    List<Currency>? currencies,
    int? selectedCurrencyId,
    IconData? icon,
    bool? sending,
    int? savedId,
    String? error,
  }) {
    return AddAccountState(
      status: status ?? this.status,
      currencies: currencies ?? this.currencies,
      selectedCurrencyId: selectedCurrencyId ?? this.selectedCurrencyId,
      icon: icon ?? this.icon,
      sending: sending ?? this.sending,
      savedId: savedId ?? this.savedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currencies,
    selectedCurrencyId,
    icon,
    sending,
    savedId,
    error,
  ];
}
