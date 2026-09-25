import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exception.dart';
import '../models/payment.dart';
import '../utils/app_logger.dart';
import 'payment_repository.dart';

class FirestorePaymentRepository implements PaymentRepository {
  FirestorePaymentRepository._();
  static final FirestorePaymentRepository instance =
      FirestorePaymentRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _firestore.collection('payments');

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
  Future<Payment?> getPaymentByAppointment(String appointmentId,
      {String? businessId}) async {
    try {
      final query = await _withBusinessFilter(
        _paymentsCol.where('appointmentId', isEqualTo: appointmentId),
        businessId,
      ).limit(1).get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromMap(data);
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.getPaymentByAppointment error: $e\n$stack');
      throw AppException('Failed to load payment', cause: e);
    }
  }

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
      {String? businessId}) async {
    try {
      final query = await _withBusinessFilter(
        _paymentsCol.where('professionalId', isEqualTo: professionalId),
        businessId,
      ).get();
      final payments = <Payment>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        payments.add(Payment.fromMap(data));
      }
      payments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return payments;
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.getPaymentsByProfessional error: $e\n$stack');
      throw AppException('Failed to load payments', cause: e);
    }
  }

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
      String? professionalId, DateTime start, DateTime end,
      {String? businessId}) async {
    try {
      final startIso = start.toIso8601String();
      final endIso = end.toIso8601String();
      var query = _withBusinessFilter(
        _paymentsCol
            .where('appointmentDate', isGreaterThanOrEqualTo: startIso)
            .where('appointmentDate', isLessThan: endIso),
        businessId,
      );
      if (professionalId != null && professionalId.isNotEmpty) {
        query = query.where('professionalId', isEqualTo: professionalId);
      }
      final snapshot = await query.get();
      final payments = <Payment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        payments.add(Payment.fromMap(data));
      }
      payments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return payments;
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.getPaymentsByProfessionalInRange error: $e\n$stack');
      throw AppException('Failed to load payments', cause: e);
    }
  }

  @override
  Future<String> recordPayment(Payment payment) async {
    try {
      // Backfill tenant scope for payments created without businessId
      // (legacy clients): adopt it from the linked appointment when possible.
      var businessId = payment.businessId;
      if (businessId == null || businessId.isEmpty) {
        try {
          final apptDoc = await _firestore
              .collection('appointments')
              .doc(payment.appointmentId)
              .get();
          final adopted = apptDoc.data()?['businessId']?.toString();
          if (adopted != null && adopted.isNotEmpty) {
            businessId = adopted;
          }
        } catch (_) {
          // Adoption is best-effort; the payment itself must still record.
        }
      }
      final docRef = payment.id != null
          ? _paymentsCol.doc(payment.id)
          : _paymentsCol.doc();
      final withId = payment.copyWith(id: docRef.id, businessId: businessId);
      await docRef.set(withId.toMap());
      return docRef.id;
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.recordPayment error: $e\n$stack');
      throw AppException('Failed to record payment', cause: e);
    }
  }

  @override
  Future<int> updatePayment(Payment payment) async {
    try {
      if (payment.id == null) {
        throw const AppException('Payment ID is required');
      }
      await _paymentsCol.doc(payment.id).update(payment.toMap());
      return 1;
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.updatePayment error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update payment', cause: e);
    }
  }

  @override
  Future<int> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    try {
      if (paymentId.isEmpty) {
        throw const AppException('Payment ID is required');
      }
      await _paymentsCol.doc(paymentId).update({'status': status.name});
      return 1;
    } catch (e, stack) {
      AppLogger.error(
          'FirestorePaymentRepository.updatePaymentStatus error: $e\n$stack');
      if (e is AppException) rethrow;
      throw AppException('Failed to update payment status', cause: e);
    }
  }
}
