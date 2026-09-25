import 'package:flutter/material.dart';

import '../helpers/theme_preferences.dart';
import '../theme/theme_helper.dart';

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
        return _buildTheme(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          onSurface: const Color(0xFFF3F4F6),
        );
      case AppTheme.indigo:
        return _buildTheme(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFF1E3A8A),
        );
      case AppTheme.rose:
        return _buildTheme(
          seedColor: const Color(0xFFBE123C),
          brightness: Brightness.light,
          surface: const Color(0xFFFFF1F2),
          onSurface: const Color(0xFF1E293B),
        );
      case AppTheme.teal:
        return _buildTheme(
          seedColor: const Color(0xFF008080),
          brightness: Brightness.light,
        );
    }
  }

  ThemeData _buildTheme({
    required Color seedColor,
    required Brightness brightness,
    Color? surface,
    Color? onSurface,
  }) {
    return ThemeHelper.buildThemeData(
      seedColor: seedColor,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
    );
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    ThemePreferences.saveTheme(theme.name);
    notifyListeners();
  }
}
