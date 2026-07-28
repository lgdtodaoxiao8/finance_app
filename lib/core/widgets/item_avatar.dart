import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The app-wide visual for a user-created item (category, account): the icon
/// drawn in its colour on a soft tint of the SAME colour — one colour drives
/// both, like the amount chips on the quick-add widget. Alpha is fixed by
/// design; users pick only the hue.
class ItemAvatar extends StatelessWidget {
  const ItemAvatar({
    super.key,
    required this.color,
    this.icon,
    this.label,
    this.diameter = 40,
  });

  /// The item's colour (fully opaque — the tint is derived here).
  final Color color;

  /// Icon to draw; mutually exclusive with [label].
  final IconData? icon;

  /// Short text to draw instead of an icon (e.g. a currency symbol).
  final String? label;

  final double diameter;

  /// The derived circle fill.
  static Color tint(Color color) => color.withValues(alpha: 0.15);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tint(color)),
      alignment: Alignment.center,
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                fontSize: diameter * 0.42,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            )
          : Icon(
              icon ?? PhosphorIconsFill.squaresFour,
              size: diameter * 0.5,
              color: color,
            ),
    );
  }
}
