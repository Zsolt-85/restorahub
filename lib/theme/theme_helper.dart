import 'package:flutter/material.dart';

class ThemeHelper {
  static const _defaultPrimaryColor = Color(0xFF008080);

  static ThemeData generateTenantTheme(String? hexColor, {bool isDark = false}) {
    final seedColor = _parseHexColor(hexColor) ?? _defaultPrimaryColor;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      chipTheme: _buildChipTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
    );
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var input = hex.trim();
    if (input.startsWith('#')) {
      input = input.substring(1);
    }
    if (input.length == 6) {
      input = '${input}FF';
    }
    if (input.length != 8) return null;
    final intValue = int.tryParse('0x$input');
    if (intValue == null) return null;
    return Color(intValue);
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return ChipThemeData(
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      disabledColor: onSurface.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
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

  static TabBarThemeData _buildTabBarTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return TabBarThemeData(
      indicator: BoxDecoration(color: colorScheme.primary),
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.onPrimary,
      unselectedLabelColor: onSurface.withValues(alpha: 0.6),
      unselectedLabelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
    );
  }
}
