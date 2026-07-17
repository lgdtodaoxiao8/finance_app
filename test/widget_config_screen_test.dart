import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/features/widget_config/view/widget_config_screen.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the widget-config screen against a real in-memory database. This is
/// the substitute for on-simulator verification while the iOS toolchain has no
/// buildable destination — it exercises the actual DI wiring, the category
/// load, and the empty-shortcuts state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.memory();
    await getIt.reset();
    getIt
      ..registerSingleton<AppDatabase>(db)
      ..registerSingleton<AppPreferences>(
        AppPreferences(await SharedPreferences.getInstance()),
      )
      ..registerLazySingleton<CurrencyRepository>(
        () => DriftCurrencyRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<CategoryRepository>(
        () => DriftCategoryRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<AccountRepository>(
        () => DriftAccountRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<TransactionRepository>(
        () => DriftTransactionRepository(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<WidgetService>(
        () => WidgetService(
          getIt<TransactionRepository>(),
          getIt<CurrencyRepository>(),
          getIt<CategoryRepository>(),
          getIt<AppPreferences>(),
        ),
      );
    await seedData();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget host() => const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WidgetConfigScreen(),
  );

  testWidgets('renders with the empty-shortcuts state', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.widgetsTitle), findsWidgets);
    expect(find.text(l.widgetNoShortcuts), findsOneWidget);
    expect(find.text(l.widgetAddCategory), findsOneWidget);
  });

  testWidgets('opens the category picker when adding', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.widgetAddCategory));
    await tester.pumpAndSettle();

    // The seeded categories (Food / Salary) are offered in the picker sheet.
    expect(find.text(l.selectCategory), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });
}
