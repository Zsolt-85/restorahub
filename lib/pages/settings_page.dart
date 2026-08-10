import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit profile'),
            subtitle: Text(auth.currentUser?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Theme', style: Theme.of(context).textTheme.titleSmall),
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
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
