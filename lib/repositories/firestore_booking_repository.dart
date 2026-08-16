import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exception.dart';
import '../models/appointment.dart';
import '../utils/app_logger.dart';
import 'booking_repository.dart';

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository._();
  static final FirestoreBookingRepository instance = FirestoreBookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId) async {
    try {
      final query = await _appointmentsCol
          .where('customerId', isEqualTo: customerId)
          .get();
      final appointments = <Appointment>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        appointments.add(Appointment.fromMap(data));
      }
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentsForCustomer error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId) async {
    try {
      final query = await _appointmentsCol
          .where('professionalId', isEqualTo: professionalId)
          .get();
      final appointments = <Appointment>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        appointments.add(Appointment.fromMap(data));
      }
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentsForProfessional error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0}) async {
    try {
      final slotEnd = dateTime.add(Duration(minutes: slotDurationMinutes));
      AppLogger.debug('AVAILABILITY CHECK: professionalId=$professionalId, dateTime=$dateTime, slotEnd=$slotEnd, buffer=$bufferTimeMinutes');
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final startOfDay = dateOnly.toIso8601String();
      final endOfDay = dateOnly.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String();
      final query = await _appointmentsCol
          .where('professionalId', isEqualTo: professionalId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThanOrEqualTo: endOfDay)
          .where('status', whereNotIn: ['cancelledByCustomer', 'cancelledByProfessional', 'noShow'])
          .get();
      AppLogger.debug('AVAILABILITY CHECK: ${query.docs.length} documents fetched from Firestore');
      final isAvailable = !query.docs.any((doc) {
        final data = doc.data();
        final apptDateTime = DateTime.parse(data['dateTime'] as String);
        final duration = data['durationMinutes'] as int? ?? 60;
        final occupiedDuration = duration + bufferTimeMinutes;
        final apptEnd = apptDateTime.add(Duration(minutes: occupiedDuration));
        final overlaps = apptEnd.isAfter(dateTime);
        AppLogger.debug('AVAILABILITY CHECK: doc=${doc.id}, apptDateTime=$apptDateTime, duration=$duration, buffer=$bufferTimeMinutes, apptEnd=$apptEnd, overlaps=$overlaps');
        return overlaps;
      });
      AppLogger.debug('AVAILABILITY CHECK: result=$isAvailable');
      return isAvailable;
    } catch (e, stack) {
      AppLogger.error('AVAILABILITY ERROR: $e \n $stack');
      throw AppException('Unable to check slot availability. Please check your connection and try again.', cause: e);
    }
  }

  @override
  Future<void> createAppointmentAtomic(Appointment appointment) async {
    final docRef = _firestore.collection('appointments').doc(appointment.id);
    appointment.id = docRef.id;
    AppLogger.debug('DEBUG: Targeted Collection: appointments');
    AppLogger.debug('DEBUG: Attempting write to project: ${FirebaseFirestore.instance.app.options.projectId}');

    try {
      await docRef.set(appointment.toMap());
    } catch (e, stack) {
      Object actualError = e;
      try {
        final dynamic dynamicError = e;
        if (dynamicError.error != null) {
          actualError = dynamicError.error;
        }
      } catch (_) {}
      AppLogger.error('DIRECT WRITE ERROR: $e');
      AppLogger.error('DEBUG RAW UNWRAPPED ERROR: $actualError');
      AppLogger.error('FirestoreBookingRepository.createAppointmentAtomic error: $actualError\n$stack');
      throw AppException(actualError.toString(), cause: e);
    }

    AppLogger.debug('DEBUG: Document Created with ID: ${docRef.id}');

    try {
      final serverSnapshot = await docRef.get(const GetOptions(source: Source.server));
      if (!serverSnapshot.exists) {
        throw const AppException('Server write rejected: Document does not exist on Firestore server.');
      }
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.createAppointmentAtomic verification error: $e\n$stack');
      if (e is AppException) rethrow;
      if (e is FirebaseException) {
        throw AppException('Failed to verify booking creation: $e', cause: e);
      }
      throw AppException('Failed to verify booking creation: $e', cause: e);
    }
  }

  @override
  Future<int> insertAppointment(Appointment appointment) async {
    final docRef = appointment.id != null
        ? _appointmentsCol.doc(appointment.id)
        : _appointmentsCol.doc();
    appointment.id = docRef.id;
    AppLogger.debug('DEBUG: Targeted Collection: ${_appointmentsCol.path}');
    AppLogger.debug('DEBUG: Attempting write to project: ${FirebaseFirestore.instance.app.options.projectId}');
    try {
      try {
        await docRef.set(appointment.toMap()).timeout(const Duration(seconds: 5));
      } catch (e) {
        AppLogger.error('DEBUG FIRESTORE CREATE ERROR: $e');
        rethrow;
      }
      AppLogger.debug('DEBUG: Document Created with ID: ${docRef.id}');

      try {
        final serverSnapshot = await docRef.get(const GetOptions(source: Source.server));
        if (!serverSnapshot.exists) {
          throw Exception('Server write rejected: Document does not exist on Firestore server.');
        }
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.insertAppointment verification error: $e\n$stack');
      if (e is AppException) rethrow;
      if (e is FirebaseException) {
        throw AppException('Failed to verify booking creation: $e', cause: e);
      }
      throw AppException('Failed to verify booking creation: $e', cause: e);
    }

      return 1;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.insertAppointment error: $e\n$stack');
      throw AppException('Failed to create booking: $e', cause: e);
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
      AppLogger.error('FirestoreBookingRepository.updateAppointment error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update booking: $e', cause: e);
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
      AppLogger.error('FirestoreBookingRepository.deleteAppointment error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to cancel booking: $e', cause: e);
    }
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId) {
    return _appointmentsCol
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final appointments = <Appointment>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            appointments.add(Appointment.fromMap(data));
          }
          appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return appointments;
        });
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId) {
    return _appointmentsCol
        .where('professionalId', isEqualTo: professionalId)
        .snapshots()
        .map((snapshot) {
          final appointments = <Appointment>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            appointments.add(Appointment.fromMap(data));
          }
          appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return appointments;
        });
  }

  @override
  Stream<Appointment?> watchAppointment(String id) {
    return _appointmentsCol
        .doc(id)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          final data = snapshot.data()!;
          data['id'] = snapshot.id;
          return Appointment.fromMap(data);
        });
  }
}
