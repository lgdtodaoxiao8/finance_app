import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'base_currency_state.dart';

/// Drives the "set base currency" settings widget: loads the currency list,
/// tracks the selected currency and whether a rate must be entered, and
/// performs the save (optionally setting a rate, then making it the base).
class BaseCurrencyCubit extends Cubit<BaseCurrencyState> {
  BaseCurrencyCubit(this._repository) : super(const BaseCurrencyState()) {
    load();
  }

  final CurrencyRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BaseCurrencyStatus.loading));
    try {
      final all = await _repository.getAll();
      final base = await _repository.getBase();
      emit(
        state.copyWith(
          status: BaseCurrencyStatus.ready,
          currencies: all,
          baseSymbol: base?.currencySymbol,
          isFirstSetup: base == null,
          selectedId: base?.currencyId ?? state.selectedId,
          needToEnterRate: false,
        ),
      );
    } catch (e, st) {
      debugPrint('BaseCurrencyCubit.load error: $e\n$st');
      emit(state.copyWith(status: BaseCurrencyStatus.error, error: '$e'));
    }
  }

  Future<void> selectCurrency(int id) async {
    emit(state.copyWith(selectedId: id));
    // A new currency that has no rate yet needs one before it can be base
    // (unless we're doing the very first setup, which sets rate = 1.0).
    final rate = await _repository.getRate(id);
    emit(state.copyWith(needToEnterRate: !state.isFirstSetup && rate == null));
  }

  void setRate(double? rate) => emit(state.copyWith(rateToBase: rate ?? 0));

  Future<void> submit() async {
    final id = state.selectedId;
    if (id == null) return;

    emit(state.copyWith(sending: true, success: false));
    try {
      final minimumWait = Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (state.needToEnterRate) {
        final rate = state.rateToBase;
        if (rate == null) throw Exception('Rate is null');
        await _repository.setRate(id, rate);
      }
      await _repository.makeBase(id);

      await minimumWait;

      // Refresh data, keeping the success flag so the check icon shows.
      await load();
      emit(state.copyWith(sending: false, success: true));

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed) emit(state.copyWith(success: false));
    } catch (e, st) {
      debugPrint('BaseCurrencyCubit.submit error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
