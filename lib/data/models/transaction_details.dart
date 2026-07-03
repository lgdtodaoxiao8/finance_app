import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Read model for a transaction joined with its account, destination account,
/// category and currency — the shape returned by the list/analytics JOIN.
///
/// Colour/icon getters live here so the UI doesn't re-parse raw DB integers.
class TransactionDetails extends Equatable {
  const TransactionDetails({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.isCanceled,
    this.note,
    this.accountName,
    this.accountIconCode,
    this.accountDestinationName,
    this.accountDestinationIconCode,
    this.categoryName,
    this.categoryColorValue,
    this.categoryIconColorValue,
    this.categoryIconCode,
    this.currencyName,
    this.currencyCode,
  });

  final int id;
  final double amount;

  /// Local-time transaction date.
  final DateTime date;
  final String type; // expense | income | transfer
  final bool isCanceled;
  final String? note;

  final String? accountName;
  final int? accountIconCode;
  final String? accountDestinationName;
  final int? accountDestinationIconCode;

  final String? categoryName;
  final int? categoryColorValue;
  final int? categoryIconColorValue;
  final int? categoryIconCode;

  final String? currencyName;
  final String? currencyCode;

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';

  Color get categoryColor =>
      categoryColorValue != null ? Color(categoryColorValue!) : Colors.grey;

  Color get categoryIconColor => categoryIconColorValue != null
      ? Color(categoryIconColorValue!)
      : Colors.white;

  IconData get categoryIcon => categoryIconCode != null
      ? IconData(categoryIconCode!, fontFamily: 'MaterialIcons')
      : Icons.help_outline;

  factory TransactionDetails.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'] as String?;
    DateTime date;
    try {
      date = DateTime.parse(rawDate!).toLocal();
    } catch (_) {
      date = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return TransactionDetails(
      id: map['id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: date,
      type: map['type'] as String? ?? '',
      isCanceled: (map['is_canceled'] as int? ?? 0) == 1,
      note: map['note'] as String?,
      accountName: map['account_name'] as String?,
      accountIconCode: map['account_icon_code'] as int?,
      accountDestinationName: map['account_destination_name'] as String?,
      accountDestinationIconCode: map['account_destination_icon_code'] as int?,
      categoryName: map['category_name'] as String?,
      categoryColorValue: map['category_color'] as int?,
      categoryIconColorValue: map['category_icon_color'] as int?,
      categoryIconCode: map['category_icon_code'] as int?,
      currencyName: map['currency_name'] as String?,
      currencyCode: map['currency_code'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    type,
    isCanceled,
    note,
    accountName,
    accountDestinationName,
    categoryName,
    categoryColorValue,
    categoryIconColorValue,
    categoryIconCode,
    currencyCode,
  ];
}
