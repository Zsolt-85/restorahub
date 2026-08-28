import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../models/business.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/setup_wizard_provider.dart';
import '../repositories/business_repository.dart';

class SetupWizardPage extends StatefulWidget {
  const SetupWizardPage({super.key});

  @override
  State<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends State<SetupWizardPage> {
  int _previousStepIndex = 0;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _customerFacingController;
  late final TextEditingController _logoController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _secondaryColorController;
  late final TextEditingController _accentColorController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _customerFacingController = TextEditingController();
    _logoController = TextEditingController();
    _primaryColorController = TextEditingController();
    _secondaryColorController = TextEditingController();
    _accentColorController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _customerFacingController.dispose();
    _logoController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _accentColorController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user?.businessId == null) return;

    final provider = Provider.of<SetupWizardProvider>(context, listen: false);
    await provider.loadProgress(user!.businessId!);

    if (!mounted) return;
    final state = provider.state;
    _nameController.text = state.businessName;
    _emailController.text = state.businessEmail ?? '';
    _phoneController.text = state.businessPhone ?? '';
    _addressController.text = state.businessAddress ?? '';
    _customerFacingController.text = state.customerFacingName ?? '';
    _logoController.text = state.logoUrl ?? '';
    _primaryColorController.text = state.primaryColor ?? '';
    _secondaryColorController.text = state.secondaryColor ?? '';
    _accentColorController.text = state.accentColor ?? '';
  }

  void _syncControllersToState(SetupWizardProvider wizard) {
    final state = wizard.state;
    _nameController.text = state.businessName;
    _emailController.text = state.businessEmail ?? '';
    _phoneController.text = state.businessPhone ?? '';
    _addressController.text = state.businessAddress ?? '';
    _customerFacingController.text = state.customerFacingName ?? '';
    _logoController.text = state.logoUrl ?? '';
    _primaryColorController.text = state.primaryColor ?? '';
    _secondaryColorController.text = state.secondaryColor ?? '';
    _accentColorController.text = state.accentColor ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null || user.businessId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final businessId = user.businessId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Wizard'),
        actions: [
          Consumer<SetupWizardProvider>(
            builder: (context, wizard, _) {
              if (wizard.currentStep == WizardStep.launch) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: wizard.isLoading
                    ? null
                    : () async {
                        final error = await wizard.saveProgress(businessId);
                        if (!mounted) return;
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Progress saved')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                child: const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: Consumer<SetupWizardProvider>(
        builder: (context, wizard, _) {
          if (wizard.isLoading && wizard.currentStepIndex == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_previousStepIndex != wizard.currentStepIndex) {
            _previousStepIndex = wizard.currentStepIndex;
            _syncControllersToState(wizard);
          }

          return Stepper(
            type: StepperType.vertical,
            currentStep: wizard.currentStepIndex,
            onStepContinue: _onStepContinue,
            onStepCancel: wizard.isFirstStep ? null : wizard.previousStep,
            onStepTapped: (index) => wizard.goToStep(WizardStep.values[index]),
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (!wizard.isFirstStep)
                      ElevatedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(
                        wizard.isLastStep ? 'Finish' : 'Next',
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              _buildBusinessInfoStep(wizard),
              _buildBrandStep(wizard),
              _buildBusinessTypeStep(wizard),
              _buildServicesStep(wizard),
              _buildStaffStep(wizard),
              _buildOpeningHoursStep(wizard),
              _buildBookingRulesStep(wizard),
              _buildPreviewStep(wizard),
              _buildLaunchStep(wizard, businessId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onStepContinue() async {
    final wizard = Provider.of<SetupWizardProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessId = auth.currentUser?.businessId;
    if (businessId == null) return;

    if (wizard.isLastStep) {
      final error = await wizard.completeSetup(businessId);
      if (!mounted) return;
      if (error == null) {
        final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
        final repository = Provider.of<BusinessRepository>(context, listen: false);
        final refreshed = await repository.getBusinessById(businessId);
        if (refreshed != null) {
          businessProvider.setBusiness(refreshed);
        }
        Navigator.pushNamedAndRemoveUntil(context, Routes.customerHome, (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    wizard.nextStep();
  }

  Step _buildBusinessInfoStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.businessInfo.title),
      subtitle: Text(WizardStep.businessInfo.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.businessInfo.index,
      state: _stepState(wizard, WizardStep.businessInfo),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business_outlined),
            ),
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(businessName: value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(businessEmail: value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(businessPhone: value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            maxLines: 3,
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(businessAddress: value),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildBrandStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.brand.title),
      subtitle: Text(WizardStep.brand.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.brand.index,
      state: _stepState(wizard, WizardStep.brand),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _customerFacingController,
            decoration: const InputDecoration(
              labelText: 'Customer-Facing Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(customerFacingName: value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _logoController,
            decoration: const InputDecoration(
              labelText: 'Logo URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image_outlined),
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) => wizard.updateState(
              wizard.state.copyWith(logoUrl: value),
            ),
          ),
          const SizedBox(height: 20),
          _ColorField(
            label: 'Primary Color',
            controller: _primaryColorController,
            palette: _kPrimaryPalette,
            onColorSelected: (hex) {
              _primaryColorController.text = hex;
              wizard.updateState(wizard.state.copyWith(primaryColor: hex));
            },
          ),
          const SizedBox(height: 16),
          _ColorField(
            label: 'Secondary Color',
            controller: _secondaryColorController,
            palette: _kSecondaryPalette,
            onColorSelected: (hex) {
              _secondaryColorController.text = hex;
              wizard.updateState(wizard.state.copyWith(secondaryColor: hex));
            },
          ),
          const SizedBox(height: 16),
          _ColorField(
            label: 'Accent Color',
            controller: _accentColorController,
            palette: _kAccentPalette,
            onColorSelected: (hex) {
              _accentColorController.text = hex;
              wizard.updateState(wizard.state.copyWith(accentColor: hex));
            },
          ),
        ],
      ),
    );
  }

  Step _buildBusinessTypeStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.businessType.title),
      subtitle: Text(WizardStep.businessType.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.businessType.index,
      state: _stepState(wizard, WizardStep.businessType),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: BusinessType.values.map((type) {
          final isSelected = wizard.state.businessType == type;
          return Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: RadioListTile<BusinessType>(
              title: Text(_businessTypeLabel(type)),
              subtitle: Text(_businessTypeDescription(type)),
              value: type,
              groupValue: wizard.state.businessType,
              onChanged: (value) {
                if (value != null) {
                  wizard.updateState(wizard.state.copyWith(businessType: value));
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Step _buildServicesStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.services.title),
      subtitle: Text(WizardStep.services.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.services.index,
      state: _stepState(wizard, WizardStep.services),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Default services for your business type will be created during launch.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (wizard.state.services.isNotEmpty)
            ...wizard.state.services.map((service) {
              return ListTile(
                leading: const Icon(Icons.check_circle_outlined),
                title: Text(service.name),
                trailing: Text(
                  '${service.durationMinutes ?? 0} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
        ],
      ),
    );
  }

  Step _buildStaffStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.staff.title),
      subtitle: Text(WizardStep.staff.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.staff.index,
      state: _stepState(wizard, WizardStep.staff),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You can invite staff members after setup from the Team Management page.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Step _buildOpeningHoursStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.openingHours.title),
      subtitle: Text(WizardStep.openingHours.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.openingHours.index,
      state: _stepState(wizard, WizardStep.openingHours),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Default opening hours will be applied. You can customize them later in Business Settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Step _buildBookingRulesStep(SetupWizardProvider wizard) {
    return Step(
      title: Text(WizardStep.bookingRules.title),
      subtitle: Text(WizardStep.bookingRules.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.bookingRules.index,
      state: _stepState(wizard, WizardStep.bookingRules),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cancellation Window (hours)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: wizard.state.cancellationWindowHours,
            items: const [
              DropdownMenuItem(value: 2, child: Text('2 hours')),
              DropdownMenuItem(value: 12, child: Text('12 hours')),
              DropdownMenuItem(value: 24, child: Text('24 hours')),
              DropdownMenuItem(value: 48, child: Text('48 hours')),
            ],
            onChanged: (value) {
              if (value != null) {
                wizard.updateState(
                  wizard.state.copyWith(cancellationWindowHours: value),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Buffer Time Between Appointments',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: wizard.state.bufferTimeMinutes,
            items: const [
              DropdownMenuItem(value: 0, child: Text('None')),
              DropdownMenuItem(value: 10, child: Text('10 minutes')),
              DropdownMenuItem(value: 15, child: Text('15 minutes')),
              DropdownMenuItem(value: 30, child: Text('30 minutes')),
            ],
            onChanged: (value) {
              if (value != null) {
                wizard.updateState(
                  wizard.state.copyWith(bufferTimeMinutes: value),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Step _buildPreviewStep(SetupWizardProvider wizard) {
    final state = wizard.state;
    return Step(
      title: Text(WizardStep.preview.title),
      subtitle: Text(WizardStep.preview.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.preview.index,
      state: _stepState(wizard, WizardStep.preview),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewRow(
            label: 'Business Name',
            value: state.businessName,
          ),
          _PreviewRow(
            label: 'Email',
            value: state.businessEmail,
          ),
          _PreviewRow(
            label: 'Phone',
            value: state.businessPhone,
          ),
          _PreviewRow(
            label: 'Address',
            value: state.businessAddress,
          ),
          _PreviewRow(
            label: 'Customer-Facing Name',
            value: state.customerFacingName,
          ),
          _PreviewRow(
            label: 'Business Type',
            value: state.businessType != null
                ? _businessTypeLabel(state.businessType!)
                : null,
          ),
          _PreviewColorRow(
            label: 'Primary Color',
            hex: state.primaryColor,
          ),
          _PreviewColorRow(
            label: 'Secondary Color',
            hex: state.secondaryColor,
          ),
          _PreviewColorRow(
            label: 'Accent Color',
            hex: state.accentColor,
          ),
          _PreviewRow(
            label: 'Cancellation Window',
            value: state.cancellationWindowHours != null
                ? '${state.cancellationWindowHours} hours'
                : null,
          ),
          _PreviewRow(
            label: 'Buffer Time',
            value: state.bufferTimeMinutes != null
                ? '${state.bufferTimeMinutes} minutes'
                : null,
          ),
        ],
      ),
    );
  }

  Step _buildLaunchStep(SetupWizardProvider wizard, String businessId) {
    return Step(
      title: Text(WizardStep.launch.title),
      subtitle: Text(WizardStep.launch.subtitle),
      isActive: wizard.currentStepIndex >= WizardStep.launch.index,
      state: _stepState(wizard, WizardStep.launch),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Your business is ready to launch!',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'All settings have been configured. Click Finish to activate your account.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  StepState _stepState(SetupWizardProvider wizard, WizardStep step) {
    if (wizard.currentStepIndex > step.index) {
      return StepState.complete;
    }
    if (wizard.currentStepIndex == step.index) {
      return StepState.editing;
    }
    return StepState.indexed;
  }

  String _businessTypeLabel(BusinessType type) {
    switch (type) {
      case BusinessType.wellness:
        return 'Wellness';
      case BusinessType.beauty:
        return 'Beauty';
      case BusinessType.fitness:
        return 'Fitness';
      case BusinessType.automotive:
        return 'Automotive';
      case BusinessType.healthcare:
        return 'Healthcare';
      case BusinessType.custom:
        return 'Custom';
    }
  }

  String _businessTypeDescription(BusinessType type) {
    switch (type) {
      case BusinessType.wellness:
        return 'Massage, spa, and wellness services';
      case BusinessType.beauty:
        return 'Hair, nails, and beauty services';
      case BusinessType.fitness:
        return 'Personal training and classes';
      case BusinessType.automotive:
        return 'Vehicle service and repair';
      case BusinessType.healthcare:
        return 'Medical and health services';
      case BusinessType.custom:
        return 'Define your own service types';
    }
  }
}

const _kPrimaryPalette = <Color>[
  Color(0xFF3A86EF),
  Color(0xFF2563EB),
  Color(0xFF1D4ED8),
  Color(0xFF0EA5E9),
  Color(0xFF06B6D4),
  Color(0xFF14B8A6),
  Color(0xFF10B981),
  Color(0xFF22C55E),
  Color(0xFF84CC16),
  Color(0xFFEAB308),
  Color(0xFFF59E0B),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFF43F5E),
  Color(0xFFEC4899),
  Color(0xFFD946EF),
  Color(0xFFA855F7),
  Color(0xFF8B5CF6),
  Color(0xFF6366F1),
  Color(0xFF64748B),
  Color(0xFF475569),
  Color(0xFF1E293B),
];

const _kSecondaryPalette = <Color>[
  Color(0xFF60A5FA),
  Color(0xFF34D399),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
  Color(0xFFFBBF24),
  Color(0xFFFB923C),
  Color(0xFF4ADE80),
  Color(0xFF2DD4BF),
  Color(0xFFE879F9),
  Color(0xFF818CF8),
  Color(0xFF94A3B8),
  Color(0xFFCBD5E1),
];

const _kAccentPalette = <Color>[
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF6F91),
  Color(0xFF845EC2),
  Color(0xFF00C9A7),
  Color(0xFFFFC75C),
  Color(0xFF0088FF),
  Color(0xFFFF8C42),
  Color(0xFF2ECC71),
];

class _ColorField extends StatelessWidget {
  const _ColorField({
    required this.label,
    required this.controller,
    required this.palette,
    required this.onColorSelected,
  });

  final String label;
  final TextEditingController controller;
  final List<Color> palette;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final selectedHex = controller.text.trim().toLowerCase();
    final selectedColor = _hexToColor(selectedHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: palette.map((color) {
            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            final isSelected = selectedHex == hex.toLowerCase() || selectedColor == color;
            return GestureDetector(
              onTap: () => onColorSelected(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: _contrastColor(color), size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$label (hex)',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette_outlined),
            suffixIcon: selectedColor != null
                ? Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  )
                : null,
          ),
          onChanged: (value) => onColorSelected(value),
        ),
      ],
    );
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewColorRow extends StatelessWidget {
  const _PreviewColorRow({
    required this.label,
    required this.hex,
  });

  final String label;
  final String? hex;

  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;
    final buffer = StringBuffer();
    final cleaned = value.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      buffer.write('FF');
    }
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(hex);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hex ?? '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: hex != null ? FontWeight.w500 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
