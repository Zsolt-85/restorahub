import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../repositories/business_repository.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _primaryColorController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _depositPercentController = TextEditingController();
  final _noShowFeeController = TextEditingController();

  static const _windowOptions = [2, 12, 24, 48];
  int _cancellationWindowHours = 2;
  bool _depositRequired = false;

  bool _busy = true;
  bool _loading = false;
  String? _error;
  Business? _currentBusiness;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _primaryColorController.dispose();
    _logoUrlController.dispose();
    _depositPercentController.dispose();
    _noShowFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final businessProvider =
        Provider.of<BusinessProvider>(context, listen: false);
    Business? business = businessProvider.currentBusiness;

    if (business == null &&
        user.businessId != null &&
        user.businessId!.isNotEmpty) {
      try {
        final repository =
            Provider.of<BusinessRepository>(context, listen: false);
        business = await repository.getBusinessById(user.businessId!);
        if (business != null) {
          businessProvider.setBusiness(business);
        }
      } catch (e, stack) {
        AppLogger.error('BusinessSettingsPage._loadBusiness error: $e\n$stack');
      }
    }

    if (!mounted) return;
    setState(() {
      _currentBusiness = business;
      if (business != null) {
        _nameController.text = business.name;
        _phoneController.text = business.phone ?? '';
        _addressController.text = business.address ?? '';
        _primaryColorController.text = business.primaryColorHex ?? '';
        _logoUrlController.text = business.logoUrl ?? '';
        final settings = business.settings;
        _cancellationWindowHours =
            settings?.cancellationWindowHours ?? 2;
        if (!_windowOptions.contains(_cancellationWindowHours)) {
          _cancellationWindowHours = 2;
        }
        _depositRequired = settings?.depositRequired ?? false;
        _depositPercentController.text =
            settings?.depositPercent?.toString() ?? '';
        _noShowFeeController.text =
            settings?.noShowFeeAmount?.toString() ?? '';
      }
      _busy = false;
    });
  }

  Future<void> _save() async {
    final business = _currentBusiness;
    if (business == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Business name is required');
      return;
    }

    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final primaryColorHex = _primaryColorController.text.trim().isEmpty
        ? null
        : _primaryColorController.text.trim();
    final logoUrl = _logoUrlController.text.trim().isEmpty
        ? null
        : _logoUrlController.text.trim();

    final depositPercent =
        double.tryParse(_depositPercentController.text.trim());
    if (_depositRequired &&
        (depositPercent == null ||
            depositPercent <= 0 ||
            depositPercent > 100)) {
      setState(() => _error =
          'Deposit percent must be a number between 1 and 100');
      return;
    }
    final noShowFee = _noShowFeeController.text.trim().isEmpty
        ? null
        : double.tryParse(_noShowFeeController.text.trim());
    if (noShowFee == null && _noShowFeeController.text.trim().isNotEmpty ||
        (noShowFee != null && noShowFee < 0)) {
      setState(() => _error = 'No-show fee must be zero or more');
      return;
    }

    final settings = (business.settings ?? BusinessSettings()).copyWith(
      cancellationWindowHours: _cancellationWindowHours,
      depositRequired: _depositRequired,
      depositPercent: _depositRequired ? depositPercent : null,
      noShowFeeAmount: noShowFee,
    );
    final updated = business.copyWith(
      name: name,
      phone: phone.isEmpty ? null : phone,
      address: address.isEmpty ? null : address,
      primaryColorHex: primaryColorHex,
      logoUrl: logoUrl,
      settings: settings,
    );

    setState(() {
      _loading = true;
      _error = null;
    });

    final repository = Provider.of<BusinessRepository>(context, listen: false);
    final businessProvider =
        Provider.of<BusinessProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = AppLocalizations.of(context);

    try {
      await repository.updateBusiness(updated);

      Business? refreshed;
      try {
        refreshed = await repository.getBusinessById(business.id);
      } catch (e, stack) {
        AppLogger.error('BusinessSettingsPage refresh error: $e\n$stack');
      }

      if (refreshed != null) {
        businessProvider.setBusiness(refreshed);
      }

      if (!mounted) return;
      setState(() {
        _currentBusiness = refreshed ?? updated;
        _loading = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.businessSavedSuccessfully ??
                'Business settings updated successfully',
          ),
        ),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('BusinessSettingsPage._save error: $e\n$stack');
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getDisplayMessage(e)),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  bool _isAdmin(String role) {
    return role == 'business_admin' || role == 'super_admin';
  }

  Widget _buildPresetSwatches() {
    const presets = [
      Color(0xFF008080),
      Color(0xFF3A86EF),
      Color(0xFFBE123C),
      Color(0xFF10B981),
      Color(0xFF6366F1),
    ];
    final current = _primaryColorController.text.trim();
    String? normalizedCurrent;
    if (current.isNotEmpty) {
      normalizedCurrent =
          current.startsWith('#') ? current.substring(1) : current;
      normalizedCurrent = normalizedCurrent.toUpperCase();
    }

    return Wrap(
      spacing: 12,
      children: presets.map((color) {
        final hex =
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        final selected =
            normalizedCurrent == hex || normalizedCurrent == hex.substring(1);
        return Semantics(
          button: true,
          label: 'Color $hex',
          child: GestureDetector(
            onTap: () {
              _primaryColorController.text = hex;
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_isAdmin(user.role)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.businessSettings ??
                'Business Settings',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)?.businessAccessDenied ??
                  'You do not have permission to access business settings.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.businessSettings ?? 'Business Settings',
        ),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _currentBusiness != null
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: _loading
                  ? const SizedBox.shrink()
                  : Text(AppLocalizations.of(context)?.save ?? 'Save'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final business = _currentBusiness;

    if (business == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)?.noBusinessConfigured ??
                'No business information is configured.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CircleAvatar(
            radius: 32,
            child: Text(
              business.name.isNotEmpty
                  ? business.name.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            business.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)?.businessName ?? 'Business Name',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText:
                  AppLocalizations.of(context)?.businessName ?? 'Business Name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText:
                  AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.address ?? 'Address',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.address ?? 'Address',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            keyboardType: TextInputType.streetAddress,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          Text(
            'Branding & Appearance',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Primary Color',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _buildPresetSwatches(),
          const SizedBox(height: 12),
          TextField(
            controller: _primaryColorController,
            decoration: const InputDecoration(
              labelText: 'Primary Color Hex',
              hintText: '#3A86EF or 3A86EF',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.palette_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(
            'Logo URL',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _logoUrlController,
            decoration: const InputDecoration(
              labelText: 'Logo URL',
              hintText: 'https://example.com/logo.png',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image_outlined),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          if (_logoUrlController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Image.network(
                _logoUrlController.text.trim(),
                height: 80,
                width: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Booking Policy',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _cancellationWindowHours,
            decoration: const InputDecoration(
              labelText: 'Cancellation cutoff',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            items: _windowOptions
                .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text('$h hours before start'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _cancellationWindowHours = v);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require deposit'),
            subtitle: const Text(
                'Customers see the deposit due at booking time'),
            value: _depositRequired,
            onChanged: (v) => setState(() => _depositRequired = v),
          ),
          if (_depositRequired) ...[
            TextField(
              controller: _depositPercentController,
              decoration: const InputDecoration(
                labelText: 'Deposit percent of price',
                suffixText: '%',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _noShowFeeController,
            decoration: const InputDecoration(
              labelText: 'No-show fee (optional)',
              prefixText: '€ ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_off_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
