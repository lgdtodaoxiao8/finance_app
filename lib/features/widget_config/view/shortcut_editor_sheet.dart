import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
import 'package:finance_app/features/widget_config/view/widget_visuals.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Configures one widget shortcut: its behavior (fixed / presets / open) and
/// the amount(s) involved. Returns the edited [WidgetShortcut], or null on
/// cancel.
class ShortcutEditorSheet extends StatefulWidget {
  const ShortcutEditorSheet({
    super.key,
    required this.shortcut,
    required this.category,
  });

  final WidgetShortcut shortcut;
  final Category category;

  static Future<WidgetShortcut?> show(
    BuildContext context, {
    required WidgetShortcut shortcut,
    required Category category,
  }) {
    return showModalBottomSheet<WidgetShortcut>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShortcutEditorSheet(
        shortcut: shortcut,
        category: category,
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

  void _addPreset() {
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
    final result = widget.shortcut.copyWith(
      mode: _mode,
      clearAmount: _mode != WidgetShortcutMode.fixed,
      amount: _mode == WidgetShortcutMode.fixed
          ? _parse(_amountController.text)
          : null,
      presets: _mode == WidgetShortcutMode.presets ? _presets : const [],
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
                    onTap: () => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                if (_mode == WidgetShortcutMode.fixed) _fixedField(l),
                if (_mode == WidgetShortcutMode.presets) _presetsField(l),
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

  Widget _presetsField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_presets.isNotEmpty)
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _presetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => _addPreset(),
                decoration: InputDecoration(
                  labelText: l.widgetAddPreset,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _addPreset,
              icon: const Icon(Icons.add),
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
    required this.onTap,
  });

  final WidgetShortcutMode mode;
  final bool selected;
  final Category category;
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
        l.widgetPresetsHint,
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
                      maxLines: 2,
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
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
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

  /// A miniature of the actual widget button in this mode.
  Widget _illustration() {
    final fill = category.categoryColor;
    final icon = category.categoryIcon;
    return switch (mode) {
      // Solid circle + one amount caption: "tap = this exact sum".
      WidgetShortcutMode.fixed => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeCircle(fill: fill, icon: icon, diameter: 30, isOpen: false),
          const SizedBox(height: 3),
          AmountChip(label: '100', color: fill, fontSize: 8),
        ],
      ),
      // Solid circle + a pair of chips: "your usual sums to pick from".
      WidgetShortcutMode.presets => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeCircle(fill: fill, icon: icon, diameter: 30, isOpen: false),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountChip(label: '100', color: fill, fontSize: 8),
              const SizedBox(width: 3),
              AmountChip(label: '500', color: fill, fontSize: 8),
            ],
          ),
        ],
      ),
      // Tinted circle with the "+" badge: "opens input".
      WidgetShortcutMode.open => ModeCircle(
        fill: fill,
        icon: icon,
        diameter: 36,
        isOpen: true,
      ),
    };
  }
}
