import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/home/cubit/analytics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
    getIt
      ..registerSingleton<AppDatabase>(db)
      ..registerLazySingleton<CurrencyRepository>(
        () => DriftCurrencyRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<AccountRepository>(
        () => DriftAccountRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<CategoryRepository>(
        () => DriftCategoryRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<TransactionRepository>(
        () => DriftTransactionRepository(getIt<AppDatabase>()),
      );
    await seedData();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  test('aggregates totals and category spend in base currency', () async {
    final currencyRepo = getIt<CurrencyRepository>();
    final currencies = await currencyRepo.getAll();
    final aId = currencies[0].currencyId;
    final bId = currencies[1].currencyId;
    await currencyRepo.makeBase(aId); // A base, rate 1.0
    await currencyRepo.setRate(bId, 2.0); // 1 B = 2 A

    final accountId = await getIt<AccountRepository>().add(
      name: 'Cash',
      currencyId: aId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
    final categories = await getIt<CategoryRepository>().getAll();
    final foodId = categories[0].categoryId;
    final salaryId = categories[1].categoryId;
    final now = DateTime.now();
    final txRepo = getIt<TransactionRepository>();

    await txRepo.add(
      accountId: accountId,
      categoryId: salaryId,
      currencyId: aId,
      amount: 100,
      date: now,
      type: 'income',
    );
    await txRepo.add(
      accountId: accountId,
      categoryId: foodId,
      currencyId: aId,
      amount: 10,
      date: now,
      type: 'expense',
    );
    await txRepo.add(
      accountId: accountId,
      categoryId: foodId,
      currencyId: bId,
      amount: 3, // = 6 A
      date: now,
      type: 'expense',
    );
    await txRepo.add(
      accountId: accountId,
      categoryId: salaryId,
      currencyId: aId,
      amount: 4,
      date: now,
      type: 'expense',
    );

    final cubit = AnalyticsCubit(txRepo, currencyRepo);
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AnalyticsState>(
          (s) =>
              s.status == AnalyticsStatus.ready && s.transactions.length == 4,
        ),
      ),
    );

    expect(cubit.state.totalIncome, 100.0);
    expect(cubit.state.totalExpense, 20.0); // 10 + 6 + 4
    expect(cubit.state.balance, 80.0);

    final spends = cubit.state.categorySpends;
    expect(spends.length, 2);
    expect(spends.first.name, 'Food'); // 16, largest first
    expect(spends.first.total, 16.0);
    expect(spends[1].name, 'Salary');
    expect(spends[1].total, 4.0);

    await cubit.close();
  });
}
