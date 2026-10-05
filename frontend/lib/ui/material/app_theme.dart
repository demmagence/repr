import 'dart:io';
import 'package:flutter/material.dart';
enum AppActionVariant { primary, secondary, destructive, quiet }

const _appBg = Color(0xFF09090B);
const _cardBg = Color(0xFF161618);
const _cardBorder = Color(0xFF27272A);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFF8E8E93);

const sfProDisplayFontFamily = 'SF Pro Display';

ThemeData buildAppTheme() {
  const baseTextTheme = TextTheme(
    headlineLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: _textPrimary),
    bodyMedium: TextStyle(color: _textPrimary),
    bodySmall: TextStyle(color: _textSecondary),
    labelLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: _textSecondary),
  );

  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  final textTheme = isTest
      ? baseTextTheme
      : baseTextTheme.apply(
          fontFamily: sfProDisplayFontFamily,
          fontFamilyFallback: const [
            '.SF Pro Display',
            'SF Pro Display Bold',
            'sans-serif',
          ],
        );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: isTest ? null : sfProDisplayFontFamily,
    fontFamilyFallback: isTest
        ? null
        : const ['.SF Pro Display', 'SF Pro Display Bold', 'sans-serif'],
    scaffoldBackgroundColor: _appBg,
    colorScheme: const ColorScheme.dark(
      surface: _appBg,
      primary: Colors.white,
      secondary: _textSecondary,
      surfaceContainer: _cardBg,
      outline: _cardBorder,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _appBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: _textPrimary),
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: isTest ? null : sfProDisplayFontFamily,
      ),
    ),
    cardTheme: CardThemeData(
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
