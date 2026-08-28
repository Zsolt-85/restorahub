import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/app_exception.dart';
import '../models/business.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

abstract class SuperAdminRepository {
  Future<List<Business>> getAllBusinesses();
  Future<void> createBusiness(Business business);
  Future<void> updateBusiness(Business business);
  Future<List<User>> getAllUsers({String? searchQuery});
  Future<void> updateUserRoleAndBusiness(
    String userId,
    String newRole,
    String? businessId,
  );
}

class FirestoreSuperAdminRepository implements SuperAdminRepository {
  FirestoreSuperAdminRepository._();
  static final FirestoreSuperAdminRepository instance =
      FirestoreSuperAdminRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _businessesCol =>
      _firestore.collection('businesses');

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  @override
  Future<List<Business>> getAllBusinesses() async {
    try {
      final snapshot = await _businessesCol.get();
      final businesses = <Business>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        businesses.add(Business.fromMap(data));
      }
      businesses.sort((a, b) => a.name.compareTo(b.name));
      return businesses;
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreSuperAdminRepository.getAllBusinesses error: $e\n$stack',
      );
      throw AppException('Failed to load businesses', cause: e);
    }
  }

  @override
  Future<void> createBusiness(Business business) async {
    try {
      final docRef = business.id.isEmpty
          ? _businessesCol.doc()
          : _businessesCol.doc(business.id);

      final data = business.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreSuperAdminRepository.createBusiness error: $e\n$stack',
      );
      throw AppException('Failed to create business: $e', cause: e);
    }
  }

  @override
  Future<void> updateBusiness(Business business) async {
    try {
      if (business.id.isEmpty) {
        throw const AppException('Business ID is required');
      }
      await _businessesCol.doc(business.id).update(business.toMap());
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreSuperAdminRepository.updateBusiness error: $e\n$stack',
      );
      if (e is AppException) rethrow;
      throw AppException('Failed to update business', cause: e);
    }
  }

  @override
  Future<List<User>> getAllUsers({String? searchQuery}) async {
    try {
      final snapshot = await _usersCol.get();
      final users = <User>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        users.add(User.fromMap(data));
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        return users
            .where(
              (u) =>
                  u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query) ||
                  u.phone.toLowerCase().contains(query),
            )
            .toList();
      }

      return users;
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreSuperAdminRepository.getAllUsers error: $e\n$stack',
      );
      throw AppException('Failed to load users', cause: e);
    }
  }

  @override
  Future<void> updateUserRoleAndBusiness(
    String userId,
    String newRole,
    String? businessId,
  ) async {
    try {
      if (userId.isEmpty) {
        throw const AppException('User ID is required');
      }
      await _usersCol.doc(userId).update({
        'role': newRole,
        'businessId': businessId,
      });
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreSuperAdminRepository.updateUserRoleAndBusiness error: $e\n$stack',
      );
      if (e is AppException) rethrow;
      throw AppException('Failed to update user', cause: e);
    }
  }
}
