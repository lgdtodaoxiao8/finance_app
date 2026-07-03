import 'package:equatable/equatable.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_category_state.dart';

class AddCategoryCubit extends Cubit<AddCategoryState> {
  AddCategoryCubit(this._repository) : super(const AddCategoryState());

  final CategoryRepository _repository;

  void setColor(Color color) => emit(state.copyWith(color: color));
  void setIconColor(Color color) => emit(state.copyWith(iconColor: color));
  void setIcon(IconData icon) => emit(state.copyWith(icon: icon));

  Future<void> save(String name) async {
    final color = state.color;
    final icon = state.icon;
    if (color == null || icon == null) return;

    emit(state.copyWith(sending: true));
    try {
      final id = await _repository.add(
        name: name,
        color: color.toARGB32(),
        iconColor: (state.iconColor ?? Colors.black).toARGB32(),
        iconCodePoint: icon.codePoint,
      );
      emit(state.copyWith(sending: false, savedId: id));
    } catch (e, st) {
      debugPrint('AddCategoryCubit.save error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
