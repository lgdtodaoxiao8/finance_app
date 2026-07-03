import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/features/settings/cubit/manage_status.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'accounts_state.dart';

/// Lists accounts reactively and deletes them, refusing to delete an account
/// still referenced by transactions.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository) : super(const AccountsState()) {
    _subscription = _repository.watchAll().listen(
      (accounts) =>
          emit(state.copyWith(status: ManageStatus.ready, accounts: accounts)),
      onError: (Object e, StackTrace st) {
        debugPrint('AccountsCubit error: $e\n$st');
        emit(state.copyWith(status: ManageStatus.error));
      },
    );
  }

  final AccountRepository _repository;
  StreamSubscription<List<Account>>? _subscription;

  Future<void> delete(int id) async {
    final count = await _repository.transactionCount(id);
    if (count > 0) {
      emit(
        state.copyWith(
          message: "Can't delete: $count transaction(s) use this account",
        ),
      );
      return;
    }
    await _repository.delete(id);
  }

  void clearMessage() => emit(state.copyWith(message: null));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
