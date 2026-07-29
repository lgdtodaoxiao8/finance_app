part of 'add_category_cubit.dart';

class AddCategoryState extends Equatable {
  const AddCategoryState({
    this.color = const Color(0xFF1E88E5),
    this.icon = SolarIconsBold.bag4,
    this.kind = 'expense',
    this.sending = false,
    this.savedId,
    this.error,
  });

  /// The one colour the user picks: icon colour; the circle fill is derived
  /// from it (see ItemAvatar.tint). Defaults let the user save immediately.
  final Color color;
  final IconData icon;

  /// 'expense' | 'income' — the category's hard type.
  final String kind;
  final bool sending;

  /// Set to the new row id once saved — the screen pops with it.
  final int? savedId;
  final String? error;

  AddCategoryState copyWith({
    Color? color,
    IconData? icon,
    String? kind,
    bool? sending,
    int? savedId,
    String? error,
  }) {
    return AddCategoryState(
      color: color ?? this.color,
      icon: icon ?? this.icon,
      kind: kind ?? this.kind,
      sending: sending ?? this.sending,
      savedId: savedId ?? this.savedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [color, icon, kind, sending, savedId, error];
}
