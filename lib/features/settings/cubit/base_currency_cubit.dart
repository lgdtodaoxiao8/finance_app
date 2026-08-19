import 'package:equatable/equatable.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
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
    final base = await _repository.getBase();
    final firstSetup = state.isFirstSetup;
    final switchingToOther = base?.currencyId != id;
    final selected = state.currencies.firstWhere(
      (c) => c.currencyId == id,
      orElse: () => state.currencies.first,
    );
    final hasRate = selected.currencyRateToBase != null;
    // A rate is only needed to switch base to a RATE-LESS currency. A currency
    // that already has a rate just rebases everything by that rate — no typing,
    // which is the "couple of clicks" flow. (Correcting an existing rate is a
    // separate action, so history stays frozen — see setRate.)
    emit(
      state.copyWith(
        needToEnterRate: !firstSetup && switchingToOther && !hasRate,
      ),
    );
    // Commit immediately (no rate entry) for the first setup and for switching
    // to a currency that already has a rate — pick it, it becomes the base.
    if (firstSetup || (switchingToOther && hasRate)) await submit();
  }

  void setRate(double? rate) => emit(state.copyWith(rateToBase: rate ?? 0));

  Future<void> submit() async {
    final id = state.selectedId;
    if (id == null || state.sending) return;

    emit(state.copyWith(sending: true, success: false));
    try {
      final minimumWait = Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      final previousBase = await _repository.getBase();
      if (state.needToEnterRate) {
        final rate = state.rateToBase;
        if (rate == null || rate == 0) throw Exception('Rate is null');
        // The user entered "1 currentBase = rate selected" (e.g. 1 USD = 475
        // KZT). rate_to_base stores "value of 1 selected in base", i.e. the
        // reciprocal (1 KZT = 1/475 USD). Storing `rate` directly inverted the
        // whole conversion.
        await _repository.setRate(id, 1 / rate);
      }
      // Factor to re-express old-base amounts in the new base (= makeBase's
      // rebase multiplier). Captured before makeBase resets the rate to 1.0.
      double? amountMultiplier;
      if (previousBase != null && previousBase.currencyId != id) {
        final newBaseRate = await _repository.getRate(id);
        if (newBaseRate != null && newBaseRate != 0) {
          amountMultiplier = 1 / newBaseRate;
        }
      }
      await _repository.makeBase(id);

      // Re-price the per-widget configured amounts (presets / fixed / steps)
      // into the new base so they stay meaningful after the switch.
      if (amountMultiplier != null && getIt.isRegistered<WidgetService>()) {
        await getIt<WidgetService>().rescaleConfiguredAmounts(amountMultiplier);
      }

      // Persist the new base + rates as a synced preference so the choice
      // travels to the user's other devices.
      if (getIt.isRegistered<SettingsService>()) {
        await getIt<SettingsService>().recordCurrencyConfig();
      }

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
