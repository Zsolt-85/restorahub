import '../models/appointment.dart';
import '../models/user.dart';

abstract class BookingRepository {
  Future<User?> getUserById(int id);
  Future<User?> getUserByEmail(String email);
  Future<bool> isEmailTaken(String email, {int? excludeUserId});
  Future<int> insertUser(User user);
  Future<int> updateUser(User user);
  Future<void> syncUserInAppointments(User user);

  Future<List<User>> getProfessionalsBySpecialty(String specialty);
  Future<List<Appointment>> getAppointments();
  Future<int> insertAppointment(Appointment appointment);
  Future<int> updateAppointment(Appointment appointment);
  Future<int> deleteAppointment(int id);
}
