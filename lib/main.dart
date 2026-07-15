import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the launch path minimal so the UI appears instantly. Only local,
  // fast work runs before runApp: DI wiring + first-run seed. The backend
  // (Supabase session refresh — a network call), home-widget publishing and
  // the first sync are all brought up AFTER the first frame in FinanceApp,
  // so the user never waits on the network to open the app.
  // Date symbols for every locale we format dates in (intl only ships en_US
  // by default — DateFormat with 'ru' would throw without this).
  await initializeDateFormatting();

  await configureDependencies();
  await seedData();
  // Load preferences before the first frame so theme + language are correct
  // from the start (a fast local read; cloud values arrive later via sync).
  await getIt<SettingsService>().load();

  runApp(const FinanceApp());
}
