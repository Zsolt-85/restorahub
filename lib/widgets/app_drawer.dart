import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/notification_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.user, required this.auth});

  final User user;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notifProvider.unreadCount;
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final isAdmin = (user.role == 'business_admin' || user.role == 'super_admin') && businessProvider.hasBusiness;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(
              user.phone.isNotEmpty ? user.phone : user.email,
            ),
            currentAccountPicture: CircleAvatar(
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(AppLocalizations.of(context)?.menuNotifications ?? 'Notifications'),
            trailing: unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.notifications);
            },
          ),
          if (user.role == 'super_admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Super Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.superAdminDashboard);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: Text(AppLocalizations.of(context)?.menuAnalytics ?? 'Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.analytics);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppLocalizations.of(context)?.menuEditProfile ?? 'Edit profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(AppLocalizations.of(context)?.menuPastAppointments ?? 'Past appointments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.pastAppointments);
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(AppLocalizations.of(context)?.businessSettings ?? 'Business Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.businessSettings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Team Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.teamManagement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.design_services),
              title: const Text('Services Catalog'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.services);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Staff Calendar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.adminCalendar);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(AppLocalizations.of(context)?.menuSettings ?? 'Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)?.menuLogout ?? 'Logout'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppLocalizations.of(context)?.logoutConfirmation ?? 'Logout'),
                  content: Text(AppLocalizations.of(context)?.logoutConfirmation ?? 'Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        auth.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.login,
                          (route) => false,
                        );
                      },
                      child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}