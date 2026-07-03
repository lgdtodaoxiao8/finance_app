import 'package:finance_app/database/database_helper.dart';
import 'package:flutter/rendering.dart';

final db = DatabaseHelper.instance;

Future<List<Map<String, dynamic>>> fetchCurrenciesFutureListFromBase() async {
  try {
    await db.database;

    final fetchedCurrencies = await db.getCurrenciesWithRate();

    return fetchedCurrencies;
  } catch (e, st) {
    debugPrint('fetchDataFromBase error: $e\n$st');
    throw Exception('Error by fetching currencies from database');
  }
}

Future<List<Map<String, dynamic>>> fetchAccountsFutureListFromBase() async {
  try {
    await db.database;

    final fetchedAccounts = await db.getAll("accounts");

    return fetchedAccounts;
  } catch (e, st) {
    debugPrint('fetchDataFromBase error: $e\n$st');
    throw Exception('Error by fetching accounts from database');
  }
}
