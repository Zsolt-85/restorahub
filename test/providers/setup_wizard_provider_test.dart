import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/providers/setup_wizard_provider.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/service_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBusinessRepository implements BusinessRepository {
  final Map<String, Business> businesses = {};

  @override
  Future<Business?> getBusinessById(String businessId) async {
    return businesses[businessId];
  }

  @override
  Future<void> updateBusiness(Business business) async {
    businesses[business.id] = business;
  }
}

class FakeServiceRepository implements ServiceRepository {
  final List<Service> services = [];

  @override
  Future<void> createService(Service service) async {
    services.add(service);
  }

  @override
  Future<List<Service>> getServicesForBusiness(String businessId) async {
    return services.where((s) => s.businessId == businessId).toList();
  }

  @override
  Future<List<Service>> getServices({String? businessId}) async {
    return getServicesForBusiness(businessId ?? '');
  }

  @override
  Future<Service?> getServiceById(String id) async {
    try {
      return services.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateService(Service service) async {
    final index = services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      services[index] = service;
    }
  }

  @override
  Future<void> deleteService(String id) async {
    services.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Service>> getServicesForProfessional(String professionalId) async {
    return services.where((s) => s.assignedProfessionalIds.contains(professionalId)).toList();
  }

  @override
  Stream<List<Service>> watchServices({String? businessId}) {
    return Stream.value(services.where((s) => s.businessId == (businessId ?? '')).toList());
  }
}

class FakeUserRepository implements UserRepository {
  final Map<String, User> users = {};

  @override
  Future<User?> getUserById(String id) async => users[id];

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    return users.values.any((u) => u.email == email && u.id != excludeUserId);
  }

  @override
  Future<int> insertUser(User user) async {
    users[user.id!] = user;
    return 1;
  }

  @override
  Future<int> updateUser(User user) async {
    users[user.id!] = user;
    return 1;
  }

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsByCategory(String category) async {
    return users.values.where((u) => u.role == 'professional' && u.category == category).toList();
  }

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    return getProfessionalsByCategory(specialty);
  }

  @override
  Future<List<User>> getProfessionals({String? businessId}) async {
    return users.values
        .where((u) => u.role == 'professional')
        .where((u) => businessId == null || u.businessId == businessId)
        .toList();
  }

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) {
    return Stream.value(
      users.values
          .where((u) => u.role == 'professional')
          .where((u) => businessId == null || u.businessId == businessId)
          .toList(),
    );
  }

  @override
  Future<List<User>> getCustomers() async {
    return users.values.where((u) => u.role == 'customer').toList();
  }
}

