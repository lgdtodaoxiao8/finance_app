import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:get_it/get_it.dart';

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
}
