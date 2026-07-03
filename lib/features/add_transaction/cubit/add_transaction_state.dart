part of 'add_transaction_cubit.dart';

enum AddTransactionStatus { loading, ready, error }

class AddTransactionState extends Equatable {
  const AddTransactionState({
    this.status = AddTransactionStatus.loading,
    this.accounts = const [],
    this.categories = const [],
    this.currencies = const [],
    this.type = 'expense',
    this.typeIndex = 0,
    this.accountId,
    this.accountDestinationId,
    this.categoryId,
    this.currencyId,
    this.date,
    this.editingId,
    this.initialAmount,
    this.initialNote,
    this.sending = false,
    this.saved = false,
    this.loadError,
  });

  final AddTransactionStatus status;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Currency> currencies;

  final String type; // expense | income | transfer
  final int typeIndex;

  final int? accountId;
  final int? accountDestinationId;
  final int? categoryId;
  final int? currencyId;
  final DateTime? date;

  /// Non-null when editing an existing transaction.
  final int? editingId;
  final String? initialAmount;
  final String? initialNote;

  final bool sending;
  final bool saved;
  final String? loadError;

  bool get isTransfer => type == 'transfer';
  bool get isEditing => editingId != null;

  /// A blocking validation message for the current selection, or null if the
  /// transaction can be saved. Recomputed from state (never sticky).
  String? get validationError {
    if (accounts.isEmpty) return 'You have not added any account';
    if (categories.isEmpty) return 'You have not added any category';
    if (currencies.isEmpty) return 'You have not added any currency';
    if (isTransfer) {
      if (accounts.length < 2) return 'You have no second account to transfer';
      if (accountId == accountDestinationId) {
        return 'Account departure and destination must be different';
      }
    }
    return null;
  }

  AddTransactionState copyWith({
    AddTransactionStatus? status,
    List<Account>? accounts,
    List<Category>? categories,
    List<Currency>? currencies,
    String? type,
    int? typeIndex,
    int? accountId,
    int? accountDestinationId,
    int? categoryId,
    int? currencyId,
    DateTime? date,
    int? editingId,
    String? initialAmount,
    String? initialNote,
    bool? sending,
    bool? saved,
    String? loadError,
  }) {
    return AddTransactionState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      currencies: currencies ?? this.currencies,
      type: type ?? this.type,
      typeIndex: typeIndex ?? this.typeIndex,
      accountId: accountId ?? this.accountId,
      accountDestinationId: accountDestinationId ?? this.accountDestinationId,
      categoryId: categoryId ?? this.categoryId,
      currencyId: currencyId ?? this.currencyId,
      date: date ?? this.date,
      editingId: editingId ?? this.editingId,
      initialAmount: initialAmount ?? this.initialAmount,
      initialNote: initialNote ?? this.initialNote,
      sending: sending ?? this.sending,
      saved: saved ?? this.saved,
      loadError: loadError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accounts,
    categories,
    currencies,
    type,
    typeIndex,
    accountId,
    accountDestinationId,
    categoryId,
    currencyId,
    date,
    editingId,
    initialAmount,
    initialNote,
    sending,
    saved,
    loadError,
  ];
}
