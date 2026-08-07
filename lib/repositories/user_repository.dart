import '../models/user.dart';

abstract class UserRepository {
  Future<User?> getUserById(String id);
  Future<bool> isEmailTaken(String email, {String? excludeUserId});
  Future<int> insertUser(User user);
  Future<int> updateUser(User user);
  Future<void> syncUserInAppointments(User user);
  Future<List<User>> getProfessionalsBySpecialty(String specialty);
}
