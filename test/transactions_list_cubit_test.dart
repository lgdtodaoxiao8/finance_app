import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/database/database_helper.dart';
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
      );
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<(int baseId, int accountId, int categoryId)> seedReady() async {
    final helper = DatabaseHelper.instance;
    await seedData();
    final baseId = (await helper.getAllCurrencies()).first['id'] as int;
    await helper.makeCurrencyBase(baseId);
    final accountId = (await helper.insert('accounts', {
      'name': 'Cash',
      'currency_id': baseId,
      'icon_code_point': Icons.account_balance_wallet_rounded.codePoint,
    }))!;
    final categoryId =
        (await helper.getAll('categories')).first['id'] as int;
    return (baseId, accountId, categoryId);
  }

  test('reactively surfaces a newly added transaction', () async {
    final (baseId, accountId, categoryId) = await seedReady();
    final cubit = TransactionsListCubit(getIt<TransactionRepository>());

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

    // Let the initial (empty) stream event flush, then write via the facade.
    await Future<void>.delayed(Duration.zero);
    await DatabaseHelper.instance.insert('transactions', {
      'account_id': accountId,
      'category_id': categoryId,
      'currency_id': baseId,
      'amount': 9.99,
      'date': DateTime.now().toUtc().toIso8601String(),
      'note': 'coffee',
      'type': 'expense',
      'is_canceled': 0,
    });

    await expectation;
    await cubit.close();
  });

  test('selectPreset updates the state', () async {
    await seedReady();
    final cubit = TransactionsListCubit(getIt<TransactionRepository>());
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
