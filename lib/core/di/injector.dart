import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/budget_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/subscription/entitlement_service.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/sync/sync_service.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// Wires up singletons. Call once at startup, before any data access.
///
/// Registers the Drift [AppDatabase] and the typed repositories built on top
/// of it. Blocs/cubits are created per-screen (via BlocProvider) and pull
/// their repository from here.
Future<void> configureDependencies() async {
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerSingleton<AppDatabase>(AppDatabase());
  }

  if (!getIt.isRegistered<AppPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<AppPreferences>(AppPreferences(prefs));
  }

  if (!getIt.isRegistered<SettingsService>()) {
    getIt.registerSingleton<SettingsService>(
      SettingsService(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<SubscriptionService>()) {
    getIt.registerSingleton<SubscriptionService>(
      SubscriptionService(getIt<AppPreferences>()),
    );
  }

  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerSingleton<AuthService>(AuthService());
  }

  if (!getIt.isRegistered<EntitlementService>()) {
    getIt.registerSingleton<EntitlementService>(
      EntitlementService(getIt<AuthService>(), getIt<SubscriptionService>()),
    );
  }

  if (!getIt.isRegistered<SyncService>()) {
    getIt.registerSingleton<SyncService>(
      SyncService(getIt<AppDatabase>(), getIt<AuthService>()),
    );
  }

  if (!getIt.isRegistered<AiService>()) {
    getIt.registerSingleton<AiService>(AiService(getIt<AppPreferences>()));
  }

  if (!getIt.isRegistered<TransactionRepository>()) {
    getIt.registerLazySingleton<TransactionRepository>(
      () => DriftTransactionRepository(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<CurrencyRepository>()) {
    getIt.registerLazySingleton<CurrencyRepository>(
      () => DriftCurrencyRepository(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<AccountRepository>()) {
    getIt.registerLazySingleton<AccountRepository>(
      () => DriftAccountRepository(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<CategoryRepository>()) {
    getIt.registerLazySingleton<CategoryRepository>(
      () => DriftCategoryRepository(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<BudgetRepository>()) {
    getIt.registerLazySingleton<BudgetRepository>(
      () => DriftBudgetRepository(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<WidgetService>()) {
    getIt.registerLazySingleton<WidgetService>(
      () => WidgetService(
        getIt<TransactionRepository>(),
        getIt<CurrencyRepository>(),
        getIt<CategoryRepository>(),
        getIt<AppPreferences>(),
      ),
    );
  }
}
