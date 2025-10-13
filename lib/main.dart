import 'package:finance_app/finance_app.dart';
import 'package:flutter/material.dart';

final kColorTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
);

void main() {
  runApp(
    MaterialApp(
      theme: kColorTheme,
      home: const FinanceApp(),
    ),
  );
}
