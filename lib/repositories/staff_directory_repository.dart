import '../models/user.dart';

/// Public, PII-free staff directory backing customer-facing booking flows.
///
/// `users` list queries cannot be secured per tenant in Firestore rules, so
/// bookable staff are mirrored here (name, category, schedule only — never
/// email/phone). Reads are signed-in public; writes are owner/super-admin.
abstract class StaffDirectoryRepository {
  Future<void> upsertEntry(User user);
  Future<User?> getEntryById(String id);
  Future<List<User>> getStaff({String? businessId, String? category});
  Stream<List<User>> watchStaff({String? businessId, String? category});
}
