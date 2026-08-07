import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../helpers/app_exception.dart';
import '../models/appointment.dart';
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
      debugPrint('FirestoreBookingRepository.getAppointmentsForCustomer error: $e\n$stack');
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
      debugPrint('FirestoreBookingRepository.getAppointmentsForProfessional error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0}) async {
    try {
      final slotEnd = dateTime.add(Duration(minutes: slotDurationMinutes));
      print('AVAILABILITY CHECK: professionalId=$professionalId, dateTime=$dateTime, slotEnd=$slotEnd, buffer=$bufferTimeMinutes');
      final query = await _appointmentsCol
          .where('professionalId', isEqualTo: professionalId)
          .where('dateTime', isLessThan: slotEnd.toIso8601String())
          .where('status', whereNotIn: ['cancelledByCustomer', 'cancelledByProfessional', 'noShow'])
          .get();
      print('AVAILABILITY CHECK: ${query.docs.length} documents fetched from Firestore');
      final isAvailable = !query.docs.any((doc) {
        final data = doc.data();
        final apptDateTime = DateTime.parse(data['dateTime'] as String);
        final duration = data['durationMinutes'] as int? ?? 60;
        final occupiedDuration = duration + bufferTimeMinutes;
        final apptEnd = apptDateTime.add(Duration(minutes: occupiedDuration));
        final overlaps = apptEnd.isAfter(dateTime);
        print('AVAILABILITY CHECK: doc=${doc.id}, apptDateTime=$apptDateTime, duration=$duration, buffer=$bufferTimeMinutes, apptEnd=$apptEnd, overlaps=$overlaps');
        return overlaps;
      });
      print('AVAILABILITY CHECK: result=$isAvailable');
      return isAvailable;
    } catch (e, stack) {
      print('AVAILABILITY ERROR: $e \n $stack');
      throw AppException('Unable to check slot availability. Please check your connection and try again.', cause: e);
    }
  }

  @override
  Future<void> createAppointmentAtomic(Appointment appointment) async {
    try {
      await _firestore.runTransaction((transaction) async {
        if (appointment.professionalId != null) {
          final slotStart = appointment.dateTime;
          final slotEnd = slotStart.add(Duration(minutes: appointment.durationMinutes));

          final query = await _appointmentsCol
              .where('professionalId', isEqualTo: appointment.professionalId)
              .where('status', whereIn: ['pending', 'confirmed'])
              .get();

          for (final doc in query.docs) {
            final data = doc.data();
            final apptDateTime = DateTime.parse(data['dateTime'] as String);
            final duration = data['durationMinutes'] as int? ?? 60;
            final buffer = data['bufferTimeMinutes'] as int? ?? 0;
            final apptEnd = apptDateTime.add(Duration(minutes: duration + buffer));

            if (slotStart.isBefore(apptEnd) && slotEnd.isAfter(apptDateTime)) {
              throw AppException('This time slot is no longer available', code: 'SLOT_TAKEN');
            }
          }
        }

        final docRef = appointment.id != null
            ? _appointmentsCol.doc(appointment.id)
            : _appointmentsCol.doc();
        appointment.id = docRef.id;
        transaction.set(docRef, appointment.toMap());
      });
    } catch (e, stack) {
      if (e is AppException) rethrow;
      debugPrint('FirestoreBookingRepository.createAppointmentAtomic error: $e\n$stack');
      throw AppException('Failed to create booking', cause: e);
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
