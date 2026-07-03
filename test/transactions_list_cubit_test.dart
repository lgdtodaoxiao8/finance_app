import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/transactions_list/cubit/transactions_list_cubit.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
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
      ..registerLazySingleton<TransactionRepository>(
        () => DriftTransactionRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<CurrencyRepository>(
        () => DriftCurrencyRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<AccountRepository>(
        () => DriftAccountRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<CategoryRepository>(
        () => DriftCategoryRepository(getIt<AppDatabase>()),
      );
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<(int baseId, int accountId, int categoryId)> seedReady() async {
    await seedData();
    final currencyRepo = getIt<CurrencyRepository>();
    final baseId = (await currencyRepo.getAll()).first.currencyId;
    await currencyRepo.makeBase(baseId);
    final accountId = await getIt<AccountRepository>().add(
      name: 'Cash',
      currencyId: baseId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
    final categoryId =
        (await getIt<CategoryRepository>().getAll()).first.categoryId;
    return (baseId, accountId, categoryId);
  }

  test('reactively surfaces a newly added transaction', () async {
    final (baseId, accountId, categoryId) = await seedReady();
    final cubit = TransactionsListCubit(
      getIt<TransactionRepository>(),
      getIt<CurrencyRepository>(),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsThrough(
        predicate<TransactionsListState>(
          (s) =>
              s.status == TransactionsStatus.ready &&
              s.transactions.length == 1,
        ),
      ),
    );

    // Let the initial (empty) stream event flush, then write via the repo.
    await Future<void>.delayed(Duration.zero);
    await getIt<TransactionRepository>().add(
      accountId: accountId,
      categoryId: categoryId,
      currencyId: baseId,
      amount: 9.99,
      date: DateTime.now(),
      note: 'coffee',
      type: 'expense',
    );

    await expectation;
    await cubit.close();
  });

  test('totals are converted to the base currency', () async {
    await seedData();
    final currencyRepo = getIt<CurrencyRepository>();
    final all = await currencyRepo.getAll();
    final aId = all[0].currencyId;
    final bId = all[1].currencyId;
    await currencyRepo.makeBase(aId); // A base, rate 1.0
    await currencyRepo.setRate(bId, 2.0); // 1 B = 2 A

    final accountId = await getIt<AccountRepository>().add(
      name: 'Cash',
      currencyId: aId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
    final categoryId =
        (await getIt<CategoryRepository>().getAll()).first.categoryId;
    final now = DateTime.now();
    final txRepo = getIt<TransactionRepository>();
    await txRepo.add(
      accountId: accountId,
      categoryId: categoryId,
      currencyId: aId,
      amount: 10,
      date: now,
      type: 'income',
    );
    await txRepo.add(
      accountId: accountId,
      categoryId: categoryId,
      currencyId: bId,
      amount: 3,
      date: now,
      type: 'expense',
    );

    final cubit = TransactionsListCubit(txRepo, currencyRepo);
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<TransactionsListState>(
          (s) =>
              s.status == TransactionsStatus.ready &&
              s.transactions.length == 2,
        ),
      ),
    );

    final totals = cubit.state.totals;
    expect(totals['income'], 10.0);
    expect(totals['expense'], 6.0); // 3 B * 2 = 6 A
    await cubit.close();
  });

  test('selectPreset updates the state', () async {
    await seedReady();
    final cubit = TransactionsListCubit(
      getIt<TransactionRepository>(),
      getIt<CurrencyRepository>(),
    );
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<TransactionsListState>(
          (s) => s.status == TransactionsStatus.ready,
        ),
      ),
    );

    expect(cubit.state.preset, PeriodPreset.month);
    cubit.selectPreset(PeriodPreset.year);
    expect(cubit.state.preset, PeriodPreset.year);

    await cubit.close();
  });
}
