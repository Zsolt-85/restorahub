import 'package:flutter/material.dart';

import '../helpers/theme_preferences.dart';

enum AppTheme { teal, dark, rose, indigo }

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.teal;

  AppTheme get currentTheme => _currentTheme;

  Future<void> loadTheme() async {
    final savedTheme = await ThemePreferences.getTheme();
    if (savedTheme == null) return;

    _currentTheme = AppTheme.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => AppTheme.teal,
    );
    notifyListeners();
  }

  ThemeData get theme {
    switch (_currentTheme) {
      case AppTheme.dark:
        return ThemeData.dark().copyWith(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.grey,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        );
      case AppTheme.indigo:
        return ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.light(
            primary: Colors.indigo,
            secondary: Colors.indigoAccent,
          ),
        );
      case AppTheme.rose:
        return ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFFE91E63),
          scaffoldBackgroundColor: const Color(0xFFFFF5F8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE91E63),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE91E63),
            secondary: Color(0xFFF48FB1),
          ),
        );
      case AppTheme.teal:
        return ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF4DB6AC),
          scaffoldBackgroundColor: const Color(0xFFF2FBFA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4DB6AC),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4DB6AC),
            secondary: Color(0xFF80CBC4),
          ),
        );
    }
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    ThemePreferences.saveTheme(theme.name);
    notifyListeners();
  }
}
