import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../constants/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/service.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../repositories/business_repository.dart';
import '../repositories/service_repository.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  @override
  void initState() {
    super.initState();
    _ensureBusinessLoaded();
  }

  Future<void> _ensureBusinessLoaded() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (businessProvider.currentBusiness != null) return;

    final userBusinessId = user.businessId;
    if (userBusinessId == null || userBusinessId.isEmpty) return;

    try {
      final repository = Provider.of<BusinessRepository>(context, listen: false);
      final business = await repository.getBusinessById(userBusinessId);
      if (business != null && mounted) {
        businessProvider.setBusiness(business);
      }
    } catch (e, stack) {
      AppLogger.error('ServicesPage._ensureBusinessLoaded error: $e\n$stack');
    }
  }

  bool _isAdmin(String role) {
    return role == 'business_admin' || role == 'super_admin';
  }

  Future<void> _createService(BuildContext context) async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final repository = Provider.of<ServiceRepository>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = AppLocalizations.of(context);

    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.addService ?? 'Add Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n?.name ?? 'Name',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ErrorHandler.showErrorSnackBar(context, 'Service name is required');
                return;
              }
              Navigator.pop(context);
              try {
                await repository.createService(
                  Service(
                    name: name,
                    description: '',
                    businessId: businessId,
                  ),
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n?.save ?? 'Service created'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getDisplayMessage(e)),
                    backgroundColor: errorColor,
                  ),
                );
              }
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final businessProvider = Provider.of<BusinessProvider>(context);
    final businessId = businessProvider.currentBusiness?.id;
    final isAdmin = auth.currentUser != null && _isAdmin(auth.currentUser!.role);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.services ?? 'Services')),
      body: _buildCategoryGrid(context),
      floatingActionButton:
          isAdmin && (businessId != null && businessId.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: () => _createService(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                )
              : null,
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = serviceDescriptions.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, index) {
        final category = categories[index];
        final icon = serviceIcons[category] ?? Icons.spa_outlined;
        final description = serviceDescriptions[category] ?? '';

        return Card(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              Routes.booking,
              arguments: {'category': category},
            ),
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
                    category,
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
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
