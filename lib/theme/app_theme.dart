import 'package:flutter/material.dart';

class AppAccent {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;

  const AppAccent({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
  });
}

class AppTheme {
  static bool isDark = true;
  static String darkAccentId = 'purple';
  static String lightAccentId = 'blue';

  static const List<AppAccent> accents = [
    AppAccent(
      id: 'purple',
      name: 'بنفش',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF06B6D4),
    ),
    AppAccent(
      id: 'blue',
      name: 'آبی',
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF22D3EE),
    ),
    AppAccent(
      id: 'pink',
      name: 'صورتی',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFF8B5CF6),
    ),
    AppAccent(
      id: 'red',
      name: 'قرمز',
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFF97316),
    ),
    AppAccent(
      id: 'orange',
      name: 'نارنجی',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFFACC15),
    ),
    AppAccent(
      id: 'gold',
      name: 'طلایی',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFEF4444),
    ),
    AppAccent(
      id: 'green',
      name: 'سبز',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF84CC16),
    ),
    AppAccent(
      id: 'teal',
      name: 'فیروزه‌ای',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF0EA5E9),
    ),
  ];

  static AppAccent _byId(String id) =>
      accents.firstWhere((a) => a.id == id, orElse: () => accents[0]);

  static AppAccent get darkAccent => _byId(darkAccentId);
  static AppAccent get lightAccent => _byId(lightAccentId);
  static AppAccent get current => isDark ? darkAccent : lightAccent;

  static Color get accent => current.primary;
  static Color get accent2 => current.secondary;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightAccent.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkAccent.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070B14),
      );

  static Color get background =>
      isDark ? const Color(0xFF070B14) : const Color(0xFFF5F7FA);
  static Color get surface =>
      isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  static Color get surfaceSoft => isDark
      ? const Color.fromRGBO(255, 255, 255, 0.04)
      : const Color.fromRGBO(0, 0, 0, 0.05);
  static Color get cardBorder => isDark ? Colors.white12 : Colors.black12;
  static Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF111827);
  static Color get textSecondary =>
      isDark ? Colors.white70 : Colors.black87;
  static Color get textMuted => isDark ? Colors.white54 : Colors.black54;
  static Color get textFaint => isDark ? Colors.white38 : Colors.black38;
  static Color get iconActive =>
      isDark ? Colors.white : const Color(0xFF111827);
  static Color get iconInactive =>
      isDark ? Colors.white38 : Colors.black38;
  static Color get placeholder =>
      isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE5E7EB);
  static Color get sliderInactive =>
      isDark ? Colors.white12 : Colors.black12;
}
