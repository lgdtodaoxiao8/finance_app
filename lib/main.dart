import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/widget_bridge/widget_interactivity.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bring up the backend client only once real Supabase keys are set; until
  // then the app runs fully local-first.
  if (AppConfig.isBackendConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  await configureDependencies();

  // await deleteAllData();

  await seedData();

  // Start publishing data to the native home-screen widget, then persist any
  // quick-adds queued by the widget buttons while the app was closed.
  await getIt<WidgetService>().start();
  await drainPendingQuickAdds();

  runApp(
    const FinanceApp(),
  );
}
