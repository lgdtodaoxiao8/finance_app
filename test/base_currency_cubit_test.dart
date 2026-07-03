import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
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
      );
    // seedData writes directly through the Drift AppDatabase from getIt.
    await seedData();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  test('first setup makes a currency base with rate 1.0', () async {
    final repo = getIt<CurrencyRepository>();
    final cubit = BaseCurrencyCubit(repo);

    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<BaseCurrencyState>(
          (s) => s.status == BaseCurrencyStatus.ready,
        ),
      ),
    );
    expect(cubit.state.isFirstSetup, isTrue);

    final firstId = cubit.state.currencies.first.currencyId;
    await cubit.selectCurrency(firstId);
    expect(cubit.state.needToEnterRate, isFalse);

    final submitFuture = cubit.submit();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final base = await repo.getBase();
    expect(base?.currencyId, firstId);
    expect(base?.currencyRateToBase, 1.0);

    await submitFuture;

    // With a base set, picking a rate-less currency now requires a rate.
    final other = cubit.state.currencies.firstWhere(
      (c) => c.currencyId != firstId,
    );
    await cubit.selectCurrency(other.currencyId);
    expect(cubit.state.isFirstSetup, isFalse);
    expect(cubit.state.needToEnterRate, isTrue);

    await cubit.close();
  });
}
