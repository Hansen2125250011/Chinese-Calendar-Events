import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getTheme(
      {required Color seedColor, required Brightness brightness}) {
    final baseTheme =
        brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(
      seedColor: const Color(0xFFD32F2F), brightness: Brightness.light);
  static ThemeData get darkTheme =>
      getTheme(seedColor: const Color(0xFFD32F2F), brightness: Brightness.dark);
}
