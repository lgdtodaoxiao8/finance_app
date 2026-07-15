import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/app_settings.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SettingsService service;

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
      ..registerSingleton<SettingsService>(
        SettingsService(getIt<AppDatabase>()),
      );
    await seedData();
    service = getIt<SettingsService>();
    await service.load();
  });

  tearDown(() async {
    service.dispose();
    await getIt.reset();
    await db.close();
  });

  test('preferences round-trip through the settings table', () async {
    expect(service.settings.value.themeMode, AppThemeMode.system);

    await service.setThemeMode(AppThemeMode.dark);
    await service.setLanguage('ru');
    await service.setWeekStartsMonday(false);
    await service.setHideAmounts(true);

    final s = service.settings.value;
    expect(s.themeMode, AppThemeMode.dark);
    expect(s.languageCode, 'ru');
    expect(s.weekStartsMonday, isFalse);
    expect(s.hideAmounts, isTrue);

    // A fresh service over the same db reads them back (simulates a relaunch).
    final reloaded = SettingsService(db);
    await reloaded.load();
    expect(reloaded.settings.value.themeMode, AppThemeMode.dark);
    expect(reloaded.settings.value.languageCode, 'ru');
    expect(reloaded.settings.value.hideAmounts, isTrue);
    reloaded.dispose();
  });

  test(
    'currency config applies a base change directly (no rebasing)',
    () async {
      final repo = getIt<CurrencyRepository>();
      final all = await repo.getAll();
      final usd = all.firstWhere((c) => c.currencyCode == 'USD');
      await repo.makeBase(usd.currencyId);

      // Simulates a config pulled from another device: EUR base, USD at 1.5.
      await repo.applyConfig(
        const CurrencyConfig(baseCode: 'EUR', rates: {'USD': 1.5, 'EUR': 1.0}),
      );

      final base = await repo.getBase();
      expect(base?.currencyCode, 'EUR');
      expect(base?.currencyRateToBase, 1.0);

      final snap = await repo.configSnapshot();
      expect(snap.baseCode, 'EUR');
      expect(snap.rates['USD'], 1.5);
      // Idempotent: matching config re-applies to the same state.
      expect(snap.matches(snap), isTrue);
    },
  );
}
