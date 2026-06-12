import '../helpers/database_helper.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import 'booking_repository.dart';

class LocalBookingRepository implements BookingRepository {
  LocalBookingRepository._();
  static final LocalBookingRepository instance = LocalBookingRepository._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<User?> getUserById(int id) => _db.getUserById(id);

  @override
  Future<User?> getUserByEmail(String email) => _db.getUserByEmail(email);

  @override
  Future<bool> isEmailTaken(String email, {int? excludeUserId}) =>
      _db.isEmailTaken(email, excludeUserId: excludeUserId);

  @override
  Future<int> insertUser(User user) => _db.insertUser(user);

  @override
  Future<int> updateUser(User user) => _db.updateUser(user);

  @override
  Future<void> syncUserInAppointments(User user) =>
      _db.syncUserInAppointments(user);

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) =>
      _db.getProfessionalsBySpecialty(specialty);

  @override
  Future<List<Appointment>> getAppointments() => _db.getAppointments();

  @override
  Future<int> insertAppointment(Appointment appointment) =>
      _db.insertAppointment(appointment);

  @override
  Future<int> updateAppointment(Appointment appointment) =>
      _db.updateAppointment(appointment);

  @override
  Future<int> deleteAppointment(int id) => _db.deleteAppointment(id);
}
