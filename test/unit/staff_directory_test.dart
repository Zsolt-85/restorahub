import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/repositories/firestore_staff_directory_repository.dart';
import 'package:restorahub/repositories/staff_directory_repository.dart';

/// In-memory stand-in mirroring the Firestore scoping semantics.
class FakeStaffDirectoryRepository implements StaffDirectoryRepository {
  final List<User> entries = [];

  @override
  Future<void> upsertEntry(User user) async {
    if (user.id == null || !user.isStaff) return;
    entries.removeWhere((u) => u.id == user.id);
    entries.add(user);
  }

  @override
  Future<User?> getEntryById(String id) async {
    if (id.isEmpty) return null;
    final matches = entries.where((u) => u.id == id).toList();
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<User>> getStaff({String? businessId, String? category}) async {
    return entries
        .where((u) =>
            (businessId == null ||
                businessId.isEmpty ||
                u.businessId == businessId) &&
            (category == null || category.isEmpty || u.category == category))
        .toList();
  }

  @override
  Stream<List<User>> watchStaff({String? businessId, String? category}) =>
      Stream.value([]);
}

User _staff(String id, String category, String? businessId) => User(
      id: id,
      name: 'Pro $id',
      email: 'pro-$id@test.com',
      phone: '555',
      role: 'staff',
      businessId: businessId,
      category: category,
    );

void main() {
  group('Staff directory entry mapping', () {
    test('toEntry strips PII and normalizes legacy roles', () {
      final entry = FirestoreStaffDirectoryRepository.toEntry(
        _staff('u1', 'Massage', 'biz-a').copyWith(role: 'professional'),
      );

      expect(entry['userId'], 'u1');
      expect(entry['businessId'], 'biz-a');
      expect(entry['name'], 'Pro u1');
      expect(entry['category'], 'Massage');
      expect(entry['role'], 'staff');
      expect(entry.containsKey('email'), isFalse);
      expect(entry.containsKey('phone'), isFalse);
    });

    test('fromEntry round-trips public fields with safe defaults', () {
      final entry = FirestoreStaffDirectoryRepository.toEntry(
          _staff('u1', 'Massage', 'biz-a'));
      final user = FirestoreStaffDirectoryRepository.fromEntry('u1', entry);

      expect(user.id, 'u1');
      expect(user.name, 'Pro u1');
      expect(user.category, 'Massage');
      expect(user.businessId, 'biz-a');
      expect(user.isStaff, isTrue);
      expect(user.email, isEmpty);
      expect(user.phone, isEmpty);
    });
  });

  group('Staff directory scoping', () {
    test('upsert ignores non-staff and id-less users', () async {
      final repo = FakeStaffDirectoryRepository();
      await repo.upsertEntry(User(
          id: 'c1',
          name: 'C',
          email: 'c@t.com',
          phone: '1',
          role: 'customer',
          businessId: 'biz-a'));
      await repo.upsertEntry(User(
          name: 'NoId',
          email: 'n@t.com',
          phone: '1',
          role: 'staff',
          businessId: 'biz-a'));

      expect(repo.entries, isEmpty);
    });

    test('getStaff filters by business and category', () async {
      final repo = FakeStaffDirectoryRepository();
      await repo.upsertEntry(_staff('u1', 'Massage', 'biz-a'));
      await repo.upsertEntry(_staff('u2', 'Facial', 'biz-a'));
      await repo.upsertEntry(_staff('u3', 'Massage', 'biz-b'));
      await repo.upsertEntry(_staff('u4', 'Massage', null));

      final scoped =
          await repo.getStaff(businessId: 'biz-a', category: 'Massage');
      expect(scoped.map((u) => u.id), ['u1']);

      final unscoped = await repo.getStaff(category: 'Massage');
      expect(unscoped.map((u) => u.id).toSet(), {'u1', 'u3', 'u4'});
    });

    test('getEntryById resolves solo pros for reschedule flows', () async {
      final repo = FakeStaffDirectoryRepository();
      await repo.upsertEntry(_staff('u4', 'Massage', null));

      expect((await repo.getEntryById('u4'))?.id, 'u4');
      expect(await repo.getEntryById('missing'), isNull);
      expect(await repo.getEntryById(''), isNull);
    });
  });
}
