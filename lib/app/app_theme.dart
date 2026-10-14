import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF14243A);
  static const blue = Color(0xFF0057B7);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: blue,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: navy,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      surfaceTintColor: Colors.transparent,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: blue,
      unselectedLabelColor: navy,
      indicatorColor: blue,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
