import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_transaction_state.dart';

const _typeIndex = {'expense': 0, 'income': 1, 'transfer': 2};

class AddTransactionCubit extends Cubit<AddTransactionState> {
  AddTransactionCubit(
    this._accountRepository,
    this._categoryRepository,
    this._currencyRepository,
    this._transactionRepository, {
    TransactionDetails? existing,
    String? presetType,
    int? presetCategoryId,
  }) : _existing = existing,
       _presetType = presetType,
       _presetCategoryId = presetCategoryId,
       super(const AddTransactionState()) {
    load();
  }

  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CurrencyRepository _currencyRepository;
  final TransactionRepository _transactionRepository;

  /// The transaction being edited, or null when creating a new one.
  final TransactionDetails? _existing;

  /// Prefill for a brand-new transaction opened from a widget quick-add: the
  /// flow's type ('expense'/'income') and a pre-selected category.
  final String? _presetType;
  final int? _presetCategoryId;

  Future<void> load() async {
    try {
      final currencies = await _currencyRepository.getWithRate();
      final accounts = await _accountRepository.getAll();
      final categories = await _categoryRepository.getAll();

      final existing = _existing;
      if (existing != null) {
        // Editing: prefill every field from the existing transaction.
        final amount = existing.amount;
        emit(
          state.copyWith(
            status: AddTransactionStatus.ready,
            accounts: accounts,
            categories: categories,
            currencies: currencies,
            type: existing.type,
            typeIndex: _typeIndex[existing.type] ?? 0,
            accountId: existing.accountId,
            accountDestinationId: existing.accountDestinationId,
            categoryId: existing.categoryId,
            currencyId: existing.currencyId,
            date: existing.date,
            editingId: existing.id,
            initialAmount: amount % 1 == 0
                ? amount.toInt().toString()
                : amount.toString(),
            initialNote: existing.note ?? '',
          ),
        );
      } else {
        // New transaction — default to expense, or a widget-supplied preset.
        final type = _presetType ?? 'expense';
        emit(
          state.copyWith(
            status: AddTransactionStatus.ready,
            accounts: accounts,
            categories: categories,
            currencies: currencies,
            type: type,
            typeIndex: _typeIndex[type] ?? 0,
            accountId: accounts.isNotEmpty ? accounts.first.id : null,
            accountDestinationId: accounts.length > 1 ? accounts[1].id : null,
            categoryId: _pickCategory(
              type,
              categories,
              preferred: _presetCategoryId,
            ),
            currencyId: currencies.isNotEmpty ? currencies.first.id : null,
            date: DateTime.now(),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('AddTransactionCubit.load error: $e\n$st');
      emit(state.copyWith(status: AddTransactionStatus.error, loadError: '$e'));
    }
  }

  void setType(String type, int index) {
    int? destination = state.accountDestinationId;
    if (type == 'transfer' &&
        destination == null &&
        state.accounts.length > 1) {
      destination = state.accounts[1].id;
    }
    emit(
      state.copyWith(
        type: type,
        typeIndex: index,
        accountDestinationId: destination,
        // Keep the selected category valid for the tab: expense tab → an expense
        // category, income tab → an income one.
        categoryId: _pickCategory(
          type,
          state.categories,
          preferred: state.categoryId,
        ),
      ),
    );
  }

  /// A category id valid for [type] — keeps [preferred] if it matches the type's
  /// kind, else falls back to the first matching category (null if none).
  static int? _pickCategory(
    String type,
    List<Category> cats, {
    int? preferred,
  }) {
    if (type == 'transfer') {
      return preferred ?? (cats.isEmpty ? null : cats.first.categoryId);
    }
    final wantIncome = type == 'income';
    final matching = cats.where((c) => c.isIncome == wantIncome);
    if (preferred != null &&
        matching.any((c) => c.categoryId == preferred)) {
      return preferred;
    }
    return matching.isEmpty ? null : matching.first.categoryId;
  }

  void setAccount(int id) => emit(state.copyWith(accountId: id));
  void setAccountDestination(int id) =>
      emit(state.copyWith(accountDestinationId: id));
  void setCategory(int id) => emit(state.copyWith(categoryId: id));
  void setCurrency(int id) => emit(state.copyWith(currencyId: id));
  void setDate(DateTime date) => emit(state.copyWith(date: date));

  Future<void> reloadAccounts([int? selectId]) async {
    final accounts = await _accountRepository.getAll();
    emit(
      state.copyWith(
        accounts: accounts,
        accountId: selectId ?? state.accountId,
      ),
    );
  }

  Future<void> reloadCategories([int? selectId]) async {
    final categories = await _categoryRepository.getAll();
    emit(
      state.copyWith(
        categories: categories,
        categoryId: selectId ?? state.categoryId,
      ),
    );
  }

  Future<void> reloadCurrencies([int? selectId]) async {
    final currencies = await _currencyRepository.getWithRate();
    emit(
      state.copyWith(
        currencies: currencies,
        currencyId: selectId ?? state.currencyId,
      ),
    );
  }

  Future<void> add({required double amount, required String note}) async {
    if (state.validationError != null) return;
    final accountId = state.accountId;
    final categoryId = state.categoryId;
    final currencyId = state.currencyId;
    if (accountId == null || categoryId == null || currencyId == null) return;

    emit(state.copyWith(sending: true));
    try {
      final destination = state.isTransfer ? state.accountDestinationId : null;
      final editingId = state.editingId;
      if (editingId != null) {
        await _transactionRepository.update(
          id: editingId,
          accountId: accountId,
          accountDestinationId: destination,
          categoryId: categoryId,
          currencyId: currencyId,
          amount: amount,
          date: state.date ?? DateTime.now(),
          note: note,
          type: state.type,
        );
      } else {
        await _transactionRepository.add(
          accountId: accountId,
          accountDestinationId: destination,
          categoryId: categoryId,
          currencyId: currencyId,
          amount: amount,
          date: state.date ?? DateTime.now(),
          note: note,
          type: state.type,
        );
      }
      emit(state.copyWith(sending: false, saved: true));
    } catch (e, st) {
      debugPrint('AddTransactionCubit.add error: $e\n$st');
      emit(state.copyWith(sending: false));
    }
  }

  Future<void> deleteTransaction() async {
    final editingId = state.editingId;
    if (editingId == null) return;

    emit(state.copyWith(sending: true));
    try {
      await _transactionRepository.delete(editingId);
      emit(state.copyWith(sending: false, saved: true));
    } catch (e, st) {
      debugPrint('AddTransactionCubit.deleteTransaction error: $e\n$st');
      emit(state.copyWith(sending: false));
    }
  }
}
