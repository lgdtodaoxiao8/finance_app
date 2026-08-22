import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Period selector for the per-entity history screens: an "All" chip plus
/// Day / Week / Month / Year / Custom. `selected == null` means All.
class PeriodFilterChips extends StatelessWidget {
  const PeriodFilterChips({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onPickCustom,
  });

  final PeriodPreset? selected;
  final ValueChanged<PeriodPreset?> onSelect;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
      label: Text(
        label,
        style: kTextStyle.copyWith(
          color: sel
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: sel,
      onSelected: (_) => onTap(),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip(l.periodAll, selected == null, () => onSelect(null)),
        for (final p in PeriodPreset.values)
          chip(periodChipLabel(l, p), selected == p, () {
            if (p == PeriodPreset.custom) {
              onPickCustom();
            } else {
              onSelect(p);
            }
          }),
      ],
    );
  }
}
