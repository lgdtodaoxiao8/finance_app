import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the DatabaseHelper facade against a real in-memory Drift database
/// to validate the raw SQL (inserts, currency logic, the details JOIN).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
    getIt.registerSingleton<AppDatabase>(db);
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  test('seed + full facade round trip', () async {
    final helper = DatabaseHelper.instance;

    await seedData();

    final currencies = await helper.getAllCurrencies();
    expect(currencies, isNotEmpty);

    // Nothing has a rate until a base is chosen.
    final nullRate = await helper.getCurrenciesWithNullRate();
    expect(nullRate.length, currencies.length);
    expect(await helper.getCurrenciesWithRate(), isEmpty);
    expect(await helper.getDefaultCurrency(), isEmpty);

    // Choosing a base assigns rate_to_base = 1.0 and flags is_base.
    final baseId = currencies.first['id'] as int;
    await helper.makeCurrencyBase(baseId);

    final base = await helper.getDefaultCurrency();
    expect(base.single['id'], baseId);
    expect(base.single['rate_to_base'], 1.0);
    expect(base.single['is_base'], 1);
    expect((await helper.getCurrenciesWithRate()).length, 1);

    // Account + transaction + the details JOIN used by the list screen.
    final accountId = await helper.insert('accounts', {
      'name': 'Cash',
      'currency_id': baseId,
      'icon_code_point': Icons.account_balance_wallet_rounded.codePoint,
    });
    final categoryId = (await helper.getAll('categories')).first['id'] as int;

    await helper.insert('transactions', {
      'account_id': accountId,
      'category_id': categoryId,
      'currency_id': baseId,
      'amount': 12.5,
      'date': DateTime.utc(2026, 1, 1).toIso8601String(),
      'note': 'lunch',
      'type': 'expense',
      'is_canceled': 0,
    });

    final details = await helper.getTransactionsWithDetails();
    expect(details, hasLength(1));
    expect(details.first['account_name'], 'Cash');
    expect(details.first['category_name'], isNotNull);
    expect(details.first['currency_code'], isNotNull);
    expect(details.first['amount'], 12.5);
    expect(details.first['type'], 'expense');
  });
}
