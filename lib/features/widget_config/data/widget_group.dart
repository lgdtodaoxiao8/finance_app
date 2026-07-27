import 'package:finance_app/features/widget_config/data/widget_flow.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';

/// A named set of quick-add shortcuts. Each home-screen widget instance is
/// bound to one group (via iOS "Edit Widget"), so two widgets can show
/// different categories. Stored per-device in [AppPreferences].
///
/// A group has a [flow]: an expense group feeds the "Quick Expense" widget,
/// an income group feeds the "Quick Income" widget (each widget kind's picker
/// only offers groups of its own flow).
class WidgetGroup {
  const WidgetGroup({
    required this.id,
    required this.name,
    this.flow = WidgetFlow.expense,
    this.shortcuts = const [],
  });

  final String id;
  final String name;
  final WidgetFlow flow;
  final List<WidgetShortcut> shortcuts;

  WidgetGroup copyWith({
    String? name,
    WidgetFlow? flow,
    List<WidgetShortcut>? shortcuts,
  }) {
    return WidgetGroup(
      id: id,
      name: name ?? this.name,
      flow: flow ?? this.flow,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'flow': flow.name,
    'shortcuts': [for (final s in shortcuts) s.toJson()],
  };

  factory WidgetGroup.fromJson(Map<String, dynamic> json) {
    return WidgetGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      flow: WidgetFlow.fromName(json['flow'] as String?),
      shortcuts: [
        for (final e in (json['shortcuts'] as List<dynamic>? ?? []))
          WidgetShortcut.fromJson(e as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}
