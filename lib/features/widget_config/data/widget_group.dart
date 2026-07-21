import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';

/// A named set of quick-add shortcuts. Each home-screen widget instance is
/// bound to one group (via iOS "Edit Widget"), so two widgets can show
/// different categories. Stored per-device in [AppPreferences].
class WidgetGroup {
  const WidgetGroup({
    required this.id,
    required this.name,
    this.shortcuts = const [],
  });

  final String id;
  final String name;
  final List<WidgetShortcut> shortcuts;

  WidgetGroup copyWith({String? name, List<WidgetShortcut>? shortcuts}) {
    return WidgetGroup(
      id: id,
      name: name ?? this.name,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortcuts': [for (final s in shortcuts) s.toJson()],
  };

  factory WidgetGroup.fromJson(Map<String, dynamic> json) {
    return WidgetGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      shortcuts: [
        for (final e in (json['shortcuts'] as List<dynamic>? ?? []))
          WidgetShortcut.fromJson(e as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}
