import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark = true;

  static const Color accent = Color(0xFF8B5CF6);
  static const Color accent2 = Color(0xFF06B6D4);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
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
