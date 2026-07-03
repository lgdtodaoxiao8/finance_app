import 'package:finance_app/core/database/app_database.dart';
import 'package:get_it/get_it.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// Wires up singletons. Call once at startup, before any data access.
///
/// Phase 1 registers the Drift [AppDatabase]. Repositories and blocs are
/// added here as features are migrated in Phase 2.
Future<void> configureDependencies() async {
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerSingleton<AppDatabase>(AppDatabase());
  }
}
