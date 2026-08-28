import 'dart:async';

import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/business.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../repositories/business_repository.dart';
import '../repositories/firestore_business_repository.dart';
import '../repositories/firestore_service_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

enum WizardStep {
  businessInfo,
  brand,
  businessType,
  services,
  staff,
  openingHours,
  bookingRules,
  preview,
  launch,
}

extension WizardStepExtension on WizardStep {
  String get title {
    switch (this) {
      case WizardStep.businessInfo:
        return 'Business Information';
      case WizardStep.brand:
        return 'Brand';
      case WizardStep.businessType:
        return 'Business Type';
      case WizardStep.services:
        return 'Services';
      case WizardStep.staff:
        return 'Staff';
      case WizardStep.openingHours:
        return 'Opening Hours';
      case WizardStep.bookingRules:
        return 'Booking Rules';
      case WizardStep.preview:
        return 'Preview';
      case WizardStep.launch:
        return 'Launch';
    }
  }

  String get subtitle {
    switch (this) {
      case WizardStep.businessInfo:
        return 'Tell us about your business';
      case WizardStep.brand:
        return 'Customize your appearance';
      case WizardStep.businessType:
        return 'Select your industry';
      case WizardStep.services:
        return 'Set up your service catalog';
      case WizardStep.staff:
        return 'Add your team members';
      case WizardStep.openingHours:
        return 'Configure your schedule';
      case WizardStep.bookingRules:
        return 'Set booking policies';
      case WizardStep.preview:
        return 'Review your setup';
      case WizardStep.launch:
        return 'Ready to go live';
    }
  }
}

class WizardState {
  final String businessName;
  final String? businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final String? customerFacingName;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final BusinessType? businessType;
  final List<Service> services;
  final List<User> staff;
  final Map<String, dynamic> openingHours;
  final int? cancellationWindowHours;
  final int? bufferTimeMinutes;

  const WizardState({
    this.businessName = '',
    this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    this.customerFacingName,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.businessType,
    this.services = const [],
    this.staff = const [],
    this.openingHours = const {},
    this.cancellationWindowHours,
    this.bufferTimeMinutes,
  });

  WizardState copyWith({
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? customerFacingName,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    BusinessType? businessType,
    List<Service>? services,
    List<User>? staff,
    Map<String, dynamic>? openingHours,
    int? cancellationWindowHours,
    int? bufferTimeMinutes,
  }) {
    return WizardState(
      businessName: businessName ?? this.businessName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      customerFacingName: customerFacingName ?? this.customerFacingName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      businessType: businessType ?? this.businessType,
      services: services ?? this.services,
      staff: staff ?? this.staff,
      openingHours: openingHours ?? this.openingHours,
      cancellationWindowHours: cancellationWindowHours ?? this.cancellationWindowHours,
      bufferTimeMinutes: bufferTimeMinutes ?? this.bufferTimeMinutes,
    );
  }
}

class SetupWizardProvider extends ChangeNotifier {
  SetupWizardProvider({
    BusinessRepository? businessRepository,
    ServiceRepository? serviceRepository,
    UserRepository? userRepository,
  })  : _businessRepository = businessRepository ?? FirestoreBusinessRepository.instance,
        _serviceRepository = serviceRepository ?? FirestoreServiceRepository.instance,
        _userRepository = userRepository ?? FirestoreUserRepository.instance;

  final BusinessRepository _businessRepository;
  final ServiceRepository _serviceRepository;
  final UserRepository _userRepository;

  WizardState _state = const WizardState();
  WizardStep _currentStep = WizardStep.businessInfo;
  bool _isLoading = false;
  String? _error;

  WizardState get state => _state;
  WizardStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentStepIndex => _currentStep.index;
  int get totalSteps => WizardStep.values.length;

  bool get isFirstStep => _currentStep == WizardStep.businessInfo;
  bool get isLastStep => _currentStep == WizardStep.launch;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading([String? error]) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  void updateState(WizardState state) {
    _state = state;
    notifyListeners();
  }

  void nextStep() {
    if (isLastStep) return;
    _currentStep = WizardStep.values[_currentStep.index + 1];
    _error = null;
    notifyListeners();
  }

  void previousStep() {
    if (isFirstStep) return;
    _currentStep = WizardStep.values[_currentStep.index - 1];
    _error = null;
    notifyListeners();
  }

  void goToStep(WizardStep step) {
    final targetIndex = step.index;
    if (targetIndex < 0 || targetIndex >= WizardStep.values.length) return;
    if (targetIndex > _currentStep.index + 1) return;
    _currentStep = step;
    _error = null;
    notifyListeners();
  }

