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
///
/// Set [adaptive] where space is tight (stat tiles, headline numbers, chart
/// labels): the amount then prefers its full form, shrinks it to fit, and only
/// falls back to the abbreviated "52К"/"1,2М" form when even shrinking can't
/// make it fit and read well. Leave it off (default) for list rows and other
/// unconstrained contexts, where the full value should always show.
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
    this.adaptive = false,
    this.minScale = 0.7,
    this.abbreviateAbove,
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

  /// Shrink-then-abbreviate when the full value doesn't fit the given width.
  final bool adaptive;

  /// How far the full value may shrink before switching to the abbreviated
  /// form (0.7 = down to 70% of the style size).
  final double minScale;

  /// Magnitude-based abbreviation for contexts that can't measure their width
  /// (e.g. inside an `IntrinsicHeight`, where the space-aware [adaptive] path's
  /// `LayoutBuilder` isn't allowed): values with `|value| >=` this show the
  /// abbreviated form. Pair with an outer `FittedBox` to shrink the rest.
  final double? abbreviateAbove;

  /// Mask shown in place of a hidden amount.
  static const mask = '••••';

  /// Masks [text] when the preference is on — for string-only contexts (e.g.
  /// chart tooltips) that can't use the widget. Not reactive on its own.
  static String maskString(String text) =>
      getIt<SettingsService>().settings.value.hideAmounts ? mask : text;

  String _masked() =>
      symbol == null || symbol!.isEmpty ? mask : '$mask $symbol';

  String _full(bool hide) {
    if (hide) return _masked();
    if (signed) {
      final sign = value < 0 ? '-' : '+';
      return '$sign${formatMoney(value.abs(), symbol)}';
    }
    return formatMoney(value, symbol);
  }

  String _abbreviated() {
    if (signed) {
      final sign = value < 0 ? '-' : '+';
      return '$sign${abbreviateMoney(value.abs(), symbol)}';
    }
    return abbreviateMoney(value, symbol);
  }

  /// The non-adaptive string: abbreviated when past [abbreviateAbove], else full.
  String _static(bool hide) {
    if (hide) return _masked();
    if (abbreviateAbove != null && value.abs() >= abbreviateAbove!) {
      return _abbreviated();
    }
    return _full(false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: getIt<SettingsService>().settings,
      builder: (context, s, _) {
        final full = _full(s.hideAmounts);
        if (!adaptive || s.hideAmounts) {
          return Text(
            _static(s.hideAmounts),
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          );
        }
        // Space-aware: measure the full value against the available width, keep
        // it (shrinking a little if needed) while it still reads, and only drop
        // to the abbreviated form when even shrinking can't fit it.
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            if (!maxWidth.isFinite) {
              return Text(
                full,
                style: style,
                maxLines: 1,
                textAlign: textAlign,
              );
            }
            final effectiveStyle = DefaultTextStyle.of(
              context,
            ).style.merge(style);
            final fullWidth = _measure(full, effectiveStyle);
            final text = fullWidth <= maxWidth / minScale
                ? full
                : _abbreviated();
            return SizedBox(
              width: maxWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: _fitAlignment(textAlign),
                child: Text(text, style: style, maxLines: 1, softWrap: false),
              ),
            );
          },
        );
      },
    );
  }

  double _measure(String text, TextStyle textStyle) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  Alignment _fitAlignment(TextAlign? align) {
    switch (align) {
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }
}
