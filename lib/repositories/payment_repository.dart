import '../models/payment.dart';

abstract class PaymentRepository {
  Future<Payment?> getPaymentByAppointment(String appointmentId,
      {String? businessId});
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
      {String? businessId});
  Future<List<Payment>> getPaymentsByProfessionalInRange(
      String? professionalId, DateTime start, DateTime end,
      {String? businessId});

  /// Records the payment and returns its document id.
  /// Never mutates the passed [payment]; callers must use the returned id.
  Future<String> recordPayment(Payment payment);
  Future<int> updatePayment(Payment payment);
  Future<int> updatePaymentStatus(String paymentId, PaymentStatus status);
}
