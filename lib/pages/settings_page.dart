import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.settings ?? 'Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppLocalizations.of(context)?.profile ?? 'Edit profile'),
            subtitle: Text(auth.currentUser?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, Routes.profile),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(AppLocalizations.of(context)?.theme ?? 'Theme', style: Theme.of(context).textTheme.titleSmall),
          ),
          _ThemeTile(
            title: 'Teal Clean',
            theme: AppTheme.teal,
            iconColor: const Color(0xFF008080),
            selected: theme.currentTheme == AppTheme.teal,
          ),
          _ThemeTile(
            title: 'Midnight Dark',
            theme: AppTheme.dark,
            iconColor: const Color(0xFF6366F1),
            selected: theme.currentTheme == AppTheme.dark,
          ),
          _ThemeTile(
            title: 'Rose Gold',
            theme: AppTheme.rose,
            iconColor: const Color(0xFFBE123C),
            selected: theme.currentTheme == AppTheme.rose,
          ),
          _ThemeTile(
            title: 'Deep Slate',
            theme: AppTheme.indigo,
            iconColor: const Color(0xFF1E3A8A),
            selected: theme.currentTheme == AppTheme.indigo,
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppLocalizations.of(context)?.language ?? 'Language',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final currentLanguage = _languageOptions.firstWhere(
                (option) => option['locale'] == localeProvider.locale,
                orElse: () => _languageOptions.first,
              );

              return ListTile(
                leading: Text(
                  currentLanguage['flag'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(currentLanguage['name'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, localeProvider),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)?.signOut ?? 'Logout'),
            onTap: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  static const _languageOptions = [
    {'locale': Locale('en'), 'name': 'English', 'flag': '🇬🇧'},
    {'locale': Locale('ro'), 'name': 'Română', 'flag': '🇷🇴'},
    {'locale': Locale('de'), 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'locale': Locale('hu'), 'name': 'Magyar', 'flag': '🇭🇺'},
  ];

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
        children: _languageOptions.map((option) {
          final locale = option['locale'] as Locale;
          final name = option['name'] as String;
          final flag = option['flag'] as String;
          final isSelected = localeProvider.locale == locale;

          return SimpleDialogOption(
            onPressed: () {
              localeProvider.setLocale(locale);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(child: Text(name)),
                if (isSelected) const Icon(Icons.check, color: Colors.green),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.theme,
    required this.iconColor,
    required this.selected,
  });

  final String title;
  final AppTheme theme;
  final Color iconColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.color_lens, color: iconColor),
      title: Text(title),
      trailing:
          selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: () =>
          Provider.of<ThemeProvider>(context, listen: false).setTheme(theme),
    );
  }
}
