import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/user_resolution_helper.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/repositories/user_repository.dart';

class _FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};

  void addUser(User user) {
    if (user.id != null) {
      _users[user.id!] = user;
    }
  }

  @override
  Future<List<User>> getCustomers() async => [];

  @override
  Future<List<User>> getProfessionals({String? businessId}) async => [];

  @override
  Future<List<User>> getProfessionalsByCategory(String category) async => [];

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async => [];

  @override
  Future<User?> getUserById(String id) async => _users[id];

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async => false;

  @override
  Future<int> insertUser(User user) async => 0;

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<int> updateUser(User user) async => 0;

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) => Stream.value([]);
}

void main() {
  group('UserResolutionHelper', () {
    late _FakeUserRepository repo;
    late UserResolutionHelper helper;

    setUp(() {
      repo = _FakeUserRepository();
      repo.addUser(User(
        id: 'user_1',
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: '5551234567',
        role: 'customer',
      ));
      repo.addUser(User(
        id: 'user_2',
        name: 'Bob Jones',
        email: 'bob@example.com',
        phone: '5559876543',
        role: 'professional',
      ));
      helper = UserResolutionHelper(userRepository: repo);
    });

    test('resolveUserDisplayName returns name for valid userId', () async {
      final name = await helper.resolveUserDisplayName('user_1');
      expect(name, 'Alice Smith');
    });

    test('resolveUserDisplayName returns fallback for null userId', () async {
      final name = await helper.resolveUserDisplayName(null);
      expect(name, 'Unknown');
    });

    test('resolveUserDisplayName returns fallback for empty userId', () async {
      final name = await helper.resolveUserDisplayName('');
      expect(name, 'Unknown');
    });

    test('resolveUserDisplayName returns custom fallback', () async {
      final name = await helper.resolveUserDisplayName('nonexistent', fallback: 'N/A');
      expect(name, 'N/A');
    });

    test('resolveUserEmail returns email for valid userId', () async {
      final email = await helper.resolveUserEmail('user_1');
      expect(email, 'alice@example.com');
    });

    test('resolveUserEmail returns null for invalid userId', () async {
      final email = await helper.resolveUserEmail('nonexistent');
      expect(email, isNull);
    });

    test('resolveUserPhone returns phone for valid userId', () async {
      final phone = await helper.resolveUserPhone('user_2');
      expect(phone, '5559876543');
    });

    test('resolveUserPhone returns null for invalid userId', () async {
      final phone = await helper.resolveUserPhone('nonexistent');
      expect(phone, isNull);
    });

    test('caches user lookups', () async {
      await helper.resolveUserDisplayName('user_1');
      await helper.resolveUserDisplayName('user_1');
    });

    test('clearCache removes all cached entries', () async {
      await helper.resolveUserDisplayName('user_1');
      helper.clearCache();
    });

    test('invalidateCache removes specific entry', () async {
      await helper.resolveUserDisplayName('user_1');
      helper.invalidateCache('user_1');
    });
  });
}
