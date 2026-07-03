import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/finance_app/finance_app.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  // await deleteAllData();

  await seedData();

  runApp(
    const FinanceApp(),
  );
}
