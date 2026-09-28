import 'package:flutter/material.dart';

import '../config/brand_config.dart';
import '../models/business.dart';

class ThemeHelper {
  static const _defaultPrimaryColor = Color(0xFF008080);

  static ThemeData buildThemeData({
    required Color seedColor,
    required Brightness brightness,
    Color? surface,
    Color? onSurface,
    String displayFont = 'Fraunces',
    String bodyFont = 'Inter',
  }) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    if (surface != null || onSurface != null) {
      colorScheme = colorScheme.copyWith(surface: surface, onSurface: onSurface);
    }
    if (brightness == Brightness.light && surface == null) {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ).copyWith(
        surface: Color.alphaBlend(
          const Color(0xFFFAF7F2).withValues(alpha: 0.6),
          colorScheme.surface,
        ),
      );
    }
    final baseTextTheme = Typography.material2021().englishLike.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      textTheme: baseTextTheme.copyWith(
        displayLarge:
            baseTextTheme.displayLarge?.copyWith(fontFamily: displayFont),
        displayMedium:
            baseTextTheme.displayMedium?.copyWith(fontFamily: displayFont),
        displaySmall:
            baseTextTheme.displaySmall?.copyWith(fontFamily: displayFont),
        headlineLarge:
            baseTextTheme.headlineLarge?.copyWith(fontFamily: displayFont),
        headlineMedium:
            baseTextTheme.headlineMedium?.copyWith(fontFamily: displayFont),
        headlineSmall:
            baseTextTheme.headlineSmall?.copyWith(fontFamily: displayFont),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontFamily: bodyFont,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: bodyFont),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: bodyFont),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: bodyFont),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: bodyFont),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: bodyFont),
      ),
      chipTheme: _buildChipTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
    );
  }

  static ThemeData generateTenantTheme(BusinessBranding? branding, {bool isDark = false}) {
    if (branding == null) {
      // No Firestore branding: fall back to the BrandConfig runtime
      // (assets/brand/maya.json mirror) instead of hardcoded literals.
      final config = BrandConfig.current;
      final seedColor =
          _parseHexColor(config.seedColorHex) ?? _defaultPrimaryColor;
      final brightness = _resolveBrightness(null, isDark);
      return buildThemeData(
        seedColor: seedColor,
        brightness: brightness,
        displayFont: config.displayFont,
        bodyFont: config.bodyFont,
      );
    }
    final seedColor = _parseHexColor(branding.primaryColor) ?? _defaultPrimaryColor;
    final brightness = _resolveBrightness(branding.themeMode, isDark);
    return buildThemeData(seedColor: seedColor, brightness: brightness);
  }

  static Brightness _resolveBrightness(String? themeMode, bool fallbackDark) {
    if (themeMode == null || themeMode.isEmpty) {
      return fallbackDark ? Brightness.dark : Brightness.light;
    }
    switch (themeMode.toLowerCase()) {
      case 'dark':
        return Brightness.dark;
      case 'light':
        return Brightness.light;
      default:
        return fallbackDark ? Brightness.dark : Brightness.light;
    }
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

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
      ColorScheme colorScheme) {
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
