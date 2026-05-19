import 'package:flutter/material.dart';

import 'views/auth/auth_gate.dart';

class QloderApp extends StatelessWidget {
  const QloderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QLMA',
      theme: ThemeData(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
