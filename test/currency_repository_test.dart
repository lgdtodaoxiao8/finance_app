import 'package:drift/drift.dart' show Value;
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
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

  test('a rate correction freezes history; a base change re-expresses it',
      () async {
    final currencyRepo = getIt<CurrencyRepository>();
    getIt.registerLazySingleton<TransactionRepository>(
      () => DriftTransactionRepository(getIt<AppDatabase>()),
    );
    final txRepo = getIt<TransactionRepository>();

    final all = await currencyRepo.getAll();
    final usd = all[0].currencyId;
    final eur = all[1].currencyId;
    await currencyRepo.makeBase(usd); // USD base = 1.0
    await currencyRepo.setRate(eur, 1.1); // 1 EUR = 1.1 USD

    final accId = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: const Value('Cash')));
    final catId = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: const Value('Food')));

    Future<TransactionDetails> eurTx() async => (await txRepo
            .getAllWithDetails())
        .firstWhere((t) => t.currencyId == eur);

    // Log 100 EUR at 1.1 → snapshot base value 110.
    await txRepo.add(
      accountId: accId,
      categoryId: catId,
      currencyId: eur,
      amount: 100,
      date: DateTime(2026, 1, 1),
      type: 'expense',
    );
    expect((await eurTx()).amountInBase, closeTo(110, 1e-6));

    // Correct EUR's rate to 1.2. The OLD transaction stays frozen at 110.
    await currencyRepo.setRate(eur, 1.2);
    expect((await eurTx()).amountInBase, closeTo(110, 1e-6));

    // A NEW transaction uses the corrected 1.2 → base 120.
    await txRepo.add(
      accountId: accId,
      categoryId: catId,
      currencyId: eur,
      amount: 100,
      date: DateTime(2026, 2, 1),
      type: 'expense',
    );
    final baseValues = (await txRepo.getAllWithDetails())
        .where((t) => t.currencyId == eur)
        .map((t) => t.amountInBase.round())
        .toSet();
    expect(baseValues, {110, 120});

    // A BASE change to EUR re-expresses both snapshots (× 1/1.2):
    // 110 USD → ~91.67 EUR, 120 USD → 100 EUR.
    await currencyRepo.makeBase(eur);
    final reexpressed = (await txRepo.getAllWithDetails())
        .where((t) => t.currencyId == eur)
        .map((t) => t.amountInBase)
        .toList()
      ..sort();
    expect(reexpressed[0], closeTo(110 / 1.2, 1e-6));
    expect(reexpressed[1], closeTo(120 / 1.2, 1e-6));
  });
}
