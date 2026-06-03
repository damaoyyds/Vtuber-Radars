import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF8B5CF6);
const Color primaryLight = Color(0xFFA78BFA);
const Color primaryDark = Color(0xFF7C3AED);
const Color secondaryColor = Color(0xFFEC4899);
const Color secondaryLight = Color(0xFFF472B6);

const Color bgGradientStart = Color(0xFFF5F3FF);
const Color bgGradientEnd = Color(0xFFEEF2FF);

const Color cardBg = Colors.white;
const Color cardBorder = Color(0xFFEDE9FE);

const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color textTertiary = Color(0xFF9CA3AF);

const Color statusLive = Color(0xFF10B981);
const Color statusUpcoming = Color(0xFFF59E0B);

const double borderRadius = 24.0;
const double cardShadowBlur = 20.0;

ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    primary: primaryColor,
    secondary: secondaryColor,
  ),
  useMaterial3: true,
  fontFamily: 'PingFang SC, Microsoft YaHei, sans-serif',
  scaffoldBackgroundColor: bgGradientStart,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    filled: true,
    fillColor: cardBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  ),
);

BoxDecoration cardDecoration = BoxDecoration(
  color: cardBg,
  borderRadius: BorderRadius.circular(borderRadius),
  border: Border.all(color: cardBorder, width: 1),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: cardShadowBlur,
      offset: const Offset(0, 4),
    ),
  ],
);

BoxDecoration gradientButtonDecoration = BoxDecoration(
  gradient: const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
);

BoxDecoration bgGradient = const BoxDecoration(
  gradient: LinearGradient(
    colors: [bgGradientStart, bgGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
);