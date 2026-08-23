import '../models/appointment.dart';

abstract class BookingRepository {
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId, {String? businessId});
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail});
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate});
  Future<List<Appointment>> getAppointmentsForBusinessInRange(String businessId, DateTime start, DateTime end, {String? professionalId});
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0, String? businessId, String? professionalEmail});
  Future<void> createAppointmentAtomic(Appointment appointment);
  Future<int> insertAppointment(Appointment appointment);
  Future<int> updateAppointment(Appointment appointment);
  Future<int> deleteAppointment(String id);

  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId, {String? businessId});
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail});
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate});
  Stream<Appointment?> watchAppointment(String id);
  Future<Appointment?> getAppointmentById(String id);
}
