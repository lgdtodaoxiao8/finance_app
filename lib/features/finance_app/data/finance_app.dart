import 'package:finance_app/assets/currencies/currencies_list.dart';
import 'package:finance_app/database/database_helper.dart';
import 'package:flutter/material.dart';

final db = DatabaseHelper.instance;

Future<void> seedData() async {
  final currencies = await db.getAll("currencies");
  if (currencies.isEmpty) {
    // Seed the full currency list with no base and no rate yet.
    // The user picks the base currency during onboarding (Settings),
    // which is what assigns rate_to_base = 1.0 to the chosen currency.
    for (final currency in currenciesList) {
      await db.insert("currencies", {
        ...currency,
        "is_base": 0,
      });
    }
  }
  final accounts = await db.getAll("accounts");
  if (accounts.isEmpty) {
    // await db.insert("accounts", {
    //   "name": "Cash",
    //   "currency_id": 1,
    //   "icon_code_point": Icons.account_balance_wallet.codePoint,
    // });
    // await db.insert("accounts", {
    //   "name": "Bank",
    //   "currency_id": 1,
    //   "icon_code_point": Icons.account_balance_rounded.codePoint,
    // });
  }
  final categories = await db.getAll("categories");
  if (categories.isEmpty) {
    await db.insert("categories", {
      "name": "Food",
      "color": 4282682111, // integer
      "icon_color": 4278190080,
      "icon_code_point": Icons.fastfood_rounded.codePoint,
    });
    await db.insert("categories", {
      "name": "Salary",
      "color": 4294953540,
      "icon_color": 4278190080,
      "icon_code_point": Icons.attach_money_rounded.codePoint,
    });
  }
}

Future<void> delete() async {
  await db.deleteDatabaseFile();
}
