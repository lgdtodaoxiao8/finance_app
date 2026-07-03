import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_account_cubit.dart';
import 'package:finance_app/features/add_item/cubit/add_category_cubit.dart';
import 'package:finance_app/features/add_item/cubit/add_currency_cubit.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
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
      );
    await seedData();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  test('AddCategoryCubit saves a category', () async {
    final cubit = AddCategoryCubit(getIt<CategoryRepository>());
    cubit.setColor(Colors.red);
    cubit.setIconColor(Colors.white);
    cubit.setIcon(Icons.fastfood_rounded);

    await cubit.save('Groceries');

    expect(cubit.state.savedId, isNotNull);
    final categories = await getIt<CategoryRepository>().getAll();
    expect(categories.any((c) => c.categoryName == 'Groceries'), isTrue);
    await cubit.close();
  });

  test('AddCurrencyCubit sets the base currency on first setup', () async {
    final cubit = AddCurrencyCubit(getIt<CurrencyRepository>());
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AddCurrencyState>(
          (s) => s.status == AddCurrencyStatus.ready,
        ),
      ),
    );
    expect(cubit.state.baseIsNotSet, isTrue);

    final selectedId = cubit.state.selectedId!;
    await cubit.save();

    expect(cubit.state.savedId, selectedId);
    final base = await getIt<CurrencyRepository>().getBase();
    expect(base?.currencyId, selectedId);
    await cubit.close();
  });

  test('AddAccountCubit saves an account on the base currency', () async {
    final currencyRepo = getIt<CurrencyRepository>();
    final baseId = (await currencyRepo.getAll()).first.currencyId;
    await currencyRepo.makeBase(baseId);

    final cubit = AddAccountCubit(getIt<AccountRepository>(), currencyRepo);
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AddAccountState>((s) => s.status == AddAccountStatus.ready),
      ),
    );
    expect(cubit.state.selectedCurrencyId, baseId);

    cubit.setIcon(Icons.account_balance_wallet_rounded);
    await cubit.save('Wallet');

    expect(cubit.state.savedId, isNotNull);
    final accounts = await getIt<AccountRepository>().getAll();
    expect(accounts.any((a) => a.accountName == 'Wallet'), isTrue);
    await cubit.close();
  });
}
