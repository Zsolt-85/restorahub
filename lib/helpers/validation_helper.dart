class ValidationHelper {
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7;
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Name is required';
    return null;
  }

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(email)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePhone(String phone) {
    if (phone.trim().isEmpty) return 'Phone number is required';
    if (!isValidPhone(phone)) return 'Enter a valid phone number';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
