import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;

        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          );
        }

        final initials = user.name.isNotEmpty
            ? user.name.substring(0, 1).toUpperCase()
            : '?';

        return PopupMenuButton<String>(
          onSelected: (value) => _handleMenuSelection(context, auth, value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(AppLocalizations.of(context)?.editProfile ?? 'Profile Settings'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme',
              child: ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: Text(AppLocalizations.of(context)?.theme ?? 'Theme Selection'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.of(context)?.menuLogout ?? 'Log Out'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(
      BuildContext context, AuthProvider auth, String value) {
    switch (value) {
      case 'profile':
        Navigator.pushNamed(context, Routes.profile);
        break;
      case 'theme':
        _showThemeSelector(context);
        break;
      case 'logout':
        auth.logout();
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
        break;
    }
  }

  void _showThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentTheme = themeProvider.currentTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.theme ?? 'Theme Selection',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            final isSelected = currentTheme == theme;
            return ListTile(
              leading: Icon(Icons.color_lens, color: _themeColor(theme)),
              title: Text(
                _themeLabel(theme),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setTheme(theme);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _themeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.teal:
        return const Color(0xFF008080);
      case AppTheme.dark:
        return const Color(0xFF6366F1);
      case AppTheme.rose:
        return const Color(0xFFBE123C);
      case AppTheme.indigo:
        return const Color(0xFF1E3A8A);
    }
  }

  String _themeLabel(AppTheme theme) {
    switch (theme) {
      case AppTheme.teal:
        return 'Teal Clean';
      case AppTheme.dark:
        return 'Midnight Dark';
      case AppTheme.rose:
        return 'Rose Gold';
      case AppTheme.indigo:
        return 'Deep Slate';
    }
  }
}
