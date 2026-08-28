import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/theme/theme_helper.dart';

void main() {
  group('ThemeHelper', () {
    test('generates theme from BusinessBranding primary color', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(primaryColor: '#FF5733'),
      );

      expect(theme.colorScheme.primary, isNotNull);
    });

    test('falls back to default color when branding is null', () {
      final theme = ThemeHelper.generateTenantTheme(null);

      expect(theme.colorScheme.primary, isNotNull);
    });

    test('falls back to default color when primaryColor is empty', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(primaryColor: ''),
      );

      expect(theme.colorScheme.primary, isNotNull);
    });

    test('generates dark theme when themeMode is dark', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(
          primaryColor: '#FF5733',
          themeMode: 'dark',
        ),
      );

      expect(theme.brightness, Brightness.dark);
    });

    test('generates light theme when themeMode is light', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(
          primaryColor: '#FF5733',
          themeMode: 'light',
        ),
      );

      expect(theme.brightness, Brightness.light);
    });

    test('falls back to light when themeMode is unknown', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(
          primaryColor: '#FF5733',
          themeMode: 'unknown',
        ),
      );

      expect(theme.brightness, Brightness.light);
    });

    test('generates dark theme with fallback flag when branding is null', () {
      final theme = ThemeHelper.generateTenantTheme(null, isDark: true);

      expect(theme.brightness, Brightness.dark);
    });

    test('generates theme with full branding config', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(
          primaryColor: '#FF5733',
          secondaryColor: '#33FF57',
          accentColor: '#3357FF',
          themeMode: 'light',
        ),
      );

      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.chipTheme, isNotNull);
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.tabBarTheme, isNotNull);
    });
  });
}
