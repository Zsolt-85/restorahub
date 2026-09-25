import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/app_exception.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import 'staff_directory_repository.dart';

class FirestoreStaffDirectoryRepository implements StaffDirectoryRepository {
  FirestoreStaffDirectoryRepository._();
  static final FirestoreStaffDirectoryRepository instance =
      FirestoreStaffDirectoryRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _directoryCol =>
      _firestore.collection('staff_directory');

  /// Public-safe projection of a staff profile. Email/phone never stored.
  static Map<String, dynamic> toEntry(User user) {
    return {
      'userId': user.id,
      'businessId': user.businessId,
      'name': user.name,
      'category': user.category,
      'role': User.normalizeRole(user.role),
      'workStartTime': user.workStartTime,
      'workEndTime': user.workEndTime,
      'slotDurationMinutes': user.slotDurationMinutes,
      'bufferTimeMinutes': user.bufferTimeMinutes,
      'breakStartTime': user.breakStartTime,
      'breakEndTime': user.breakEndTime,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static User fromEntry(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name']?.toString() ?? '',
      email: '',
      phone: '',
      role: data['role']?.toString() ?? 'staff',
      businessId: data['businessId']?.toString(),
      category: data['category']?.toString() ?? '',
      workStartTime: data['workStartTime']?.toString() ?? '09:00',
      workEndTime: data['workEndTime']?.toString() ?? '17:00',
      slotDurationMinutes: data['slotDurationMinutes'] as int? ?? 60,
      bufferTimeMinutes: data['bufferTimeMinutes'] as int? ?? 0,
      breakStartTime: data['breakStartTime']?.toString(),
      breakEndTime: data['breakEndTime']?.toString(),
    );
  }

  Query<Map<String, dynamic>> _scopedQuery({
    String? businessId,
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _directoryCol;
    if (businessId != null && businessId.isNotEmpty) {
      query = query.where('businessId', isEqualTo: businessId);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query;
  }

  @override
  Future<void> upsertEntry(User user) async {
    try {
      if (user.id == null || user.id!.isEmpty) {
        throw const AppException('User ID is required');
      }
      if (!user.isStaff) return;
      await _directoryCol.doc(user.id).set(toEntry(user));
    } catch (e, stack) {
      AppLogger.error(
          'FirestoreStaffDirectoryRepository.upsertEntry error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to publish staff profile', cause: e);
    }
  }

  @override
  Future<User?> getEntryById(String id) async {
    try {
      if (id.isEmpty) return null;
      final doc = await _directoryCol.doc(id).get();
      if (!doc.exists) return null;
      return fromEntry(doc.id, doc.data()!);
    } catch (e, stack) {
      AppLogger.error(
          'FirestoreStaffDirectoryRepository.getEntryById error: $e\n$stack');
      throw AppException('Failed to load staff profile', cause: e);
    }
  }

  @override
  Future<List<User>> getStaff({String? businessId, String? category}) async {
    try {
      final snapshot =
          await _scopedQuery(businessId: businessId, category: category).get();
      final staff = <User>[];
      for (final doc in snapshot.docs) {
        staff.add(fromEntry(doc.id, doc.data()));
      }
      staff.sort((a, b) => a.name.compareTo(b.name));
      return staff;
    } catch (e, stack) {
      AppLogger.error(
          'FirestoreStaffDirectoryRepository.getStaff error: $e\n$stack');
      throw AppException('Failed to load staff', cause: e);
    }
  }

  @override
  Stream<List<User>> watchStaff({String? businessId, String? category}) {
    return _scopedQuery(businessId: businessId, category: category)
        .snapshots()
        .map((snapshot) {
      final staff = <User>[];
      for (final doc in snapshot.docs) {
        staff.add(fromEntry(doc.id, doc.data()));
      }
      staff.sort((a, b) => a.name.compareTo(b.name));
      return staff;
    });
  }
}
