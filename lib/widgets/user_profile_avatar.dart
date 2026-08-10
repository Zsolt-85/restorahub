import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profile Settings'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'theme',
              child: ListTile(
                leading: Icon(Icons.color_lens_outlined),
                title: Text('Theme Selection'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log Out'),
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
        Navigator.pushNamed(context, '/profile');
        break;
      case 'theme':
        _showThemeSelector(context);
        break;
      case 'logout':
        auth.logout();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        break;
    }
  }

  void _showThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentTheme = themeProvider.currentTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            final isSelected = currentTheme == theme;
            return ListTile(
              leading: Icon(Icons.color_lens, color: _themeColor(theme)),
              title: Text(_themeLabel(theme)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
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
        return const Color(0xFF4DB6AC);
      case AppTheme.dark:
        return Colors.black87;
      case AppTheme.rose:
        return const Color(0xFFE91E63);
      case AppTheme.indigo:
        return Colors.indigo;
    }
  }

  String _themeLabel(AppTheme theme) {
    switch (theme) {
      case AppTheme.teal:
        return 'Teal';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.rose:
        return 'Rose';
      case AppTheme.indigo:
        return 'Indigo';
    }
  }
}
