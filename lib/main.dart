import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the launch path minimal so the UI appears instantly. Only local,
  // fast work runs before runApp: DI wiring + first-run seed. The backend
  // (Supabase session refresh — a network call), home-widget publishing and
  // the first sync are all brought up AFTER the first frame in FinanceApp,
  // so the user never waits on the network to open the app.
  await configureDependencies();
  await seedData();

  runApp(const FinanceApp());
}
