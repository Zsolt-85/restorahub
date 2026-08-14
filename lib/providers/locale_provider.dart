import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _selectedLanguageKey = 'selected_language';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('ro'),
    Locale('de'),
    Locale('hu'),
  ];

  LocaleProvider() {
    loadSavedLocale();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, newLocale.languageCode);
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_selectedLanguageKey);

    if (savedLanguage != null &&
        supportedLocales.any((locale) => locale.languageCode == savedLanguage)) {
      _locale = Locale(savedLanguage);
      notifyListeners();
    }
  }
}
