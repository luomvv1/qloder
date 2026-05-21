import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'views/auth/auth_gate.dart';

class QloderApp extends StatelessWidget {
  const QloderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'QLMA',
          themeMode: ThemeController.instance.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const AuthGate(),
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  return ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F766E),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCCFBF1),
      onPrimaryContainer: Color(0xFF134E4A),
      secondary: Color(0xFFB45309),
      onSecondary: Colors.white,
      surface: Color(0xFFFAFAF9),
      onSurface: Color(0xFF1C1917),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F4),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF5F5F4),
      foregroundColor: Color(0xFF1C1917),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE7E5E4)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    useMaterial3: true,
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2DD4BF),
      onPrimary: Color(0xFF042F2E),
      primaryContainer: Color(0xFF134E4A),
      onPrimaryContainer: Color(0xFFCCFBF1),
      secondary: Color(0xFFF59E0B),
      onSecondary: Color(0xFF451A03),
      surface: Color(0xFF18181B),
      onSurface: Color(0xFFE7E5E4),
    ),
    scaffoldBackgroundColor: const Color(0xFF111113),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFF111113),
      foregroundColor: Color(0xFFE7E5E4),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    useMaterial3: true,
  );
}
