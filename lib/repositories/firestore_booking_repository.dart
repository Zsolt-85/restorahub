import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../helpers/app_exception.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import 'booking_repository.dart';

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository._();
  static final FirestoreBookingRepository instance = FirestoreBookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  @override
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _usersCol.doc(id).get();
      if (!doc.exists) {
        debugPrint('FirestoreBookingRepository.getUserById: doc does not exist for ID $id');
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return User.fromMap(data);
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.getUserById error: $e\n$stack');
      throw AppException('Failed to load user', cause: e);
    }
  }

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    try {
      var query = _usersCol.where('email', isEqualTo: email.trim());
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return false;
      if (excludeUserId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeUserId);
      }
      return true;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.isEmailTaken error: $e\n$stack');
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
      debugPrint('FirestoreBookingRepository.insertUser error: $e\n$stack');
      throw AppException('Failed to create user', cause: e);
    }
  }

  @override
  Future<int> updateUser(User user) async {
    try {
      if (user.id == null) {
        debugPrint('FirestoreBookingRepository.updateUser: user.id is null');
        throw const AppException('User ID is required');
      }
      await _usersCol.doc(user.id).update(user.toMap());
      return 1;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.updateUser error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update user', cause: e);
    }
  }

  @override
  Future<void> syncUserInAppointments(User user) async {
    try {
      if (user.id == null) return;

      final customerSnapshot = await _appointmentsCol
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

      final professionalSnapshot = await _appointmentsCol
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
      debugPrint('FirestoreBookingRepository.syncUserInAppointments error: $e\n$stack');
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
      debugPrint('FirestoreBookingRepository.getProfessionalsBySpecialty error: $e\n$stack');
      throw AppException('Failed to load professionals', cause: e);
    }
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    try {
      final query = await _appointmentsCol.get();
      final appointments = <Appointment>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        appointments.add(Appointment.fromMap(data));
      }
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.getAppointments error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<int> insertAppointment(Appointment appointment) async {
    try {
      final docRef = appointment.id != null
          ? _appointmentsCol.doc(appointment.id)
          : _appointmentsCol.doc();
      appointment.id = docRef.id;
      await docRef.set(appointment.toMap());
      return 1;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.insertAppointment error: $e\n$stack');
      throw AppException('Failed to create booking', cause: e);
    }
  }

  @override
  Future<int> updateAppointment(Appointment appointment) async {
    try {
      if (appointment.id == null) {
        throw const AppException('Appointment ID is required');
      }
      await _appointmentsCol.doc(appointment.id).update(appointment.toMap());
      return 1;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.updateAppointment error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update booking', cause: e);
    }
  }

  @override
  Future<int> deleteAppointment(String id) async {
    try {
      if (id.isEmpty) {
        throw const AppException('Appointment ID is required');
      }
      await _appointmentsCol.doc(id).delete();
      return 1;
    } catch (e, stack) {
      debugPrint('FirestoreBookingRepository.deleteAppointment error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to cancel booking', cause: e);
    }
  }
}
