import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/brand_config.dart';
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

    test('applies shared card, input, and app bar themes', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(primaryColor: '#008080'),
      );

      expect(theme.cardTheme.margin, const EdgeInsets.only(bottom: 12));
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
    });

    test('applies premium type scale and warm paper surface', () {
      final theme = ThemeHelper.generateTenantTheme(
        BusinessBranding(primaryColor: '#2F5D50'),
      );

      expect(theme.textTheme.displayLarge?.fontFamily, contains('Fraunces'));
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('Inter'));
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('null branding uses BrandConfig seed and fonts', () async {
      BrandConfig.setCurrentForTest(
        await BrandConfig.load(
          jsonString:
              '{"seedColor":"#123456","displayFont":"TestDisplay","bodyFont":"TestBody"}',
        ),
      );
      addTearDown(() async {
        BrandConfig.setCurrentForTest(
          await BrandConfig.load(jsonString: '{}'),
        );
      });
      final theme = ThemeHelper.generateTenantTheme(null);

      expect(theme.textTheme.displayLarge?.fontFamily, 'TestDisplay');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'TestBody');
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(
          seedColor: const Color(0x123456FF),
          brightness: Brightness.light,
        ).primary,
      );
    });
  });
}
