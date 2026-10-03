import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppActionVariant { primary, secondary, destructive, quiet }

const _appBg = Color(0xFF09090B);
const _cardBg = Color(0xFF161618);
const _cardBorder = Color(0xFF27272A);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFF8E8E93);

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: _textPrimary),
      bodyMedium: TextStyle(color: _textPrimary),
      bodySmall: TextStyle(color: _textSecondary),
      titleLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _appBg,
    colorScheme: const ColorScheme.dark(
      surface: _appBg,
      primary: Colors.white,
      secondary: _textSecondary,
      surfaceContainer: _cardBg,
      outline: _cardBorder,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: _appBg,
      elevation: 0,
      iconTheme: IconThemeData(color: _textPrimary),
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: _cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _cardBorder, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _appBg,
      selectedItemColor: _textPrimary,
      unselectedItemColor: _textSecondary,
    ),
  );
}

const tabularFigures = [FontFeature.tabularFigures()];
