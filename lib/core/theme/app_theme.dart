import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple theme provider to switch between dark and light modes
final themeProvider = NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = light, true = dark

  void toggle() {
    state = !state;
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFFD10000);
  static const Color backgroundColor = Color(0xFFFFE6E6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData getFormTheme(BuildContext context) {
    final parent = Theme.of(context);
    final themeColor = parent.colorScheme.primary;
    return parent.copyWith(
      colorScheme: parent.colorScheme.copyWith(
        primary: themeColor,
        primaryContainer: themeColor,
      ),
      textSelectionTheme: parent.textSelectionTheme.copyWith(
        cursorColor: themeColor,
      ),
      inputDecorationTheme: parent.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: themeColor),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return themeColor;
          }
          return Colors.grey;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return themeColor;
          }
          return Colors.grey;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
