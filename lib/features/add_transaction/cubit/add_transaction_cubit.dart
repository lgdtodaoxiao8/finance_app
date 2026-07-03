import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_transaction_state.dart';

class AddTransactionCubit extends Cubit<AddTransactionState> {
  AddTransactionCubit(
    this._accountRepository,
    this._categoryRepository,
    this._currencyRepository,
    this._transactionRepository,
  ) : super(const AddTransactionState()) {
    load();
  }

  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CurrencyRepository _currencyRepository;
  final TransactionRepository _transactionRepository;

  Future<void> load() async {
    try {
      final currencies = await _currencyRepository.getWithRate();
      final accounts = await _accountRepository.getAll();
      final categories = await _categoryRepository.getAll();

      emit(
        state.copyWith(
          status: AddTransactionStatus.ready,
          accounts: accounts,
          categories: categories,
          currencies: currencies,
          accountId: accounts.isNotEmpty ? accounts.first.id : null,
          accountDestinationId: accounts.length > 1 ? accounts[1].id : null,
          categoryId: categories.isNotEmpty ? categories.first.id : null,
          currencyId: currencies.isNotEmpty ? currencies.first.id : null,
          date: DateTime.now(),
        ),
      );
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
      ),
    );
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
      await _transactionRepository.add(
        accountId: accountId,
        accountDestinationId: state.isTransfer
            ? state.accountDestinationId
            : null,
        categoryId: categoryId,
        currencyId: currencyId,
        amount: amount,
        date: state.date ?? DateTime.now(),
        note: note,
        type: state.type,
      );
      emit(state.copyWith(sending: false, saved: true));
    } catch (e, st) {
      debugPrint('AddTransactionCubit.add error: $e\n$st');
      emit(state.copyWith(sending: false));
    }
  }
}
