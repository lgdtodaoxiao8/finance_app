import 'package:drift/drift.dart';
import 'package:finance_app/assets/currencies/currencies_list.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/app_icons.dart';

/// Seeds the currency list and a couple of default categories on first run.
///
/// Base currency and accounts are intentionally left unset — the user picks a
/// base currency during onboarding (Settings), which assigns rate_to_base.
Future<void> seedData() async {
  final db = getIt<AppDatabase>();

  final currencies = await db.select(db.currencies).get();
  if (currencies.isEmpty) {
    await db.batch((batch) {
      for (final currency in currenciesList) {
        batch.insert(
          db.currencies,
          CurrenciesCompanion.insert(
            name: Value(currency['name'] as String?),
            code: Value(currency['code'] as String?),
            symbol: Value(currency['symbol'] as String?),
          ),
        );
      }
    });
  }

  final categories = await db.select(db.categories).get();
  if (categories.isEmpty) {
    await db.batch((batch) {
      batch
        ..insert(
          db.categories,
          CategoriesCompanion.insert(
            name: const Value('Food'),
            color: const Value(4282682111),
            iconColor: const Value(4278190080),
            iconCodePoint: Value(AppIcons.fastfood.codePoint),
            kind: const Value('expense'),
          ),
        )
        ..insert(
          db.categories,
          CategoriesCompanion.insert(
            name: const Value('Salary'),
            color: const Value(4294953540),
            iconColor: const Value(4278190080),
            iconCodePoint: Value(AppIcons.attach_money.codePoint),
            kind: const Value('income'),
          ),
        );
    });
  }
}

/// Dev-only: wipes every row in the database.
Future<void> deleteAllData() async {
  final db = getIt<AppDatabase>();
  await db.transaction(() async {
    for (final table in db.allTables) {
      await db.delete(table).go();
    }
  });
}
