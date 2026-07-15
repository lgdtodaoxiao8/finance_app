import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/settings/app_settings.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:flutter/material.dart';

/// Displays a monetary amount, honouring the "hide amounts" preference live.
///
/// It listens to [SettingsService] itself, so wherever it's used the amount
/// masks/unmasks instantly when the toggle flips — no ancestor rebuild needed.
/// Use this instead of `Text(formatMoney(...))` for any figure the user might
/// want to keep private.
class AmountText extends StatelessWidget {
  const AmountText(
    this.value, {
    super.key,
    this.symbol,
    this.signed = false,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final double value;
  final String? symbol;

  /// When true, prefixes an explicit `+` / `-` based on the sign of [value]
  /// (the value itself is shown as its magnitude, matching the old rows).
  final bool signed;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Mask shown in place of a hidden amount.
  static const mask = '••••';

  /// Masks [text] when the preference is on — for string-only contexts (e.g.
  /// chart tooltips) that can't use the widget. Not reactive on its own.
  static String maskString(String text) =>
      getIt<SettingsService>().settings.value.hideAmounts ? mask : text;

  String _format(bool hide) {
    if (hide) {
      return symbol == null || symbol!.isEmpty ? mask : '$mask $symbol';
    }
    if (signed) {
      final sign = value < 0 ? '-' : '+';
      return '$sign${formatMoney(value.abs(), symbol)}';
    }
    return formatMoney(value, symbol);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: getIt<SettingsService>().settings,
      builder: (context, s, _) => Text(
        _format(s.hideAmounts),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
