import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    fontFamily: 'inter',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6E21B5),
      secondary: Color(0xFFD5E9ED),
      surface: Colors.white,
      onSurface: Color(0xFF414A4C),
      tertiary: Color(0xFF414A4C),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: const Color(0xFF6E21B5)),
    ),
  );
}
