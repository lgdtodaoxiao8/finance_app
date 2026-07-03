import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
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
    await seedData();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  test('re-basing divides all rates by the new base rate', () async {
    final repo = getIt<CurrencyRepository>();
    final all = await repo.getAll();
    final aId = all[0].currencyId;
    final bId = all[1].currencyId;

    // A is the base (rate 1.0), B is worth 2 A.
    await repo.makeBase(aId);
    expect(await repo.getRate(aId), 1.0);
    await repo.setRate(bId, 2.0);

    // Switch the base to B: B -> 1.0, A -> 0.5 (1 A = 0.5 B).
    await repo.makeBase(bId);
    expect(await repo.getRate(bId), 1.0);
    expect(await repo.getRate(aId), 0.5);
    expect((await repo.getBase())!.currencyId, bId);
  });
}
