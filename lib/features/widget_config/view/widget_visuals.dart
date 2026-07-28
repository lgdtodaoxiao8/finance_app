/// Shared visual language of the quick-add widget, mirrored from
/// FinanceWidget.swift so in-app previews match the home screen exactly.
///
/// The one-colour tint circle (glyph in the category colour on a faint tint of
/// it, like ItemAvatar) carries a bottom-right badge that tells the three modes
/// apart: fixed = its amount in the corner (no pill), presets = two small
/// horizontal pills, "ask each time" = a "+".
library;

import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The pleasant green of the income widget's add "+" and its in-app flow badge
/// (mirrors Swift's `incomeGreen`). The expense add "+" uses the accent (blue).
const Color kIncomeGreen = AppColors.positive;

/// Which mode badge sits on the circle's bottom-right corner.
enum ModeBadge {
  /// No badge (plain circle — e.g. the medium rows, whose chips convey mode).
  none,

  /// The fixed amount, written in the corner in the category colour, no pill.
  amount,

  /// Two small horizontal pills — "several presets".
  presets,

  /// A "+" — "ask each time" opens an input.
  plus,
}

/// The one-colour circle + its mode badge. [diameter] scales everything, so it
/// serves the config preview, the shortcut list and the editor illustrations.
class ModeCircle extends StatelessWidget {
  const ModeCircle({
    super.key,
    required this.fill,
    required this.icon,
    required this.diameter,
    this.badge = ModeBadge.none,
    this.amountLabel,
  });

  final Color fill;
  final IconData icon;
  final double diameter;
  final ModeBadge badge;

  /// The corner text for [ModeBadge.amount] — the fixed amount with its currency
  /// symbol and +/− flow sign, built by the caller. The badges are otherwise
  /// identical across income and expense (flow is carried by the glass rim).
  final String? amountLabel;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: diameter * 0.46, color: fill),
          ),
          ..._badge(surface),
        ],
      ),
    );
  }

  List<Widget> _badge(Color surface) {
    switch (badge) {
      case ModeBadge.none:
        return const [];
      case ModeBadge.plus:
        final b = diameter * 0.36;
        return [
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: b,
              height: b,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: surface, width: 1.5),
              ),
              child: Icon(PhosphorIconsFill.plus, size: b * 0.62, color: Colors.white),
            ),
          ),
        ];
      case ModeBadge.presets:
        return [
          Positioned(
            right: -3,
            bottom: -2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill(surface),
                SizedBox(width: diameter * 0.03),
                _pill(surface),
              ],
            ),
          ),
        ];
      case ModeBadge.amount:
        // The fixed amount (with its +/− sign + currency symbol) in the corner,
        // in the category colour, with a soft surface halo so it reads over the
        // icon. Width-capped so long sums shrink to fit.
        return [
          Positioned(
            right: -2,
            bottom: -2,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: diameter * 0.95),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountLabel ?? '',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: diameter * 0.22,
                    fontWeight: FontWeight.w800,
                    color: fill,
                    shadows: [
                      Shadow(color: surface, blurRadius: 2),
                      Shadow(color: surface, blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];
    }
  }

  /// A category-coloured capsule with a surface ring (the preset-pill shape).
  Widget _pill(Color surface) {
    return Container(
      width: diameter * 0.3,
      height: diameter * 0.2,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(diameter * 0.1),
        border: Border.all(color: surface, width: diameter * 0.03),
      ),
    );
  }
}

/// A tiny tinted amount capsule — the medium widget's chip in miniature.
class AmountChip extends StatelessWidget {
  const AmountChip({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 12,
  });

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.85,
        vertical: fontSize * 0.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
