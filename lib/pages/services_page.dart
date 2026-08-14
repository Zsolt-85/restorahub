import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../constants/constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  void _openSubtypePicker(BuildContext context, String service) {
    final subtypes = serviceTypes[service] ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose $service type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...subtypes.map(
                  (subtype) => Card(
                    color: colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(subtype, style: TextStyle(color: colorScheme.onSurface)),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          Routes.booking,
                          arguments: '$service — $subtype',
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.services ?? 'Services')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: serviceNames.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, index) {
          final service = serviceNames[index];
          final icon = serviceIcons[service] ?? Icons.spa_outlined;
          final description = serviceDescriptions[service] ?? '';

          return Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _openSubtypePicker(context, service),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: colorScheme.primary, size: 28),
                        const Spacer(),
                        Icon(Icons.arrow_forward, size: 18, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      service,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.bookNow ?? 'Book Now',
                        style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
