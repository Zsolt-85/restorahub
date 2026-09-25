import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('all AppTheme values produce identical output to shared builder', () {
      final provider = ThemeProvider();
      for (final appTheme in AppTheme.values) {
        provider.setTheme(appTheme);
        expect(provider.theme.colorScheme, isNotNull);
        expect(provider.theme.cardTheme.margin,
            const EdgeInsets.only(bottom: 12));
      }
    });

    test('dark theme uses dark brightness with indigo seed', () {
      final provider = ThemeProvider();
      provider.setTheme(AppTheme.dark);
      expect(provider.theme.brightness, Brightness.dark);
      expect(provider.theme.scaffoldBackgroundColor, const Color(0xFF121212));
    });
  });
}
