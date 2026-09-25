import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/setup_wizard_page.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/providers/setup_wizard_provider.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/service_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBusinessRepository implements BusinessRepository {
  @override
  Future<Business?> getBusinessById(String businessId) async => null;

  @override
  Future<void> updateBusiness(Business business) async {}
}

class FakeServiceRepository implements ServiceRepository {
  @override
  Future<List<Service>> getServices({String? businessId}) async => [];

  @override
  Stream<List<Service>> watchServices({String? businessId}) =>
      Stream.value([]);

  @override
  Future<void> createService(Service service) async {}

  @override
  Future<void> updateService(Service service) async {}

  @override
  Future<void> deleteService(String id) async {}
}

class FakeUserRepository implements UserRepository {
  @override
  Future<User?> getUserById(String id) async => null;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async =>
      false;

  @override
  Future<int> insertUser(User user) async => 1;

  @override
  Future<int> updateUser(User user) async => 1;

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsByCategory(String category,
          {String? businessId}) async =>
      [];

  @override
  Future<List<User>> getProfessionals({String? businessId}) async => [];

  @override
  Future<List<User>> getProfessionalsByBusiness(String businessId) async => [];

  @override
  Future<List<User>> getCustomers({String? businessId}) async => [];
}

void main() {
  group('SetupWizardPage business guard', () {
    testWidgets('explains instead of blank screen without a business',
        (tester) async {
      final auth = AuthProvider(userRepository: FakeUserRepository());
      auth.currentUser = User(
        id: 'admin-1',
        name: 'Admin',
        email: 'admin@test.com',
        phone: '555',
        role: 'business_admin',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<SetupWizardProvider>(
              create: (_) => SetupWizardProvider(
                businessRepository: FakeBusinessRepository(),
                serviceRepository: FakeServiceRepository(),
                userRepository: FakeUserRepository(),
              ),
            ),
          ],
          child: const MaterialApp(home: SetupWizardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No business is assigned'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });
  });
}
