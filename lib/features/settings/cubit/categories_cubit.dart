import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/features/settings/cubit/manage_status.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'categories_state.dart';

/// Lists categories reactively and deletes them, refusing to delete a category
/// still referenced by transactions.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState()) {
    _subscription = _repository.watchAll().listen(
      (categories) => emit(
        state.copyWith(status: ManageStatus.ready, categories: categories),
      ),
      onError: (Object e, StackTrace st) {
        debugPrint('CategoriesCubit error: $e\n$st');
        emit(state.copyWith(status: ManageStatus.error));
      },
    );
  }

  final CategoryRepository _repository;
  StreamSubscription<List<Category>>? _subscription;

  Future<void> delete(int id) async {
    final count = await _repository.transactionCount(id);
    if (count > 0) {
      emit(
        state.copyWith(
          message: "Can't delete: $count transaction(s) use this category",
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
