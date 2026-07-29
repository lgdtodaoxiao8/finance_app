import 'package:equatable/equatable.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

part 'add_category_state.dart';

/// Creates a category, or edits [initial] when given (same screen, same
/// rules — one colour drives the whole look).
class AddCategoryCubit extends Cubit<AddCategoryState> {
  AddCategoryCubit(this._repository, {Category? initial, String? initialKind})
    : _editingId = initial?.categoryId,
      super(
        initial == null
            ? AddCategoryState(kind: initialKind ?? 'expense')
            : AddCategoryState(
                color: initial.categoryColor,
                icon: initial.categoryIcon,
                kind: initial.categoryKind,
              ),
      );

  final CategoryRepository _repository;
  final int? _editingId;

  bool get isEditing => _editingId != null;

  void setColor(Color color) => emit(state.copyWith(color: color));
  void setIcon(IconData icon) => emit(state.copyWith(icon: icon));
  void setKind(String kind) => emit(state.copyWith(kind: kind));

  Future<void> save(String name) async {
    emit(state.copyWith(sending: true));
    try {
      final argb = state.color.toARGB32();
      final int id;
      if (_editingId case final editingId?) {
        await _repository.update(
          id: editingId,
          name: name,
          color: argb,
          // One colour drives the whole look; icon_color mirrors it for
          // backward compatibility.
          iconColor: argb,
          iconCodePoint: state.icon.codePoint,
          kind: state.kind,
        );
        id = editingId;
        // The home-screen widget bakes category name/colour/icon into its
        // shortcuts — republish so edits show up there too.
        await getIt<WidgetService>().publishOnce();
      } else {
        id = await _repository.add(
          name: name,
          color: argb,
          iconColor: argb,
          iconCodePoint: state.icon.codePoint,
          kind: state.kind,
        );
      }
      emit(state.copyWith(sending: false, savedId: id));
    } catch (e, st) {
      debugPrint('AddCategoryCubit.save error: $e\n$st');
      emit(state.copyWith(sending: false, error: '$e'));
    }
  }
}
