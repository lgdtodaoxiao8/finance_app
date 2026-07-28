import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// The transaction-type segmented switcher (expense / income / transfer) with a
/// gentle, unobtrusive colour accent: the selected segment carries a soft tint
/// of its semantic colour — голубой for expense, зелёный for income, a neutral
/// white chip for transfer (money that is neither in nor out).
///
/// Presentation-only; the parent owns the selected [value] and reacts to
/// [onChanged]. Kept token-driven so the coming global redesign can restyle it
/// without touching the add-transaction logic.
class TypeSwitcher extends StatelessWidget {
  const TypeSwitcher({super.key, required this.value, required this.onChanged});

  /// 'expense' | 'income' | 'transfer'.
  final String value;
  final void Function(String type, int index) onChanged;

  static const _types = ['expense', 'income', 'transfer'];

  /// The solid accent for a type — used by the Save button and the amount caret
  /// so the whole screen speaks the same colour.
  static Color solid(String type) => switch (type) {
    'income' => AppColors.positive,
    'transfer' => const Color(0xFF3B4046),
    _ => AppColors.primary,
  };

  static (Color fill, Color fg) _selected(BuildContext context, String type) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'income':
        return (
          AppColors.positive.withValues(alpha: dark ? 0.24 : 0.16),
          dark ? const Color(0xFF5DCAA5) : const Color(0xFF0F8A57),
        );
      case 'transfer':
        return (
          dark ? AppColorsDark.surfaceHigh : Colors.white,
          dark ? AppColorsDark.textPrimary : const Color(0xFF3B4046),
        );
      default:
        return (
          AppColors.primary.withValues(alpha: dark ? 0.28 : 0.15),
          dark ? const Color(0xFF85B7EB) : AppColors.primaryDark,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = {
      'expense': l.expense,
      'income': l.income,
      'transfer': l.transfer,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? AppColorsDark.surface : AppColors.field,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in _types)
            _segment(context, type, labels[type]!, type == value),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String type,
    String label,
    bool selected,
  ) {
    final (fill, fg) = _selected(context, type);
    return GestureDetector(
      onTap: selected ? null : () => onChanged(type, _types.indexOf(type)),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? fill : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected && type == 'transfer'
              ? const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: kTextStyle.copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? fg
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
