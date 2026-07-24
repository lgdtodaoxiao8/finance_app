import 'package:intl/intl.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00');
// Two decimals keep the abbreviated form informative ("2,29М", "253,7К")
// rather than losing everything below the leading digit ("2,3М").
final NumberFormat _abbrevFormat = NumberFormat('#,##0.##');

/// Formats a monetary amount with thousands separators and 2 decimals.
String formatAmount(double value) => _amountFormat.format(value);

/// Formats an amount with an optional currency symbol/code suffix.
String formatMoney(double value, String? symbol) {
  final amount = formatAmount(value);
  if (symbol == null || symbol.isEmpty) return amount;
  return '$amount $symbol';
}

/// Signed amount (e.g. "+42.00", "-42.00") for income/expense rows.
String formatSigned(double value, {required bool negative}) {
  final sign = negative ? '-' : '+';
  return '$sign${formatAmount(value)}';
}

// --- Compact / abbreviated money ---------------------------------------------
//
// High-denomination currencies (tenge, won…) produce very long numbers that
// overflow tight layouts. [AmountText] prefers the full value and only falls
// back to these abbreviated forms ("52К", "1,2М") when it truly can't fit.

/// Localized thousands/millions suffixes. Set by the app when its language
/// changes (see [setCompactSuffixes]) so pure formatters can abbreviate without
/// a BuildContext. Default to Latin K/M.
String _thousandsSuffix = 'K';
String _millionsSuffix = 'M';

/// Updates the abbreviation suffixes to match the app language (e.g. "К"/"М"
/// for Russian). Called from the root widget, which has the localizations.
void setCompactSuffixes({required String thousands, required String millions}) {
  _thousandsSuffix = thousands;
  _millionsSuffix = millions;
}

/// Abbreviates a number to a short "52К" / "1,2М" form (localized suffix).
/// Values below 1000 keep their full formatting (nothing to abbreviate).
String abbreviateAmount(double value) {
  final a = value.abs();
  if (a >= 1000000) {
    return '${_abbrevFormat.format(value / 1000000)}$_millionsSuffix';
  }
  if (a >= 1000) {
    return '${_abbrevFormat.format(value / 1000)}$_thousandsSuffix';
  }
  return formatAmount(value);
}

/// [abbreviateAmount] with an optional currency symbol suffix.
String abbreviateMoney(double value, String? symbol) {
  final amount = abbreviateAmount(value);
  if (symbol == null || symbol.isEmpty) return amount;
  return '$amount $symbol';
}