  Future<String?> saveProgress(String businessId) async {
    _beginLoading();
    try {
      final business = await _businessRepository.getBusinessById(businessId);
      if (business == null) {
        _endLoading('Business not found');
        return 'Business not found';
      }

      final updatedSettings = (business.settings ?? BusinessSettings()).copyWith(
        onboardingProgress: {
          'currentStep': _currentStep.index,
          'state': {
            'businessName': _state.businessName,
            'businessEmail': _state.businessEmail,
            'businessPhone': _state.businessPhone,
            'businessAddress': _state.businessAddress,
            'customerFacingName': _state.customerFacingName,
            'logoUrl': _state.logoUrl,
            'primaryColor': _state.primaryColor,
            'secondaryColor': _state.secondaryColor,
            'accentColor': _state.accentColor,
            'businessType': _state.businessType?.name,
            'cancellationWindowHours': _state.cancellationWindowHours,
            'bufferTimeMinutes': _state.bufferTimeMinutes,
            'openingHours': _state.openingHours,
          },
        },
      );

      final updatedBranding = BusinessBranding(
        businessName: _state.customerFacingName ?? _state.businessName,
        logo: _state.logoUrl,
        primaryColor: _state.primaryColor,
        secondaryColor: _state.secondaryColor,
        accentColor: _state.accentColor,
      );

      final updatedBusiness = business.copyWith(
        name: _state.businessName,
        email: _state.businessEmail,
        phone: _state.businessPhone,
        address: _state.businessAddress,
        branding: updatedBranding,
        settings: updatedSettings,
        businessType: _state.businessType ?? business.businessType,
      );

      await _businessRepository.updateBusiness(updatedBusiness);
      _endLoading();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e, stack) {
      AppLogger.error('SetupWizardProvider.saveProgress error: $e\n$stack');
      _endLoading('Failed to save progress');
      return 'Failed to save progress';
    }
  }

  Future<String?> completeSetup(String businessId) async {
    _beginLoading();
    try {
      final business = await _businessRepository.getBusinessById(businessId);
      if (business == null) {
        _endLoading('Business not found');
        return 'Business not found';
      }

      final updatedBusiness = business.copyWith(
        status: BusinessStatus.active,
        branding: (business.branding ?? BusinessBranding()).copyWith(
          businessName: _state.customerFacingName ?? _state.businessName,
          logo: _state.logoUrl ?? business.branding?.logo,
          primaryColor: _state.primaryColor ?? business.branding?.primaryColor,
          secondaryColor: _state.secondaryColor ?? business.branding?.secondaryColor,
          accentColor: _state.accentColor ?? business.branding?.accentColor,
        ),
        settings: (business.settings ?? BusinessSettings()).copyWith(
          cancellationWindowHours: _state.cancellationWindowHours ?? business.settings?.cancellationWindowHours,
          bufferTimeMinutes: _state.bufferTimeMinutes ?? business.settings?.bufferTimeMinutes,
          onboardingProgress: null,
        ),
      );

      await _businessRepository.updateBusiness(updatedBusiness);

      for (final service in _state.services) {
        await _serviceRepository.createService(service);
      }

      for (final staffMember in _state.staff) {
        await _userRepository.updateUser(staffMember);
      }

      _endLoading();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e, stack) {
      AppLogger.error('SetupWizardProvider.completeSetup error: $e\n$stack');
      _endLoading('Failed to complete setup');
      return 'Failed to complete setup';
    }
  }

  Future<void> loadProgress(String businessId) async {
    _beginLoading();
    try {
      final business = await _businessRepository.getBusinessById(businessId);
      if (business == null || business.settings?.onboardingProgress == null) {
        _endLoading();
        return;
      }

      final progress = business.settings!.onboardingProgress!;
      final currentStepIndex = progress['currentStep'] as int? ?? 0;
      _currentStep = WizardStep.values[currentStepIndex.clamp(0, WizardStep.values.length - 1)];

      final stateMap = progress['state'] as Map<String, dynamic>? ?? {};
      _state = WizardState(
        businessName: stateMap['businessName']?.toString() ?? '',
        businessEmail: stateMap['businessEmail']?.toString(),
        businessPhone: stateMap['businessPhone']?.toString(),
        businessAddress: stateMap['businessAddress']?.toString(),
        customerFacingName: stateMap['customerFacingName']?.toString(),
        logoUrl: stateMap['logoUrl']?.toString(),
        primaryColor: stateMap['primaryColor']?.toString(),
        secondaryColor: stateMap['secondaryColor']?.toString(),
        accentColor: stateMap['accentColor']?.toString(),
        businessType: stateMap['businessType'] != null
            ? BusinessType.values.firstWhere(
                (t) => t.name == stateMap['businessType'],
                orElse: () => BusinessType.custom,
              )
            : null,
        cancellationWindowHours: stateMap['cancellationWindowHours'] as int?,
        bufferTimeMinutes: stateMap['bufferTimeMinutes'] as int?,
        openingHours: Map<String, dynamic>.from(stateMap['openingHours'] ?? {}),
      );

      _endLoading();
    } catch (e, stack) {
      AppLogger.error('SetupWizardProvider.loadProgress error: $e\n$stack');
      _endLoading();
    }
  }

  void reset() {
    _state = const WizardState();
    _currentStep = WizardStep.businessInfo;
    _error = null;
    notifyListeners();
  }
}
