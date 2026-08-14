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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: onSurface,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      chipTheme: _buildChipTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
    );
  }

  ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return ChipThemeData(
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      disabledColor: onSurface.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return onSurface.withValues(alpha: 0.12);
          }
          return colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onPrimary;
        }),
      ),
    );
  }

  TabBarThemeData _buildTabBarTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return TabBarThemeData(
      indicator: BoxDecoration(color: colorScheme.primary),
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.onPrimary,
      unselectedLabelColor: onSurface.withValues(alpha: 0.6),
      unselectedLabelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
    );
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    ThemePreferences.saveTheme(theme.name);
    notifyListeners();
  }
}
