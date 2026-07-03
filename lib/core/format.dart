import 'package:intl/intl.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00');

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
