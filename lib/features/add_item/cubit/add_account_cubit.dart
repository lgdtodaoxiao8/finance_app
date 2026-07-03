import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_account_state.dart';

class AddAccountCubit extends Cubit<AddAccountState> {
  AddAccountCubit(this._accountRepository, this._currencyRepository)
    : super(const AddAccountState()) {
    loadCurrencies();
  }

  final AccountRepository _accountRepository;
  final CurrencyRepository _currencyRepository;

  Future<void> loadCurrencies() async {
    try {
      final currencies = await _currencyRepository.getWithRate();
      emit(
        state.copyWith(
          status: AddAccountStatus.ready,
          currencies: currencies,
          selectedCurrencyId:
              state.selectedCurrencyId ??
              (currencies.isNotEmpty ? currencies.first.currencyId : null),
        ),
      );
    } catch (e, st) {
      debugPrint('AddAccountCubit.loadCurrencies error: $e\n$st');
      emit(state.copyWith(status: AddAccountStatus.error, error: '$e'));
    }
  }

  void setCurrency(int id) => emit(state.copyWith(selectedCurrencyId: id));
  void setIcon(IconData icon) => emit(state.copyWith(icon: icon));

  Future<void> save(String name) async {
    final currencyId = state.selectedCurrencyId;
    final icon = state.icon;
    if (currencyId == null || icon == null) return;

    emit(state.copyWith(sending: true));
    try {
      final id = await _accountRepository.add(
        name: name,
        currencyId: currencyId,
        iconCodePoint: icon.codePoint,
      );
      emit(state.copyWith(sending: false, savedId: id));
    } catch (e, st) {
      debugPrint('AddAccountCubit.save error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
