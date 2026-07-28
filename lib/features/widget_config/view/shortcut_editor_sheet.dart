import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
import 'package:finance_app/features/widget_config/view/widget_visuals.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/core/app_icons.dart';

/// Configures one widget shortcut: its behavior (fixed / presets / open) and
/// the amount(s) involved. Returns the edited [WidgetShortcut], or null on
/// cancel.
class ShortcutEditorSheet extends StatefulWidget {
  const ShortcutEditorSheet({
    super.key,
    required this.shortcut,
    required this.category,
    this.isIncome = false,
  });

  final WidgetShortcut shortcut;
  final Category category;

  /// Income group: the mode illustrations turn green (+ "+" sign) and the hints
  /// speak of income, matching the widget the shortcut lands on.
  final bool isIncome;

  static Future<WidgetShortcut?> show(
    BuildContext context, {
    required WidgetShortcut shortcut,
    required Category category,
    bool isIncome = false,
  }) {
    return showModalBottomSheet<WidgetShortcut>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShortcutEditorSheet(
        shortcut: shortcut,
        category: category,
        isIncome: isIncome,
      ),
    );
  }

  @override
  State<ShortcutEditorSheet> createState() => _ShortcutEditorSheetState();
}

class _ShortcutEditorSheetState extends State<ShortcutEditorSheet> {
  late WidgetShortcutMode _mode;
  late TextEditingController _amountController;
  late TextEditingController _presetController;
  late List<double> _presets;

  @override
  void initState() {
    super.initState();
    _mode = widget.shortcut.mode;
    _amountController = TextEditingController(
      text: widget.shortcut.amount == null ? '' : _fmt(widget.shortcut.amount!),
    );
    _presetController = TextEditingController();
    _presets = [...widget.shortcut.presets];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _presetController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? _parse(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return value;
  }

  /// The widget only ever renders the first six amounts (preset picker / builder
  /// steps), so the editor caps at six too.
  static const int _maxPresets = 6;

  bool get _presetsFull => _presets.length >= _maxPresets;

  void _addPreset() {
    if (_presetsFull) return;
    final value = _parse(_presetController.text);
    if (value == null || _presets.contains(value)) return;
    setState(() {
      _presets = [..._presets, value]..sort();
      _presetController.clear();
    });
  }

  bool get _valid {
    return switch (_mode) {
      WidgetShortcutMode.fixed => _parse(_amountController.text) != null,
      WidgetShortcutMode.presets => _presets.isNotEmpty,
      WidgetShortcutMode.open => true,
    };
  }

  void _save() {
    // `presets` doubles as the custom amount-builder steps in "ask each time"
    // mode (empty → the widget derives them from spending automatically).
    final keepsAmounts =
        _mode == WidgetShortcutMode.presets || _mode == WidgetShortcutMode.open;
    final result = widget.shortcut.copyWith(
      mode: _mode,
      clearAmount: _mode != WidgetShortcutMode.fixed,
      amount: _mode == WidgetShortcutMode.fixed
          ? _parse(_amountController.text)
          : null,
      presets: keepsAmounts ? _presets : const [],
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ItemAvatar(
                      color: widget.category.categoryColor,
                      icon: widget.category.categoryIcon,
                      diameter: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.category.categoryName,
                      style: kTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final m in WidgetShortcutMode.values) ...[
                  _ModeCard(
                    mode: m,
                    selected: _mode == m,
                    category: widget.category,
                    isIncome: widget.isIncome,
                    onTap: () => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                if (_mode == WidgetShortcutMode.fixed) _fixedField(l),
                if (_mode == WidgetShortcutMode.presets) _presetsField(l),
                if (_mode == WidgetShortcutMode.open) _openStepsField(l),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _valid ? _save : null,
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fixedField(AppLocalizations l) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: l.amount,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _presetsField(AppLocalizations l) => _amountListEditor(l);

  /// "Ask each time" mode: optional custom builder steps. Empty = the widget
  /// adapts them to the user's spending (and currency) automatically.
  Widget _openStepsField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.widgetStepsTitle,
          style: kTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          l.widgetStepsHint,
          style: kTextStyle.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        _amountListEditor(l),
      ],
    );
  }

  /// Shared editor for a list of amounts (preset chips / builder steps): the
  /// current values as deletable chips plus an input to add more, capped at
  /// [_maxPresets] with an "N/6" counter.
  Widget _amountListEditor(AppLocalizations l) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_presets.length}/$_maxPresets',
            style: kTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _presetsFull
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_presets.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                InputChip(
                  label: Text(_fmt(p)),
                  onDeleted: () => setState(
                    () => _presets = _presets.where((x) => x != p).toList(),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _presetController,
                enabled: !_presetsFull,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => _addPreset(),
                decoration: InputDecoration(
                  labelText: _presetsFull
                      ? l.widgetPresetsMaxed(_maxPresets)
                      : l.widgetAddPreset,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _presetsFull ? null : _addPreset,
              icon: const Icon(AppIcons.add),
            ),
          ],
        ),
      ],
    );
  }
}

/// One selectable behavior option: a miniature of how the button will look on
/// the widget (same visual language: solid = instant, tinted + badge = opens
/// input) next to a title and a one-line explanation.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.category,
    required this.isIncome,
    required this.onTap,
  });

  final WidgetShortcutMode mode;
  final bool selected;
  final Category category;
  final bool isIncome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (title, hint) = switch (mode) {
      WidgetShortcutMode.fixed => (
        l.widgetShortcutModeFixed,
        l.widgetFixedAmountHint,
      ),
      WidgetShortcutMode.presets => (
        l.widgetShortcutModePresets,
        // Only the presets hint frames the action as a spend; income gets a
        // "log the income" variant.
        isIncome ? l.widgetPresetsHintIncome : l.widgetPresetsHint,
      ),
      WidgetShortcutMode.open => (
        l.widgetShortcutModeOpen,
        l.widgetOpenHint,
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _illustration(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: kTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: kTextStyle.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? AppIcons.check_circle : AppIcons.circle,
                size: 20,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A miniature of the actual widget cell in this mode — the badge tells the
  /// three modes apart (amount in the corner / two pills / "+"), matching the
  /// home-screen widget.
  Widget _illustration() {
    final fill = category.categoryColor;
    final icon = category.categoryIcon;
    final (badge, amountLabel) = switch (mode) {
      // The fixed sample carries the +/− flow sign, like the widget.
      WidgetShortcutMode.fixed => (ModeBadge.amount, isIncome ? '+100' : '−100'),
      WidgetShortcutMode.presets => (ModeBadge.presets, null),
      WidgetShortcutMode.open => (ModeBadge.plus, null),
    };
    return ModeCircle(
      fill: fill,
      icon: icon,
      diameter: 40,
      badge: badge,
      amountLabel: amountLabel,
    );
  }
}
