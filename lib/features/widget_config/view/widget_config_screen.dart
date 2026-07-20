import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
import 'package:finance_app/features/widget_config/view/shortcut_editor_sheet.dart';
import 'package:finance_app/features/widget_config/view/widget_visuals.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

String _shortAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// Lets the user pin categories to the home-screen quick-add widget and choose
/// how each button behaves (fixed amount / preset amounts / open the app).
/// Shortcuts are stored per-device in [AppPreferences] and republished to the
/// widget on every change.
class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  List<Category> _categories = const [];
  List<WidgetShortcut> _shortcuts = [];
  String _symbol = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await getIt<CategoryRepository>().getAll();
    final base = await getIt<CurrencyRepository>().getBase();
    final shortcuts = getIt<AppPreferences>().getWidgetShortcuts();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _symbol = base?.currencySymbol ?? '';
      // Drop shortcuts whose category was deleted.
      final ids = categories.map((c) => c.categoryId).toSet();
      _shortcuts = shortcuts.where((s) => ids.contains(s.categoryId)).toList();
      _loading = false;
    });
  }

  /// "500 $" — the same compact money style the native widget renders.
  String _amountCaption(double v) =>
      _symbol.isEmpty ? _shortAmount(v) : '${_shortAmount(v)} $_symbol';

  Category? _categoryFor(int id) {
    for (final c in _categories) {
      if (c.categoryId == id) return c;
    }
    return null;
  }

  Future<void> _persist() async {
    // Renumber order to match the current list position.
    _shortcuts = [
      for (var i = 0; i < _shortcuts.length; i++)
        _shortcuts[i].copyWith(order: i),
    ];
    await getIt<AppPreferences>().setWidgetShortcuts(_shortcuts);
    await getIt<WidgetService>().publishOnce();
  }

  Future<void> _addCategory() async {
    final pinnedIds = _shortcuts.map((s) => s.categoryId).toSet();
    final available = _categories
        .where((c) => !pinnedIds.contains(c.categoryId))
        .toList();
    final l = AppLocalizations.of(context);
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.widgetAllPinned)),
      );
      return;
    }
    final category = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(categories: available),
    );
    if (category == null || !mounted) return;
    await _editShortcut(
      WidgetShortcut(
        id: UniqueKey().toString(),
        categoryId: category.categoryId,
        mode: WidgetShortcutMode.presets,
        presets: const [],
        order: _shortcuts.length,
      ),
      isNew: true,
    );
  }

  Future<void> _editShortcut(
    WidgetShortcut shortcut, {
    required bool isNew,
  }) async {
    final category = _categoryFor(shortcut.categoryId);
    if (category == null) return;
    final result = await ShortcutEditorSheet.show(
      context,
      shortcut: shortcut,
      category: category,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isNew) {
        _shortcuts = [..._shortcuts, result];
      } else {
        _shortcuts = [
          for (final s in _shortcuts) s.id == result.id ? result : s,
        ];
      }
    });
    await _persist();
  }

  Future<void> _remove(WidgetShortcut shortcut) async {
    setState(() {
      _shortcuts = _shortcuts.where((s) => s.id != shortcut.id).toList();
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.widgetsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  l.widgetConfigIntro,
                  style: kTextStyle.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _WidgetPreview(
                  shortcuts: _shortcuts,
                  categoryFor: _categoryFor,
                  amountCaption: _amountCaption,
                ),
                const SizedBox(height: 24),
                Text(
                  l.widgetOnYourWidget,
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_shortcuts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l.widgetNoShortcuts,
                      style: kTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: _onReorder,
                    children: [
                      for (var i = 0; i < _shortcuts.length; i++)
                        _shortcutTile(context, l, _shortcuts[i], i),
                    ],
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: Text(l.widgetAddCategory),
                ),
              ],
            ),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final list = [..._shortcuts];
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _shortcuts = list;
    });
    await _persist();
  }

  Widget _shortcutTile(
    BuildContext context,
    AppLocalizations l,
    WidgetShortcut shortcut,
    int index,
  ) {
    final category = _categoryFor(shortcut.categoryId);
    final fill = category?.categoryColor ?? Colors.grey;
    return Container(
      key: ValueKey(shortcut.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: ListTile(
        onTap: () => _editShortcut(shortcut, isNew: false),
        leading: ModeCircle(
          fill: fill,
          icon: category?.categoryIcon ?? Icons.category,
          diameter: 40,
          isOpen: shortcut.mode == WidgetShortcutMode.open,
        ),
        title: Text(
          category?.categoryName ?? '',
          style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _modeSummary(l, shortcut),
          style: kTextStyle.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(shortcut),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
      ),
    );
  }

  /// "Presets · 500 $, 1000 $" — the mode plus what a tap actually logs.
  String _modeSummary(AppLocalizations l, WidgetShortcut s) {
    return switch (s.mode) {
      WidgetShortcutMode.fixed when s.amount != null =>
        '${l.widgetShortcutModeFixed} · ${_amountCaption(s.amount!)}',
      WidgetShortcutMode.fixed => l.widgetShortcutModeFixed,
      WidgetShortcutMode.presets when s.presets.isNotEmpty =>
        '${l.widgetShortcutModePresets} · '
            '${s.presets.map(_amountCaption).join(', ')}',
      WidgetShortcutMode.presets => l.widgetShortcutModePresets,
      WidgetShortcutMode.open => l.widgetShortcutModeOpen,
    };
  }
}

/// Live preview of the real home-screen widget, switchable between the two
/// families. Mirrors FinanceWidget.swift exactly: strict 2×2 grid (small) and
/// three row slots with amount chips (medium); instant buttons are solid
/// circles, "ask each time" buttons are tinted with a "+" badge.
class _WidgetPreview extends StatefulWidget {
  const _WidgetPreview({
    required this.shortcuts,
    required this.categoryFor,
    required this.amountCaption,
  });

  final List<WidgetShortcut> shortcuts;
  final Category? Function(int) categoryFor;
  final String Function(double) amountCaption;

  @override
  State<_WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<_WidgetPreview> {
  bool _medium = false;

  // Mirror of the native widget's cell metrics (see QuickAddEntryView in
  // FinanceWidget.swift) so the preview matches the home screen exactly.
  static const double _circle = 52;
  static const double _caption = 11;

  /// The amount one tap logs, or null for "ask each time" (mirrors
  /// Shortcut.primaryAmount in Swift).
  double? _primaryAmount(WidgetShortcut s) {
    return switch (s.mode) {
      WidgetShortcutMode.fixed => s.amount,
      WidgetShortcutMode.presets => s.presets.isEmpty ? null : s.presets.first,
      WidgetShortcutMode.open => null,
    };
  }

  BoxDecoration _card(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: kCardShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Center(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.widgetPreviewSmall)),
              ButtonSegment(value: true, label: Text(l.widgetPreviewMedium)),
            ],
            selected: {_medium},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            onSelectionChanged: (s) => setState(() => _medium = s.first),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: Center(child: _medium ? _mediumCard() : _smallCard()),
        ),
      ],
    );
  }

  Widget _smallCard() {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _card(context),
      child: Column(
        children: [
          Expanded(
            child: Row(children: [_cell(0), _cell(1)]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(children: [_cell(2), _cell(3)]),
          ),
        ],
      ),
    );
  }

  Widget _cell(int index) {
    if (index >= widget.shortcuts.length) {
      return Expanded(
        child: Center(
          child: Container(
            width: _circle,
            height: _circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        ),
      );
    }
    final s = widget.shortcuts[index];
    final category = widget.categoryFor(s.categoryId);
    final fill = category?.categoryColor ?? Colors.grey;
    final amount = _primaryAmount(s);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ModeCircle(
            fill: fill,
            icon: category?.categoryIcon ?? Icons.category,
            diameter: _circle,
            isOpen: amount == null,
          ),
          const SizedBox(height: 4),
          Text(
            amount == null
                ? (category?.categoryName ?? '')
                : widget.amountCaption(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kTextStyle.copyWith(
              fontSize: _caption,
              fontWeight: amount == null ? FontWeight.w400 : FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediumCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      height: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _card(context),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Expanded(child: _row(i)),
          ],
        ],
      ),
    );
  }

  Widget _row(int index) {
    if (index >= widget.shortcuts.length) {
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 72,
            height: 9,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }
    final s = widget.shortcuts[index];
    final category = widget.categoryFor(s.categoryId);
    final fill = category?.categoryColor ?? Colors.grey;
    final name = category?.categoryName ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth - 34 - 10 - 8 - _textWidth(name, 14);
        return Row(
          children: [
            ModeCircle(
              fill: fill,
              icon: category?.categoryIcon ?? Icons.category,
              diameter: 34,
              isOpen: _primaryAmount(s) == null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: kTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ..._rowChips(s, fill, available),
          ],
        );
      },
    );
  }

  double _textWidth(String text, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// Chip width mirror of [AmountChip]'s padding (fontSize * 0.85 each side).
  double _chipWidth(String label) => _textWidth(label, 12) + 12 * 0.85 * 2 + 2;

  List<Widget> _rowChips(WidgetShortcut s, Color fill, double available) {
    String short(double v) => _shortAmount(v);
    return switch (s.mode) {
      WidgetShortcutMode.fixed when s.amount != null => [
        AmountChip(label: widget.amountCaption(s.amount!), color: fill),
      ],
      WidgetShortcutMode.presets when s.presets.isNotEmpty => () {
        // As many preset chips as fit, mirroring the widget's ViewThatFits.
        final labels = [for (final p in s.presets) short(p)];
        final dotsWidth = _chipWidth('…');
        var count = labels.length > 4 ? 4 : labels.length;
        while (count > 1) {
          var total = dotsWidth;
          for (final l in labels.take(count)) {
            total += _chipWidth(l) + 5;
          }
          if (total <= available) break;
          count--;
        }
        return [
          for (final l in labels.take(count)) ...[
            AmountChip(label: l, color: fill),
            const SizedBox(width: 5),
          ],
          AmountChip(label: '…', color: fill),
        ];
      }(),
      _ => [AmountChip(label: '+', color: fill)],
    };
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.selectCategory,
              style: kTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in categories)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(c),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.categoryColor,
                        ),
                        child: Icon(
                          c.categoryIcon,
                          size: 18,
                          color: c.categoryIconColor,
                        ),
                      ),
                      title: Text(c.categoryName),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
