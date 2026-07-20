/// Shared visual language of the quick-add widget, mirrored from
/// FinanceWidget.swift so in-app previews match the home screen exactly.
///
/// Mode narrative: instant-log buttons (fixed / presets) are SOLID circles;
/// "ask each time" buttons are TINTED circles wearing a small "+" badge —
/// tinted + badge reads as "opens input" without any words.
library;

import 'package:flutter/material.dart';

/// White or near-black — whichever is legible on [fill]. The native widget
/// uses the same rule (contrastingOn in FinanceWidget.swift).
Color widgetOnColor(Color fill) {
  final luminance = 0.299 * fill.r + 0.587 * fill.g + 0.114 * fill.b;
  return luminance > 0.62 ? Colors.black.withValues(alpha: 0.82) : Colors.white;
}

/// The mode-aware circle: solid for instant-log, tinted + "+" badge for
/// "ask each time". [diameter] scales everything, so the same widget serves
/// the config preview and the editor's mini-illustrations.
class ModeCircle extends StatelessWidget {
  const ModeCircle({
    super.key,
    required this.fill,
    required this.icon,
    required this.diameter,
    required this.isOpen,
  });

  final Color fill;
  final IconData icon;
  final double diameter;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final badge = diameter * 0.36;
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
              color: isOpen ? fill.withValues(alpha: 0.16) : fill,
            ),
            child: Icon(
              icon,
              size: diameter * 0.46,
              color: isOpen ? fill : widgetOnColor(fill),
            ),
          ),
          if (isOpen)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: badge * 0.62,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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
