import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../helpers/feature_gate.dart';
import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../widgets/app_drawer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final businessProvider = Provider.of<BusinessProvider>(context);
    final business = businessProvider.currentBusiness;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }

    final hasMultiLocation =
        business != null && FeatureGate.isAvailable(business, 'multiLocation');
    final locations = business?.locations ?? const <Location>[];
    final activeLocation = businessProvider.activeLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (hasMultiLocation && locations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeLocation?.id,
                  hint: Text(AppLocalizations.of(context)?.selectLocation ??
                      'Select Location'),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(AppLocalizations.of(context)?.allLocations ??
                          'All Locations'),
                    ),
                    ...locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location.id,
                        child: Text(location.name),
                      );
                    }),
                  ],
                  onChanged: (locationId) {
                    businessProvider.setActiveLocation(locationId);
                  },
                ),
              ),
            ),
        ],
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user.name}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (business != null) ...[
                Text(
                  'Business: ${business.name}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${business.status.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (hasMultiLocation && activeLocation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Active Location: ${activeLocation.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _AdminNavButton(
                    icon: Icons.store,
                    label: 'Business Settings',
                    onTap: () => Navigator.pushNamed(
                        context, Routes.businessSettings),
                  ),
                  _AdminNavButton(
                    icon: Icons.people,
                    label: 'Team Management',
                    onTap: () => Navigator.pushNamed(
                        context, Routes.teamManagement),
                  ),
                  _AdminNavButton(
                    icon: Icons.design_services,
                    label: 'Services Catalog',
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.services),
                  ),
                  _AdminNavButton(
                    icon: Icons.calendar_month,
                    label: 'Staff Calendar',
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.adminCalendar),
                  ),
                  _AdminNavButton(
                    icon: Icons.dashboard_outlined,
                    label: 'Analytics Dashboard',
                    onTap: () => Navigator.pushNamed(
                        context, Routes.analyticsDashboard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavButton extends StatelessWidget {
  const _AdminNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 88,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
