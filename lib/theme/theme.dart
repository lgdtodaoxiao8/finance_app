import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final themeFromSeed =
    ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        primaryFixedDim: const Color(0xFF1B50B8),
      ),
    ).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F7FA),
      ),
    );

final kTextStyle = GoogleFonts.ubuntu().copyWith(
  overflow: TextOverflow.ellipsis,
);
//inter
//ubuntu
//varela round
