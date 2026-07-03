import 'package:finance_app/router/router.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeFromSeed,
      routes: routes,
    );
  }
}
