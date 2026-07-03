import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_currency_state.dart';

/// Adds an exchange rate to a rate-less currency, or — when no base currency
/// exists yet — turns the picked currency into the base.
class AddCurrencyCubit extends Cubit<AddCurrencyState> {
  AddCurrencyCubit(this._repository) : super(const AddCurrencyState()) {
    load();
  }

  final CurrencyRepository _repository;

  Future<void> load() async {
    try {
      final currencies = await _repository.getWithoutRate();
      final base = await _repository.getBase();
      emit(
        state.copyWith(
          status: AddCurrencyStatus.ready,
          currencies: currencies,
          selectedId: currencies.isNotEmpty
              ? currencies.first.currencyId
              : null,
          baseIsNotSet: base == null,
          baseSymbol: base?.currencySymbol,
        ),
      );
    } catch (e, st) {
      debugPrint('AddCurrencyCubit.load error: $e\n$st');
      emit(state.copyWith(status: AddCurrencyStatus.error, error: '$e'));
    }
  }

  void selectCurrency(int id) => emit(state.copyWith(selectedId: id));
  void setRate(double? rate) => emit(state.copyWith(rate: rate ?? 0));

  Future<void> save() async {
    final id = state.selectedId;
    if (id == null) return;

    emit(state.copyWith(sending: true));
    try {
      if (state.baseIsNotSet) {
        await _repository.makeBase(id);
      } else {
        await _repository.setRate(id, state.rate);
      }
      emit(state.copyWith(sending: false, savedId: id));
    } catch (e, st) {
      debugPrint('AddCurrencyCubit.save error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
