import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/helpers/route_guard_helper.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/repositories/user_repository.dart';

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
  Future<List<User>> getCustomers() async =>
      users.values.where((u) => u.role == 'customer').toList();
}

AuthProvider _authProviderWithUser(User? user) {
  final provider = AuthProvider(userRepository: FakeUserRepository());
  provider.currentUser = user;
  return provider;
}

void main() {
  group('RouteGuardHelper', () {
    test('unauthenticated user on protected route redirects to login', () {
      final auth = _authProviderWithUser(null);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        isAuthenticatedOverride: false,
        isProfileCompleteOverride: false,
      );
      expect(redirect, Routes.login);
    });

    test('unauthenticated user on login sees no redirect', () {
      final auth = _authProviderWithUser(null);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        isAuthenticatedOverride: false,
        isProfileCompleteOverride: false,
      );
      expect(redirect, isNull);
    });

    test('authenticated customer on login redirects to user home', () {
      final user = User(
        id: '1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555-0100',
        role: 'customer',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.customerHome);
    });

    test('authenticated professional on login redirects to professional home', () {
      final user = User(
        id: '2',
        name: 'Professional',
        email: 'prof@test.com',
        phone: '555-0200',
        role: 'professional',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.professionalHome);
    });

    test('customer on professional home redirects to customer home', () {
      final user = User(
        id: '1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555-0100',
        role: 'customer',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.professionalHome,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.customerHome);
    });

    test('professional on customer home redirects to professional home', () {
      final user = User(
        id: '2',
        name: 'Professional',
        email: 'prof@test.com',
        phone: '555-0200',
        role: 'professional',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.professionalHome);
    });

    test('customer on customer home sees no redirect', () {
      final user = User(
        id: '1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555-0100',
        role: 'customer',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, isNull);
    });

    test('professional on professional home sees no redirect', () {
      final user = User(
        id: '2',
        name: 'Professional',
        email: 'prof@test.com',
        phone: '555-0200',
        role: 'professional',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.professionalHome,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, isNull);
    });

    test('profile incomplete with authenticated session redirects to complete-profile',
        () {
      final auth = _authProviderWithUser(null);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: false,
      );
      expect(redirect, Routes.completeProfile);
    });

    test('authenticated user on register redirects to home dashboard', () {
      final user = User(
        id: '1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555-0100',
        role: 'customer',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.register,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.customerHome);
    });

    test('authenticated super_admin on login redirects to super admin dashboard', () {
      final user = User(
        id: '3',
        name: 'Super Admin',
        email: 'admin@test.com',
        phone: '555-0300',
        role: 'super_admin',
      );
      final auth = _authProviderWithUser(user);
      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.superAdminDashboard);
    });

    test('business_admin with trial business on login redirects to setup wizard', () {
      final user = User(
        id: '4',
        name: 'Biz Admin',
        email: 'biz@test.com',
        phone: '555-0400',
        role: 'business_admin',
        businessId: 'biz_1',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(id: 'biz_1', name: 'Test', status: BusinessStatus.trial));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test('business_admin with active business on login redirects to admin dashboard', () {
      final user = User(
        id: '5',
        name: 'Biz Admin',
        email: 'biz2@test.com',
        phone: '555-0500',
        role: 'business_admin',
        businessId: 'biz_2',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(id: 'biz_2', name: 'Active Biz', status: BusinessStatus.active));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.adminDashboard);
    });

    test('business_admin with null business on login redirects to setup wizard', () {
      final user = User(
        id: '6',
        name: 'Biz Admin',
        email: 'biz3@test.com',
        phone: '555-0600',
        role: 'business_admin',
        businessId: 'biz_3',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider();

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test('business_admin on customer home redirects to setup wizard when trial', () {
      final user = User(
        id: '7',
        name: 'Biz Admin',
        email: 'biz4@test.com',
        phone: '555-0700',
        role: 'business_admin',
        businessId: 'biz_4',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(id: 'biz_4', name: 'Trial Biz', status: BusinessStatus.trial));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test('business_admin on customer home redirects to admin dashboard when active', () {
      final user = User(
        id: '8',
        name: 'Biz Admin',
        email: 'biz5@test.com',
        phone: '555-0800',
        role: 'business_admin',
        businessId: 'biz_5',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(id: 'biz_5', name: 'Active Biz', status: BusinessStatus.active));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.adminDashboard);
    });
  });
}
