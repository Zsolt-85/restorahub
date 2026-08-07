import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/helpers/route_guard_helper.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/providers/auth_provider.dart';
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
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    return users.values
        .where((u) => u.role == 'professional' && u.specialty == specialty)
        .toList();
  }
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
  });
}
