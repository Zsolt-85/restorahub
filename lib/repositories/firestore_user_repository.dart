import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exception.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository._();
  static final FirestoreUserRepository instance = FirestoreUserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Query<Map<String, dynamic>> _withBusinessFilter(
    Query<Map<String, dynamic>> query,
    String? businessId,
  ) {
    if (businessId != null && businessId.isNotEmpty) {
      return query.where('businessId', isEqualTo: businessId);
    }
    return query;
  }

  @override
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _usersCol.doc(id).get();
      if (!doc.exists) {
        AppLogger.debug('FirestoreUserRepository.getUserById: doc does not exist for ID $id');
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return User.fromMap(data);
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.getUserById error: $e\n$stack');
      throw AppException('Failed to load user', cause: e);
    }
  }

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    try {
      var query = _usersCol.where('email', isEqualTo: email.trim().toLowerCase());
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return false;
      if (excludeUserId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeUserId);
      }
      return true;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.isEmailTaken error: $e\n$stack');
      throw AppException('Failed to check email availability', cause: e);
    }
  }

  @override
  Future<int> insertUser(User user) async {
    try {
      final docRef = user.id != null ? _usersCol.doc(user.id) : _usersCol.doc();
      final data = user.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
      return 1;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.insertUser error: $e\n$stack');
      throw AppException('Failed to create user', cause: e);
    }
  }

  @override
  Future<int> updateUser(User user) async {
    try {
      if (user.id == null) {
        AppLogger.debug('FirestoreUserRepository.updateUser: user.id is null');
        throw const AppException('User ID is required');
      }
      await _usersCol.doc(user.id).update(user.toMap());
      return 1;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.updateUser error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update user', cause: e);
    }
  }

  @override
  Future<void> syncUserInAppointments(User user) async {
    try {
      if (user.id == null) return;

      final customerSnapshot = await _firestore.collection('appointments')
          .where('customerId', isEqualTo: user.id)
          .get();

      final batch = _firestore.batch();
      for (final doc in customerSnapshot.docs) {
        batch.update(doc.reference, {
          'customerName': user.name,
          'customerPhone': user.phone,
          'customerEmail': user.email,
        });
      }

      final professionalSnapshot = await _firestore.collection('appointments')
          .where('professionalId', isEqualTo: user.id)
          .get();

      for (final doc in professionalSnapshot.docs) {
        batch.update(doc.reference, {
          'professionalName': user.name,
          'professionalPhone': user.phone,
          'professionalEmail': user.email,
        });
      }

      await batch.commit();
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.syncUserInAppointments error: $e\n$stack');
      throw AppException('Failed to sync user data', cause: e);
    }
  }

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    try {
      final query = await _usersCol
          .where('role', isEqualTo: 'professional')
          .where('specialty', isEqualTo: specialty)
          .get();

      final professionals = <User>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        professionals.add(User.fromMap(data));
      }
      professionals.sort((a, b) => a.name.compareTo(b.name));
      return professionals;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.getProfessionalsBySpecialty error: $e\n$stack');
      throw AppException('Failed to load professionals', cause: e);
    }
  }

  @override
  Future<List<User>> getProfessionals({String? businessId}) async {
    try {
      final query = await _withBusinessFilter(
        _usersCol.where('role', isEqualTo: 'professional'),
        businessId,
      ).get();

      final professionals = <User>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        professionals.add(User.fromMap(data));
      }
      professionals.sort((a, b) => a.name.compareTo(b.name));
      return professionals;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.getProfessionals error: $e\n$stack');
      throw AppException('Failed to load professionals', cause: e);
    }
  }

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) {
    return _withBusinessFilter(
      _usersCol.where('role', isEqualTo: 'professional'),
      businessId,
    ).snapshots().map((snapshot) {
      final professionals = <User>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        professionals.add(User.fromMap(data));
      }
      professionals.sort((a, b) => a.name.compareTo(b.name));
      return professionals;
    });
  }

  @override
  Future<List<User>> getCustomers() async {
    try {
      final query = await _usersCol.where('role', isEqualTo: 'customer').get();

      final customers = <User>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        customers.add(User.fromMap(data));
      }
      customers.sort((a, b) => a.name.compareTo(b.name));
      return customers;
    } catch (e, stack) {
      AppLogger.error('FirestoreUserRepository.getCustomers error: $e\n$stack');
      throw AppException('Failed to load customers', cause: e);
    }
  }
}
