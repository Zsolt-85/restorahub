import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/salon_config.dart';

void main() {
  test('default business id is null until configured', () {
    expect(SalonConfig.defaultBusinessId, isNull);
  });
}