void main() {
  group('SetupWizardProvider', () {
    late FakeBusinessRepository businessRepository;
    late FakeServiceRepository serviceRepository;
    late FakeUserRepository userRepository;
    late SetupWizardProvider provider;

    setUp(() {
      businessRepository = FakeBusinessRepository();
      serviceRepository = FakeServiceRepository();
      userRepository = FakeUserRepository();

      final business = Business(
        id: 'biz_1',
        name: 'Test Business',
        status: BusinessStatus.trial,
        settings: BusinessSettings(),
      );
      businessRepository.businesses[business.id] = business;

      provider = SetupWizardProvider(
        businessRepository: businessRepository,
        serviceRepository: serviceRepository,
        userRepository: userRepository,
      );
    });

    test('starts on businessInfo step', () {
      expect(provider.currentStep, WizardStep.businessInfo);
      expect(provider.currentStepIndex, 0);
      expect(provider.totalSteps, 9);
    });

    test('nextStep advances through steps', () {
      provider.nextStep();
      expect(provider.currentStep, WizardStep.brand);
      expect(provider.currentStepIndex, 1);

      provider.nextStep();
      expect(provider.currentStep, WizardStep.businessType);
      expect(provider.currentStepIndex, 2);
    });

    test('previousStep goes back', () {
      provider.nextStep();
      expect(provider.currentStepIndex, 1);

      provider.previousStep();
      expect(provider.currentStep, WizardStep.businessInfo);
      expect(provider.currentStepIndex, 0);
    });

    test('does not go before first step', () {
      provider.previousStep();
      expect(provider.currentStepIndex, 0);
    });

    test('does not go past last step', () {
      for (int i = 0; i < 8; i++) {
        provider.nextStep();
      }
      expect(provider.currentStepIndex, 8);

      provider.nextStep();
      expect(provider.currentStepIndex, 8);
    });

    test('goToStep navigates forward', () {
      provider.goToStep(WizardStep.brand);
      expect(provider.currentStep, WizardStep.brand);
    });

    test('goToStep does not skip more than one step', () {
      provider.goToStep(WizardStep.services);
      expect(provider.currentStepIndex, 0);
    });

    test('updateState updates wizard state', () {
      provider.updateState(
        provider.state.copyWith(businessName: 'New Business'),
      );
      expect(provider.state.businessName, 'New Business');
    });

    test('saveProgress persists wizard state to business settings', () async {
      provider.updateState(
        provider.state.copyWith(
          businessName: 'Updated Business',
          businessEmail: 'test@example.com',
          primaryColor: '#FF5733',
        ),
      );

      final error = await provider.saveProgress('biz_1');
      expect(error, isNull);

      final business = businessRepository.businesses['biz_1']!;
      expect(business.name, 'Updated Business');
      expect(business.email, 'test@example.com');
      expect(business.branding?.primaryColor, '#FF5733');
    });

    test('completeSetup activates business and persists data', () async {
      provider.updateState(
        provider.state.copyWith(
          businessName: 'Launch Business',
          cancellationWindowHours: 24,
          bufferTimeMinutes: 15,
        ),
      );

      final error = await provider.completeSetup('biz_1');
      expect(error, isNull);

      final business = businessRepository.businesses['biz_1']!;
      expect(business.status, BusinessStatus.active);
      expect(business.settings?.cancellationWindowHours, 24);
      expect(business.settings?.bufferTimeMinutes, 15);
      expect(business.settings?.onboardingProgress, isNull);
    });

    test('loadProgress restores wizard state from business settings', () async {
      final business = Business(
        id: 'biz_1',
        name: 'Test Business',
        status: BusinessStatus.trial,
        settings: BusinessSettings(
          onboardingProgress: {
            'currentStep': 3,
            'state': {
              'businessName': 'Restored Business',
              'businessEmail': 'restored@example.com',
              'businessType': 'wellness',
              'primaryColor': '#123456',
            },
          },
        ),
      );
      businessRepository.businesses[business.id] = business;

      await provider.loadProgress('biz_1');

      expect(provider.currentStepIndex, 3);
      expect(provider.state.businessName, 'Restored Business');
      expect(provider.state.businessEmail, 'restored@example.com');
      expect(provider.state.businessType, BusinessType.wellness);
      expect(provider.state.primaryColor, '#123456');
    });

    test('reset returns to initial state', () {
      provider.nextStep();
      provider.updateState(provider.state.copyWith(businessName: 'Something'));

      provider.reset();

      expect(provider.currentStep, WizardStep.businessInfo);
      expect(provider.state.businessName, '');
    });

    test('isFirstStep and isLastStep reflect current position', () {
      expect(provider.isFirstStep, isTrue);
      expect(provider.isLastStep, isFalse);

      for (int i = 0; i < 8; i++) {
        provider.nextStep();
      }
      expect(provider.isFirstStep, isFalse);
      expect(provider.isLastStep, isTrue);
    });

    test('saveProgress returns error for missing business', () async {
      final error = await provider.saveProgress('missing');
      expect(error, 'Business not found');
    });
  });

  group('WizardStep', () {
    test('has 9 steps', () {
      expect(WizardStep.values.length, 9);
    });

    test('each step has title and subtitle', () {
      for (final step in WizardStep.values) {
        expect(step.title, isNotNull);
        expect(step.title, isNotEmpty);
        expect(step.subtitle, isNotNull);
        expect(step.subtitle, isNotEmpty);
      }
    });
  });

  group('WizardState', () {
    test('copyWith preserves unchanged fields', () {
      final original = WizardState(
        businessName: 'Test',
        businessEmail: 'test@example.com',
        primaryColor: '#FF5733',
      );

      final updated = original.copyWith(businessName: 'Updated');

      expect(updated.businessName, 'Updated');
      expect(updated.businessEmail, 'test@example.com');
      expect(updated.primaryColor, '#FF5733');
    });
  });
}
