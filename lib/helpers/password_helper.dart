import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHelper {
  static const _prefix = 'sha256:';

  static String hash(String password) {
    final salt = _generateSalt();
    return '$_prefix$salt:${_digest(salt, password)}';
  }

  static bool verify(String password, String stored) {
    if (isHashed(stored)) {
      final body = stored.substring(_prefix.length);
      final parts = body.split(':');
      if (parts.length != 2) return false;
      return _digest(parts[0], password) == parts[1];
    }

    // Support existing accounts created before hashing was added.
    return stored.trim() == password.trim();
  }

  static bool isHashed(String stored) => stored.startsWith(_prefix);

  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _digest(String salt, String password) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }
}
