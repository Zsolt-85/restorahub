import '../models/appointment.dart';
import '../models/user.dart';

abstract class BookingRepository {
  Future<User?> getUserById(String id);
  Future<bool> isEmailTaken(String email, {String? excludeUserId});
  Future<int> insertUser(User user);
  Future<int> updateUser(User user);
  Future<void> syncUserInAppointments(User user);

  Future<List<User>> getProfessionalsBySpecialty(String specialty);
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId);
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId);
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes});
  Future<int> insertAppointment(Appointment appointment);
  Future<int> updateAppointment(Appointment appointment);
  Future<int> deleteAppointment(String id);
}
