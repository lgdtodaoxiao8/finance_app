part of 'add_category_cubit.dart';

class AddCategoryState extends Equatable {
  const AddCategoryState({
    this.color,
    this.iconColor,
    this.icon,
    this.sending = false,
    this.savedId,
    this.error,
  });

  final Color? color;
  final Color? iconColor;
  final IconData? icon;
  final bool sending;

  /// Set to the new row id once saved — the screen pops with it.
  final int? savedId;
  final String? error;

  AddCategoryState copyWith({
    Color? color,
    Color? iconColor,
    IconData? icon,
    bool? sending,
    int? savedId,
    String? error,
  }) {
    return AddCategoryState(
      color: color ?? this.color,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
      sending: sending ?? this.sending,
      savedId: savedId ?? this.savedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [color, iconColor, icon, sending, savedId, error];
}
