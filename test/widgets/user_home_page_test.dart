import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/pages/user_home_page.dart';

void main() {
  group('home greeting helpers', () {
    test('greetingForHour covers day parts', () {
      expect(greetingForHour(8), 'Good morning');
      expect(greetingForHour(14), 'Good afternoon');
      expect(greetingForHour(20), 'Good evening');
    });

    test('firstName takes first token', () {
      expect(firstName('Maya Papadopoulos'), 'Maya');
      expect(firstName('  '), '');
    });
  });
}
