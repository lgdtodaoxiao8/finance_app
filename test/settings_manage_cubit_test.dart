import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/settings/cubit/accounts_cubit.dart';
import 'package:finance_app/features/settings/cubit/categories_cubit.dart';
import 'package:finance_app/features/settings/cubit/manage_status.dart';
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

  test('AccountsCubit deletes unused, blocks used', () async {
    final currencyRepo = getIt<CurrencyRepository>();
    final baseId = (await currencyRepo.getAll()).first.currencyId;
    await currencyRepo.makeBase(baseId);
    final accountRepo = getIt<AccountRepository>();
    final unusedId = await accountRepo.add(
      name: 'Unused',
      currencyId: baseId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
    final usedId = await accountRepo.add(
      name: 'Used',
      currencyId: baseId,
      iconCodePoint: Icons.account_balance_rounded.codePoint,
    );
    final categoryId =
        (await getIt<CategoryRepository>().getAll()).first.categoryId;
    await getIt<TransactionRepository>().add(
      accountId: usedId,
      categoryId: categoryId,
      currencyId: baseId,
      amount: 5,
      date: DateTime.now(),
      type: 'expense',
    );

    final cubit = AccountsCubit(accountRepo);
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AccountsState>(
          (s) => s.status == ManageStatus.ready && s.accounts.length == 2,
        ),
      ),
    );

    await cubit.delete(unusedId);
    await expectLater(
      cubit.stream,
      emitsThrough(predicate<AccountsState>((s) => s.accounts.length == 1)),
    );

    await cubit.delete(usedId);
    expect(cubit.state.message, contains("Can't delete"));
    expect(cubit.state.accounts.length, 1); // still there

    await cubit.close();
  });

  test('CategoriesCubit blocks deleting a used category', () async {
    final currencyRepo = getIt<CurrencyRepository>();
    final baseId = (await currencyRepo.getAll()).first.currencyId;
    await currencyRepo.makeBase(baseId);
    final accountId = await getIt<AccountRepository>().add(
      name: 'Cash',
      currencyId: baseId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
    final categoryRepo = getIt<CategoryRepository>();
    final categories = await categoryRepo.getAll();
    final usedCategoryId = categories[0].categoryId; // Food
    final unusedCategoryId = categories[1].categoryId; // Salary
    await getIt<TransactionRepository>().add(
      accountId: accountId,
      categoryId: usedCategoryId,
      currencyId: baseId,
      amount: 5,
      date: DateTime.now(),
      type: 'expense',
    );

    final cubit = CategoriesCubit(categoryRepo);
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<CategoriesState>(
          (s) => s.status == ManageStatus.ready && s.categories.length == 2,
        ),
      ),
    );

    await cubit.delete(usedCategoryId);
    expect(cubit.state.message, contains("Can't delete"));
    expect(cubit.state.categories.length, 2);

    await cubit.delete(unusedCategoryId);
    await expectLater(
      cubit.stream,
      emitsThrough(predicate<CategoriesState>((s) => s.categories.length == 1)),
    );

    await cubit.close();
  });
}
