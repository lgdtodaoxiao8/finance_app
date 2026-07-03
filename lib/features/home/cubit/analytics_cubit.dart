import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'analytics_state.dart';

/// Feeds the analytics dashboard: reactive transactions + base-currency symbol,
/// plus the selected period. All heavy aggregation lives in [AnalyticsState].
class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._transactionRepository, this._currencyRepository)
    : super(const AnalyticsState()) {
    _subscribe();
  }

  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;
  StreamSubscription<List<TransactionDetails>>? _txSubscription;
  StreamSubscription<List<dynamic>>? _currencySubscription;

  void _subscribe() {
    _txSubscription = _transactionRepository.watchAllWithDetails().listen(
      (transactions) => emit(
        state.copyWith(
          status: AnalyticsStatus.ready,
          transactions: transactions,
        ),
      ),
      onError: (Object e, StackTrace st) {
        debugPrint('AnalyticsCubit stream error: $e\n$st');
        emit(state.copyWith(status: AnalyticsStatus.error, error: '$e'));
      },
    );

    _currencySubscription = _currencyRepository.watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency) {
          emit(state.copyWith(baseSymbol: c.currencySymbol));
          return;
        }
      }
    });
  }

  void selectPreset(PeriodPreset preset) {
    if (preset == state.preset) return;
    emit(state.copyWith(preset: preset));
  }

  void selectCustomRange(DateTimeRange range) {
    emit(
      state.copyWith(
        preset: PeriodPreset.custom,
        customRange: DateTimeRange(
          start: startOfDay(range.start),
          end: endOfDay(range.end),
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _txSubscription?.cancel();
    _currencySubscription?.cancel();
    return super.close();
  }
}
