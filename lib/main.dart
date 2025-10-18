import 'package:finance_app/finance_app.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final kColorTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
);

final kTextStyle = GoogleFonts.ubuntu();

//inter
//ubuntu
//varela round

void main() {
  runApp(
    MaterialApp(
      theme: kColorTheme,
      home: const FinanceApp(),
    ),
  );
}
