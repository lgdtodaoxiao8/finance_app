import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  // await deleteAllData();

  await seedData();

  // Start publishing data to the native home-screen widget.
  await getIt<WidgetService>().start();

  runApp(
    const FinanceApp(),
  );
}
