import 'package:flutter/material.dart';

class Account {
  final int accountId;
  final String accountName;
  final int currencyId;
  final IconData accountIcon;

  Account({
    required this.accountId,
    required this.accountName,
    required this.currencyId,
    required this.accountIcon,
  });

  Map<String, dynamic> toMap() => {
    'id': accountId,
    'name': accountName,
    'currency_id': currencyId,
    'icon_code_point': accountIcon.codePoint,
  };

  factory Account.formMap(Map<String, dynamic> map) => Account(
    accountId: map['id'],
    accountName: map['name'],
    currencyId: map['currency_id'],
    accountIcon: IconData(
      map['icon_code_point'],
      fontFamily: 'MaterialIcons',
      fontPackage: null,
    ),
  );
}

class Category {
  final int categoryId;
  final String categoryName;
  final int categoryColor;
  final IconData categoryIcon;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
  });

  Map<String, dynamic> toMap() => {
    'id': categoryId,
    'name': categoryName,
    'color': categoryColor,
    'icon_code_point': categoryIcon.codePoint,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    categoryId: map['id'],
    categoryName: map['name'],
    categoryColor: map['color'],
    categoryIcon: IconData(
      map['icon_code_point'],
      fontFamily: 'MaterialIcons',
      fontPackage: null,
    ),
  );
}

class Currency {
  final int currencyId;
  final String currencyCode;
  final String currencySymbol;
  final double currencyRateToBase;

  Currency({
    required this.currencyId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyRateToBase,
  });

  Map<String, dynamic> toMap() => {
    'id': currencyId,
    'code': currencyCode,
    'symbol': currencySymbol,
    'rate_to_base': currencyRateToBase,
  };

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    currencyId: map['id'],
    currencyCode: map['code'],
    currencySymbol: map['symbol'],
    currencyRateToBase: map['rate_to_base'],
  );
}

class Transaction {
  final int transactionId;
  final int accountId;
  final int? accountDestinationId;
  final int categoryId;
  final int currencyId;
  final double transactionAmount;
  final DateTime transactionDate;
  final String transactionNote;
  final String transactionType; //income /expense /transfer
  final bool transactionIsCanceled;

  Transaction({
    required this.transactionId,
    required this.accountId,
    required this.accountDestinationId,
    required this.categoryId,
    required this.currencyId,
    required this.transactionAmount,
    required this.transactionDate,
    required this.transactionNote,
    required this.transactionType,
    required this.transactionIsCanceled,
  });

  Map<String, dynamic> toMap() => {
    'id': transactionId,
    'account_id': accountId,
    'account_destination_id': accountDestinationId,
    'category_id': categoryId,
    'currency_id': currencyId,
    'amount': transactionAmount,
    'date': transactionDate.toString(),
    'note': transactionNote,
    'type': transactionType,
    'is_canceled': transactionIsCanceled,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    transactionId: map['id'],
    accountId: map['account_id'],
    accountDestinationId: map['account_destination_id'],
    categoryId: map['category_id'],
    currencyId: map['currency_id'],
    transactionAmount: map['amount'],
    transactionDate: map['date'],
    transactionNote: map['note'],
    transactionType: map['type'],
    transactionIsCanceled: map['is_canceled'],
  );
}
