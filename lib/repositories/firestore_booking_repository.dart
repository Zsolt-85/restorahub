import 'dart:async';

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
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId, {String? businessId}) async {
    try {
      final query = await _withBusinessFilter(
        _appointmentsCol.where('customerId', isEqualTo: customerId),
        businessId,
      ).get();
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
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) async {
    try {
      Query<Map<String, dynamic>> baseQuery = _appointmentsCol.where('professionalId', isEqualTo: professionalId);
      if (businessId != null && businessId.isNotEmpty) {
        baseQuery = baseQuery.where('businessId', isEqualTo: businessId);
      }
      final byId = await baseQuery.get();
      final results = <String, Appointment>{};
      for (final doc in byId.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = Appointment.fromMap(data);
      }

      if (results.isEmpty && professionalEmail != null && professionalEmail.isNotEmpty) {
        Query<Map<String, dynamic>> emailQuery = _appointmentsCol.where('professionalEmail', isEqualTo: professionalEmail);
        if (businessId != null && businessId.isNotEmpty) {
          emailQuery = emailQuery.where('businessId', isEqualTo: businessId);
        }
        final byEmailSnapshot = await emailQuery.get();
        for (final doc in byEmailSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          results[doc.id] = Appointment.fromMap(data);
        }
      }

      final appointments = results.values.toList();
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentsForProfessional error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate, int? limit, String? startAfterDocumentId}) async {
    try {
      if (businessId.isEmpty) {
        throw const AppException('businessId is required for tenant-scoped queries');
      }
      Query<Map<String, dynamic>> query = _appointmentsCol.where('businessId', isEqualTo: businessId);
      if (startDate != null) {
        query = query.where('dateTime', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('dateTime', isLessThanOrEqualTo: endDate.toIso8601String());
      }
      query = query.orderBy('dateTime');
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
        final startAfterDoc = await _appointmentsCol.doc(startAfterDocumentId).get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }
      final snapshot = await query.get();
      final appointments = <Appointment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        appointments.add(Appointment.fromMap(data));
      }
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentsForBusiness error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusinessInRange(String businessId, DateTime start, DateTime end, {String? professionalId}) async {
    try {
      Query<Map<String, dynamic>> query = _appointmentsCol
          .where('businessId', isEqualTo: businessId)
          .where('dateTime', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('dateTime', isLessThanOrEqualTo: end.toIso8601String());
      if (professionalId != null && professionalId.isNotEmpty) {
        query = query.where('professionalId', isEqualTo: professionalId);
      }
      final snapshot = await query.get();
      final appointments = <Appointment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        appointments.add(Appointment.fromMap(data));
      }
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentsForBusinessInRange error: $e\n$stack');
      throw AppException('Failed to load appointments', cause: e);
    }
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0, String? businessId, String? professionalEmail}) async {
    try {
      final slotEnd = dateTime.add(Duration(minutes: slotDurationMinutes));
      AppLogger.debug('AVAILABILITY CHECK: professionalId=$professionalId, dateTime=$dateTime, slotEnd=$slotEnd, buffer=$bufferTimeMinutes');
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final startOfDay = dateOnly.toIso8601String();
      final endOfDay = dateOnly.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String();

      Query<Map<String, dynamic>> query = _appointmentsCol
          .where('professionalId', isEqualTo: professionalId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThanOrEqualTo: endOfDay)
          .where('status', whereNotIn: ['cancelledByCustomer', 'cancelledByProfessional', 'noShow']);

      final byIdSnap = await query.get();
      final docs = byIdSnap.docs;

      if (docs.isEmpty && professionalEmail != null && professionalEmail.isNotEmpty) {
        final byEmailSnap = await _appointmentsCol
            .where('professionalEmail', isEqualTo: professionalEmail)
            .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
            .where('dateTime', isLessThanOrEqualTo: endOfDay)
            .where('status', whereNotIn: ['cancelledByCustomer', 'cancelledByProfessional', 'noShow'])
            .get();
        docs.addAll(byEmailSnap.docs);
      }

      AppLogger.debug('AVAILABILITY CHECK: ${docs.length} documents fetched from Firestore');
      final isAvailable = !docs.any((doc) {
        final data = doc.data();
        final apptDateTime = DateTime.parse(data['dateTime'] as String);
        final duration = data['durationMinutes'] as int? ?? 60;
        final occupiedDuration = duration + bufferTimeMinutes;
        final apptEnd = apptDateTime.add(Duration(minutes: occupiedDuration));
        final overlaps = apptEnd.isAfter(dateTime) && apptDateTime.isBefore(slotEnd);
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
      throw AppException('Failed to cancel booking: $e', cause: e);
    }
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId, {String? businessId}) {
    return _appointmentsCol.where('customerId', isEqualTo: customerId).snapshots()
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
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) {
    final byId = _appointmentsCol.where('professionalId', isEqualTo: professionalId).snapshots().map((snapshot) {
      final map = <String, Appointment>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        map[doc.id] = Appointment.fromMap(data);
      }
      return map;
    });

    if (professionalEmail == null || professionalEmail.isEmpty) {
      return byId.map((map) {
        final list = map.values.toList();
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return list;
      });
    }

    final byEmail = _appointmentsCol.where('professionalEmail', isEqualTo: professionalEmail).snapshots().map((snapshot) {
      final map = <String, Appointment>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        map[doc.id] = Appointment.fromMap(data);
      }
      return map;
    });

    return _combineLatest(byId, byEmail);
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) {
    Query<Map<String, dynamic>> query = _appointmentsCol.where('businessId', isEqualTo: businessId);
    if (startDate != null) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('dateTime', isLessThanOrEqualTo: endDate.toIso8601String());
    }
    return query.snapshots().map((snapshot) {
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

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    if (id.isEmpty) return null;
    try {
      final doc = await _appointmentsCol.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return Appointment.fromMap(data);
    } catch (e, stack) {
      AppLogger.error('FirestoreBookingRepository.getAppointmentById error: $e\n$stack');
      throw AppException('Failed to load appointment', cause: e);
    }
  }

  Stream<List<T>> _combineLatest<T, S>(
    Stream<Map<String, T>> streamA,
    Stream<Map<String, T>> streamB,
  ) {
    return Stream<List<T>>.multi((controller) {
      final combined = <String, T>{};
      var aDone = false;
      var bDone = false;
      var aValue = <String, T>{};
      var bValue = <String, T>{};

      void emit() {
        combined.clear();
        combined.addAll(aValue);
        combined.addAll(bValue);
        final list = combined.values.toList();
        list.sort((a, b) => (a as Appointment).dateTime.compareTo((b as Appointment).dateTime));
        controller.add(list);
      }

      final subA = streamA.listen((value) {
        aValue = value;
        emit();
      }, onError: controller.addError, onDone: () {
        aDone = true;
        if (bDone) controller.close();
      });

      final subB = streamB.listen((value) {
        bValue = value;
        emit();
      }, onError: controller.addError, onDone: () {
        bDone = true;
        if (aDone) controller.close();
      });

      controller.onCancel = () {
        subA.cancel();
        subB.cancel();
      };
    });
  }
}
