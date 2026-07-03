import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/add_transaction/cubit/add_transaction_cubit.dart';
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

  Future<int> setupBaseAndAccount({String name = 'Cash'}) async {
    final currencyRepo = getIt<CurrencyRepository>();
    final baseId = (await currencyRepo.getAll()).first.currencyId;
    await currencyRepo.makeBase(baseId);
    return getIt<AccountRepository>().add(
      name: name,
      currencyId: baseId,
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
    );
  }

  AddTransactionCubit buildCubit() => AddTransactionCubit(
    getIt<AccountRepository>(),
    getIt<CategoryRepository>(),
    getIt<CurrencyRepository>(),
    getIt<TransactionRepository>(),
  );

  test('saves an expense with the defaulted selections', () async {
    final accountId = await setupBaseAndAccount();
    final cubit = buildCubit();
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AddTransactionState>(
          (s) => s.status == AddTransactionStatus.ready,
        ),
      ),
    );

    expect(cubit.state.accountId, accountId);
    expect(cubit.state.currencyId, isNotNull);
    expect(cubit.state.categoryId, isNotNull);
    expect(cubit.state.validationError, isNull);

    await cubit.add(amount: 5.0, note: 'lunch');
    expect(cubit.state.saved, isTrue);

    final txs = await getIt<TransactionRepository>().getAllWithDetails();
    expect(txs, hasLength(1));
    expect(txs.first.amount, 5.0);
    expect(txs.first.type, 'expense');
    await cubit.close();
  });

  test('transfer validation reacts to account selection', () async {
    await setupBaseAndAccount();
    final cubit = buildCubit();
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AddTransactionState>(
          (s) => s.status == AddTransactionStatus.ready,
        ),
      ),
    );

    cubit.setType('transfer', 2);
    expect(
      cubit.state.validationError,
      'You have no second account to transfer',
    );

    // Add a second account and refresh.
    await getIt<AccountRepository>().add(
      name: 'Bank',
      currencyId: cubit.state.currencyId!,
      iconCodePoint: Icons.account_balance_rounded.codePoint,
    );
    await cubit.reloadAccounts();
    cubit.setType('transfer', 2);
    expect(cubit.state.validationError, isNull);

    // Same source and destination is rejected.
    cubit.setAccountDestination(cubit.state.accountId!);
    expect(
      cubit.state.validationError,
      'Account departure and destination must be different',
    );
    await cubit.close();
  });
}
