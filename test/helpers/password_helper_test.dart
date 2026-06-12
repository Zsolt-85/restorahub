import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/password_helper.dart';

void main() {
  group('PasswordHelper', () {
    test('hash and verify work together', () {
      final hashed = PasswordHelper.hash('secret123');
      expect(PasswordHelper.isHashed(hashed), isTrue);
      expect(PasswordHelper.verify('secret123', hashed), isTrue);
      expect(PasswordHelper.verify('wrong', hashed), isFalse);
    });

    test('verify supports legacy plaintext passwords', () {
      expect(PasswordHelper.verify('legacy', 'legacy'), isTrue);
    });
  });
}
