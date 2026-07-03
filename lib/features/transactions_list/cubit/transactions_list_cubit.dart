import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'transactions_list_state.dart';

/// Drives the transactions list: subscribes to the reactive repository stream
/// so the list refreshes automatically when a transaction is added elsewhere,
/// and holds the selected period window.
class TransactionsListCubit extends Cubit<TransactionsListState> {
  TransactionsListCubit(this._repository, this._currencyRepository)
    : super(const TransactionsListState()) {
    _subscribe();
  }

  final TransactionRepository _repository;
  final CurrencyRepository _currencyRepository;
  StreamSubscription<List<TransactionDetails>>? _subscription;
  StreamSubscription<List<dynamic>>? _currencySubscription;

  void _subscribe() {
    _subscription = _repository.watchAllWithDetails().listen(
      (transactions) => emit(
        state.copyWith(
          status: TransactionsStatus.ready,
          transactions: transactions,
        ),
      ),
      onError: (Object e, StackTrace st) {
        debugPrint('TransactionsListCubit stream error: $e\n$st');
        emit(state.copyWith(status: TransactionsStatus.error, error: '$e'));
      },
    );

    // Keep the base-currency symbol (used to label totals) in sync.
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
    _subscription?.cancel();
    _currencySubscription?.cancel();
    return super.close();
  }
}
