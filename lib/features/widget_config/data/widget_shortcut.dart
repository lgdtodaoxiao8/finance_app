/// How a home-screen widget button behaves when tapped.
enum WidgetShortcutMode {
  /// Logs a fixed amount into the category instantly (no app open).
  fixed,

  /// Shows a few preset amounts; tapping one logs it instantly. A "custom"
  /// affordance deep-links into the in-app quick-add sheet.
  presets,

  /// Always opens the in-app quick-add sheet, prefilled with the category.
  open;

  static WidgetShortcutMode fromName(String? name) =>
      WidgetShortcutMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => WidgetShortcutMode.open,
      );
}

/// A category pinned to the home-screen widget. Color and icon are inherited
/// from the category at publish time, so this only stores behavior.
///
/// Stored per-device (widget layout is device-specific) in [AppPreferences],
/// referenced by the local `categoryId`.
class WidgetShortcut {
  const WidgetShortcut({
    required this.id,
    required this.categoryId,
    required this.mode,
    this.amount,
    this.presets = const [],
    this.order = 0,
  });

  final String id;
  final int categoryId;
  final WidgetShortcutMode mode;

  /// Amount logged for [WidgetShortcutMode.fixed]. Null otherwise.
  final double? amount;

  /// Preset amounts offered for [WidgetShortcutMode.presets]. Empty otherwise.
  final List<double> presets;

  /// Position in the widget (ascending).
  final int order;

  WidgetShortcut copyWith({
    int? categoryId,
    WidgetShortcutMode? mode,
    double? amount,
    bool clearAmount = false,
    List<double>? presets,
    int? order,
  }) {
    return WidgetShortcut(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      mode: mode ?? this.mode,
      amount: clearAmount ? null : (amount ?? this.amount),
      presets: presets ?? this.presets,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'mode': mode.name,
    'amount': amount,
    'presets': presets,
    'order': order,
  };

  factory WidgetShortcut.fromJson(Map<String, dynamic> json) {
    return WidgetShortcut(
      id: json['id'] as String,
      categoryId: (json['categoryId'] as num).toInt(),
      mode: WidgetShortcutMode.fromName(json['mode'] as String?),
      amount: (json['amount'] as num?)?.toDouble(),
      presets: [
        for (final p in (json['presets'] as List<dynamic>? ?? []))
          (p as num).toDouble(),
      ],
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
