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
  Future<List<User>> getProfessionalsByCategory(String category,
      {String? businessId}) async {
    return users.values
        .where((u) => u.isStaff && u.category == category)
        .where((u) => businessId == null || u.businessId == businessId)
        .toList();
  }

  @override
  Future<List<User>> getProfessionals({String? businessId}) async {
    return users.values
        .where((u) => u.isStaff)
        .where((u) => businessId == null || u.businessId == businessId)
        .toList();
  }

  @override
  Future<List<User>> getProfessionalsByBusiness(String businessId) async {
    return users.values
        .where((u) =>
            (u.isStaff || u.role == 'business_admin') &&
            u.businessId == businessId)
        .toList();
  }

  @override
  Future<List<User>> getCustomers({String? businessId}) async => users.values
      .where((u) =>
          u.role == 'customer' &&
          (businessId == null || u.businessId == businessId))
      .toList();
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

    test('authenticated professional on login redirects to professional home',
        () {
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

    test(
        'profile incomplete with authenticated session redirects to complete-profile',
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

    test(
        'authenticated super_admin on login redirects to super admin dashboard',
        () {
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

    test(
        'business_admin with trial business on login redirects to setup wizard',
        () {
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
        ..setBusiness(
            Business(id: 'biz_1', name: 'Test', status: BusinessStatus.trial));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test(
        'business_admin with active business on login redirects to admin dashboard',
        () {
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
        ..setBusiness(Business(
            id: 'biz_2', name: 'Active Biz', status: BusinessStatus.active));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.login,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.adminDashboard);
    });

    test('business_admin with null business on login redirects to setup wizard',
        () {
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

    test('business_admin on customer home redirects to setup wizard when trial',
        () {
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
        ..setBusiness(Business(
            id: 'biz_4', name: 'Trial Biz', status: BusinessStatus.trial));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test('business_admin with active business stays on business settings', () {
      final user = User(
        id: '9',
        name: 'Biz Admin',
        email: 'biz6@test.com',
        phone: '555-0900',
        role: 'business_admin',
        businessId: 'biz_6',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(
            id: 'biz_6', name: 'Active Biz', status: BusinessStatus.active));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.businessSettings,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, isNull);
    });

    test('business_admin with active business stays on earnings report', () {
      final user = User(
        id: '10',
        name: 'Biz Admin',
        email: 'biz7@test.com',
        phone: '555-1000',
        role: 'business_admin',
        businessId: 'biz_7',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(
            id: 'biz_7', name: 'Active Biz', status: BusinessStatus.active));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.earningsReport,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, isNull);
    });

    test(
        'business_admin with trial business on earnings report redirects to setup wizard',
        () {
      final user = User(
        id: '11',
        name: 'Biz Admin',
        email: 'biz8@test.com',
        phone: '555-1100',
        role: 'business_admin',
        businessId: 'biz_8',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(
            id: 'biz_8', name: 'Trial Biz', status: BusinessStatus.trial));

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.earningsReport,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test('normalizeRole maps legacy professional to staff', () {
      expect(User.normalizeRole('professional'), 'staff');
      expect(User.normalizeRole('staff'), 'staff');
      expect(User.normalizeRole('customer'), 'customer');
      expect(User.normalizeRole('business_admin'), 'business_admin');
      expect(User.normalizeRole('super_admin'), 'super_admin');
    });

    test('legacy professional role resolves to staff enum', () {
      final legacy = User(
        id: '1',
        name: 'Legacy',
        email: 'legacy@test.com',
        phone: '555-0000',
        role: 'professional',
      );
      expect(legacy.isStaff, isTrue);
      expect(legacy.roleEnum, Role.staff);
    });

    test('business_admin with assigned but unloaded business stays put in-app',
        () {
      // Transient state: businessId set, business not yet fetched.
      // Must not yank into setup wizard mid-session (admin pages handle null).
      final user = User(
        id: '12',
        name: 'Biz Admin',
        email: 'biz9@test.com',
        phone: '555-1200',
        role: 'business_admin',
        businessId: 'biz_9',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider();

      for (final route in [Routes.customerHome, Routes.businessSettings]) {
        final redirect = RouteGuardHelper.evaluateRedirect(
          currentRoute: route,
          authProvider: auth,
          businessProvider: businessProvider,
          isAuthenticatedOverride: true,
          isProfileCompleteOverride: true,
        );
        expect(redirect, isNull, reason: 'route $route');
      }
    });

    test('business_admin with no business at all goes to setup wizard in-app',
        () {
      final user = User(
        id: '13',
        name: 'Biz Admin',
        email: 'biz10@test.com',
        phone: '555-1300',
        role: 'business_admin',
      );
      final auth = _authProviderWithUser(user);
      final businessProvider = BusinessProvider();

      final redirect = RouteGuardHelper.evaluateRedirect(
        currentRoute: Routes.customerHome,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
      expect(redirect, Routes.setupWizard);
    });

    test(
        'business_admin on customer home redirects to admin dashboard when active',
        () {
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
        ..setBusiness(Business(
            id: 'biz_5', name: 'Active Biz', status: BusinessStatus.active));

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

  group('Role x route matrix', () {
    String? check({
      required String role,
      String? businessId,
      Business? business,
      required String route,
    }) {
      final auth = _authProviderWithUser(User(
        id: 'm',
        name: 'Matrix',
        email: 'matrix@test.com',
        phone: '555-9999',
        role: role,
        businessId: businessId,
      ));
      final businessProvider = BusinessProvider();
      if (business != null) businessProvider.setBusiness(business);
      return RouteGuardHelper.evaluateRedirect(
        currentRoute: route,
        authProvider: auth,
        businessProvider: businessProvider,
        isAuthenticatedOverride: true,
        isProfileCompleteOverride: true,
      );
    }

    test('customer matrix', () {
      expect(check(role: 'customer', route: Routes.login), Routes.customerHome);
      expect(check(role: 'customer', route: Routes.customerHome), isNull);
      expect(check(role: 'customer', route: Routes.professionalHome),
          Routes.customerHome);
      // Guard does not fence customers off admin pages (unchanged behavior).
      expect(check(role: 'customer', route: Routes.businessSettings), isNull);
    });

    test('staff and legacy professional matrices are identical', () {
      for (final role in ['staff', 'professional']) {
        expect(check(role: role, route: Routes.login), Routes.professionalHome,
            reason: role);
        expect(check(role: role, route: Routes.customerHome),
            Routes.professionalHome,
            reason: role);
        expect(check(role: role, route: Routes.professionalHome), isNull,
            reason: role);
        expect(check(role: role, route: Routes.businessSettings), isNull,
            reason: role);
      }
    });

    test('super_admin matrix', () {
      expect(check(role: 'super_admin', route: Routes.login),
          Routes.superAdminDashboard);
      expect(check(role: 'super_admin', route: Routes.customerHome), isNull);
    });

    test('business_admin trial matrix', () {
      final trial =
          Business(id: 't', name: 'Trial', status: BusinessStatus.trial);
      expect(
          check(
              role: 'business_admin',
              businessId: 't',
              business: trial,
              route: Routes.login),
          Routes.setupWizard);
      expect(
          check(
              role: 'business_admin',
              businessId: 't',
              business: trial,
              route: Routes.customerHome),
          Routes.setupWizard);
      expect(
          check(
              role: 'business_admin',
              businessId: 't',
              business: trial,
              route: Routes.businessSettings),
          Routes.setupWizard);
      expect(
          check(
              role: 'business_admin',
              businessId: 't',
              business: trial,
              route: Routes.setupWizard),
          isNull);
    });

    test('business_admin active matrix', () {
      final active =
          Business(id: 'a', name: 'Active', status: BusinessStatus.active);
      expect(
          check(
              role: 'business_admin',
              businessId: 'a',
              business: active,
              route: Routes.login),
          Routes.adminDashboard);
      expect(
          check(
              role: 'business_admin',
              businessId: 'a',
              business: active,
              route: Routes.customerHome),
          Routes.adminDashboard);
      expect(
          check(
              role: 'business_admin',
              businessId: 'a',
              business: active,
              route: Routes.businessSettings),
          isNull);
      expect(
          check(
              role: 'business_admin',
              businessId: 'a',
              business: active,
              route: Routes.earningsReport),
          isNull);
      // Active admins bounce off the wizard back to their dashboard.
      expect(
          check(
              role: 'business_admin',
              businessId: 'a',
              business: active,
              route: Routes.setupWizard),
          Routes.adminDashboard);
    });
  });
}
