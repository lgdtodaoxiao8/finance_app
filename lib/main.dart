import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:finance_app/features/widget_bridge/widget_interactivity.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  // await deleteAllData();

  await seedData();

  // Start publishing data to the native home-screen widget, and register the
  // background handler for interactive widget buttons (quick-add).
  await getIt<WidgetService>().start();
  HomeWidget.registerInteractivityCallback(widgetInteractiveCallback);

  runApp(
    const FinanceApp(),
  );
}
