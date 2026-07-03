import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

extension BoolToInt on bool {
  int toInt() => this ? 1 : 0;
}

extension ListSecond<T> on List<T> {
  T? get second {
    if (length < 2) throw Exception('have not enough element');
    return this[1];
  }
}

abstract class RootData {
  String get displayName;
  int get id;
  Widget buildIcon(BuildContext context);

  Widget buildDropdownRow(BuildContext context, bool isSelect);
}

class Currency implements RootData {
  final int currencyId;
  final String currencyName;
  final String currencyCode;
  final String currencySymbol;
  double? currencyRateToBase;
  bool isBaseCurrency;

  Currency({
    required this.currencyId,
    required this.currencyName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyRateToBase,
    this.isBaseCurrency = false,
  });

  @override
  String get displayName => currencyCode;
  @override
  int get id => currencyId;
  @override
  Widget buildIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        currencySymbol,
        style: kTextStyle.copyWith(
          fontSize: 20,
          color: const Color(0xFF242528),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget buildDropdownRow(BuildContext context, bool isSelect) {
    return Row(
      children: [
        Text(
          currencySymbol,
          style: kTextStyle.copyWith(
            fontSize: 16,
            color: isSelect ? const Color(0xFFB3B3B8) : const Color(0xFF242528),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currencyName,
            style: kTextStyle.copyWith(
              fontSize: 16,
              color: isSelect
                  ? const Color(0xFFB3B3B8)
                  : const Color(0xFF242528),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': currencyId,
    'name': currencyName,
    'code': currencyCode,
    'symbol': currencySymbol,
    'rate_to_base': currencyRateToBase,
    'is_base': isBaseCurrency.toInt(),
  };

  Map<String, dynamic> toMapSaving() => {
    'name': currencyName,
    'code': currencyCode,
    'symbol': currencySymbol,
    'rate_to_base': currencyRateToBase,
    'is_base': isBaseCurrency.toInt(),
  };

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    currencyId: map['id'],
    currencyName: map['name'],
    currencyCode: map['code'],
    currencySymbol: map['symbol'],
    currencyRateToBase: map['rate_to_base'],
    isBaseCurrency: map['is_base'] == 1,
  );
}

class Account implements RootData {
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

  @override
  String get displayName => accountName;
  @override
  int get id => accountId;
  @override
  Widget buildIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Icon(
        accountIcon,
        size: 25,
        color: const Color(0xFF40434A),
      ),
    );
  }

  @override
  Widget buildDropdownRow(BuildContext context, bool isSelect) {
    return Row(
      children: [
        Icon(
          accountIcon,
          size: 25,
          color: const Color(0xFF40434A),
        ),

        const SizedBox(width: 8),
        Expanded(
          child: Text(
            accountName,
            style: kTextStyle.copyWith(
              fontSize: 16,
              color: isSelect
                  ? const Color(0xFFB3B3B8)
                  : const Color(0xFF242528),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': accountId,
    'name': accountName,
    'currency_id': currencyId,
    'icon_code_point': accountIcon.codePoint,
  };

  Map<String, dynamic> toMapSaving() => {
    'name': accountName,
    'currency_id': currencyId,
    'icon_code_point': accountIcon.codePoint,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
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

class Category implements RootData {
  final int categoryId;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final Color categoryIconColor;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryIconColor,
  });

  @override
  String get displayName => categoryName;
  @override
  int get id => categoryId;
  @override
  Widget buildIcon(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: categoryColor,
      ),
      padding: const EdgeInsets.all(7),
      margin: const EdgeInsets.only(top: 4, left: 6),
      child: Icon(
        categoryIcon,
        size: 23,
        color: categoryIconColor,
      ),
    );
  }

  @override
  Widget buildDropdownRow(BuildContext context, bool isSelect) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: categoryColor.withValues(
              alpha: isSelect ? 0.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            categoryIcon,
            size: 25,
            color: categoryIconColor,
          ),
        ),

        const SizedBox(width: 8),
        Expanded(
          child: Text(
            categoryName,
            style: kTextStyle.copyWith(
              fontSize: 16,
              color: isSelect
                  ? const Color(0xFFB3B3B8)
                  : const Color(0xFF242528),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': categoryId,
    'name': categoryName,
    'color': categoryColor.toARGB32(),
    'icon_color': categoryIconColor.toARGB32(),
    'icon_code_point': categoryIcon.codePoint,
  };

  Map<String, dynamic> toMapSaving() => {
    'name': categoryName,
    'color': categoryColor.toARGB32(),
    'icon_color': categoryIconColor.toARGB32(),
    'icon_code_point': categoryIcon.codePoint,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    categoryId: map['id'],
    categoryName: map['name'],
    categoryColor: Color(map['color']),
    categoryIconColor: Color(map['icon_color']),
    categoryIcon: IconData(
      map['icon_code_point'],
      fontFamily: 'MaterialIcons',
      fontPackage: null,
    ),
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
    this.accountDestinationId,
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
    'is_canceled': transactionIsCanceled.toInt(),
  };

  Map<String, dynamic> toMapSaving() => {
    'account_id': accountId,
    'account_destination_id': accountDestinationId,
    'category_id': categoryId,
    'currency_id': currencyId,
    'amount': transactionAmount,
    'date': transactionDate.toString(), //MAKE NORMAL SAVING TO UTC FORMAT
    'note': transactionNote,
    'type': transactionType,
    'is_canceled': transactionIsCanceled.toInt(),
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    transactionId: map['id'],
    accountId: map['account_id'],
    accountDestinationId: map['account_destination_id'],
    categoryId: map['category_id'],
    currencyId: map['currency_id'],
    transactionAmount: map['amount'],
    transactionDate: DateTime.parse(map['date'] as String),
    transactionNote: map['note'],
    transactionType: map['type'],
    transactionIsCanceled: map['is_canceled'] == 1,
  );
}
