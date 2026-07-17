import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.category.categoryColor,
                      ),
                      child: Icon(
                        widget.category.categoryIcon,
                        size: 20,
                        color: widget.category.categoryIconColor,
                      ),
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
                _ModeSelector(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 8),
                Text(
                  _modeHint(l),
                  style: kTextStyle.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
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

  String _modeHint(AppLocalizations l) {
    return switch (_mode) {
      WidgetShortcutMode.fixed => l.widgetFixedAmountHint,
      WidgetShortcutMode.presets => l.widgetPresetsHint,
      WidgetShortcutMode.open => l.widgetOpenHint,
    };
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

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final WidgetShortcutMode mode;
  final ValueChanged<WidgetShortcutMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedButton<WidgetShortcutMode>(
      segments: [
        ButtonSegment(
          value: WidgetShortcutMode.fixed,
          label: Text(l.widgetShortcutModeFixed),
        ),
        ButtonSegment(
          value: WidgetShortcutMode.presets,
          label: Text(l.widgetShortcutModePresets),
        ),
        ButtonSegment(
          value: WidgetShortcutMode.open,
          label: Text(l.widgetShortcutModeOpen),
        ),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
