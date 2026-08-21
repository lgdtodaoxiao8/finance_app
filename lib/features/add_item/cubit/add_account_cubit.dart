import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_account_state.dart';

class AddAccountCubit extends Cubit<AddAccountState> {
  AddAccountCubit(
    this._accountRepository,
    this._currencyRepository, {
    Account? initial,
  }) : _editingId = initial?.accountId,
       super(
         initial == null
             ? const AddAccountState()
             : AddAccountState(
                 icon: initial.accountIcon,
                 selectedCurrencyId: initial.currencyId,
                 kind: initial.accountKind,
                 interestRate: initial.interestRate,
                 maturityDate: initial.maturityDate,
                 currentValue: initial.currentValue,
               ),
       ) {
    loadCurrencies();
  }

  final AccountRepository _accountRepository;
  final CurrencyRepository _currencyRepository;
  final int? _editingId;

  bool get isEditing => _editingId != null;

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

  /// Switches the account kind, clearing the fields that don't apply to it so
  /// e.g. a rate left over from "savings" isn't saved onto an "investment".
  void setKind(String kind) => emit(
    state.copyWith(
      kind: kind,
      clearInterestRate: kind != 'savings',
      clearMaturityDate: kind != 'savings',
      clearCurrentValue: kind != 'investment',
    ),
  );

  void setInterestRate(double? rate) => rate == null
      ? emit(state.copyWith(clearInterestRate: true))
      : emit(state.copyWith(interestRate: rate));

  void setMaturityDate(DateTime? date) => date == null
      ? emit(state.copyWith(clearMaturityDate: true))
      : emit(state.copyWith(maturityDate: date));

  void setCurrentValue(double? value) => value == null
      ? emit(state.copyWith(clearCurrentValue: true))
      : emit(state.copyWith(currentValue: value));

  Future<void> save(String name) async {
    final currencyId = state.selectedCurrencyId;
    final icon = state.icon;
    if (currencyId == null || icon == null) return;

    // Only persist the extras that belong to the chosen kind.
    final kind = state.kind;
    final interestRate = kind == 'savings' ? state.interestRate : null;
    final maturityDate = kind == 'savings' ? state.maturityDate : null;
    final currentValue = kind == 'investment' ? state.currentValue : null;

    emit(state.copyWith(sending: true));
    try {
      final int id;
      if (_editingId case final editingId?) {
        await _accountRepository.update(
          id: editingId,
          name: name,
          currencyId: currencyId,
          iconCodePoint: icon.codePoint,
          kind: kind,
          interestRate: interestRate,
          maturityDate: maturityDate,
          currentValue: currentValue,
        );
        id = editingId;
      } else {
        id = await _accountRepository.add(
          name: name,
          currencyId: currencyId,
          iconCodePoint: icon.codePoint,
          kind: kind,
          interestRate: interestRate,
          maturityDate: maturityDate,
          currentValue: currentValue,
        );
      }
      emit(state.copyWith(sending: false, savedId: id));
    } catch (e, st) {
      debugPrint('AddAccountCubit.save error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
