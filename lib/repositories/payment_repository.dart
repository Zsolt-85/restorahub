import '../models/payment.dart';

abstract class PaymentRepository {
  Future<Payment?> getPaymentByAppointment(String appointmentId);
  Future<List<Payment>> getPaymentsByProfessional(String professionalId);
  Future<List<Payment>> getPaymentsByProfessionalInRange(
    String professionalId,
    DateTime start,
    DateTime end,
  );
  Future<int> recordPayment(Payment payment);
  Future<int> updatePayment(Payment payment);
  Future<int> updatePaymentStatus(String paymentId, PaymentStatus status);
}