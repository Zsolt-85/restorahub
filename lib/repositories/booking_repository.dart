import '../models/appointment.dart';

abstract class BookingRepository {
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId);
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId);
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0});
  Future<void> createAppointmentAtomic(Appointment appointment);
  Future<int> insertAppointment(Appointment appointment);
  Future<int> updateAppointment(Appointment appointment);
  Future<int> deleteAppointment(String id);

  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId);
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId);
  Stream<Appointment?> watchAppointment(String id);
}
