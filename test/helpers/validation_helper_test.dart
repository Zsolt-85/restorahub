import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/validation_helper.dart';

void main() {
  group('ValidationHelper', () {
    test('validateEmail rejects invalid addresses', () {
      expect(ValidationHelper.validateEmail(''), isNotNull);
      expect(ValidationHelper.validateEmail('bad-email'), isNotNull);
      expect(ValidationHelper.validateEmail('user@example.com'), isNull);
    });

    test('validatePhone requires enough digits', () {
      expect(ValidationHelper.validatePhone('123'), isNotNull);
      expect(ValidationHelper.validatePhone('+1 555 123 4567'), isNull);
    });

    test('validatePassword enforces minimum length', () {
      expect(ValidationHelper.validatePassword('123'), isNotNull);
      expect(ValidationHelper.validatePassword('123456'), isNull);
    });
  });
}
