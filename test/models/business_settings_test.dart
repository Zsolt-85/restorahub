import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';

void main() {
  group('BusinessSettings policy fields', () {
    test('cancellation window defaults to 2 hours', () {
      expect(BusinessSettings().effectiveCancellationWindow,
          const Duration(hours: 2));
      expect(
          BusinessSettings(cancellationWindowHours: 24)
              .effectiveCancellationWindow,
          const Duration(hours: 24));
    });

    test('deposit percent clamps to 0-100', () {
      expect(BusinessSettings().effectiveDepositPercent, 0.0);
      expect(BusinessSettings(depositPercent: -5).effectiveDepositPercent, 0.0);
      expect(BusinessSettings(depositPercent: 250).effectiveDepositPercent,
          100.0);
      expect(BusinessSettings(depositPercent: 12.5).effectiveDepositPercent,
          12.5);
    });

    test('deposit is required only when enabled with a percent', () {
      expect(BusinessSettings().isDepositRequired, isFalse);
      expect(
          BusinessSettings(depositRequired: true).isDepositRequired, isFalse);
      expect(
          BusinessSettings(depositRequired: true, depositPercent: 10)
              .isDepositRequired,
          isTrue);
      expect(
          BusinessSettings(depositRequired: false, depositPercent: 10)
              .isDepositRequired,
          isFalse);
    });

    test('no-show fee defaults to zero and rejects negatives', () {
      expect(BusinessSettings().effectiveNoShowFee, 0.0);
      expect(BusinessSettings(noShowFeeAmount: -5).effectiveNoShowFee, 0.0);
      expect(BusinessSettings(noShowFeeAmount: 25).effectiveNoShowFee, 25.0);
    });

    test('fromMap/toMap round-trips policy fields', () {
      final settings = BusinessSettings(
        cancellationWindowHours: 24,
        depositRequired: true,
        depositPercent: 15.0,
        noShowFeeAmount: 20.0,
      );
      final restored = BusinessSettings.fromMap(settings.toMap());

      expect(restored.cancellationWindowHours, 24);
      expect(restored.isDepositRequired, isTrue);
      expect(restored.effectiveDepositPercent, 15.0);
      expect(restored.effectiveNoShowFee, 20.0);
    });

    test('fromMap tolerates legacy documents without policy fields', () {
      final restored = BusinessSettings.fromMap({});

      expect(restored.effectiveCancellationWindow,
          const Duration(hours: 2));
      expect(restored.isDepositRequired, isFalse);
      expect(restored.effectiveNoShowFee, 0.0);
    });
  });
}
