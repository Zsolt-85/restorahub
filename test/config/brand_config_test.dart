import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/brand_config.dart';

void main() {
  group('BrandConfig', () {
    test('defaults apply when JSON is absent', () async {
      final config = await BrandConfig.load(jsonString: null);
      expect(config.displayName, 'RestoraHub');
      expect(config.seedColorHex, '#2F5D50');
      expect(config.displayFont, 'Fraunces');
      expect(config.bodyFont, 'Inter');
      expect(config.photoOverride('massage'), isNull);
    });

    test('JSON values override defaults', () async {
      final config = await BrandConfig.load(
        jsonString:
            '{"displayName":"Restore by Maya","seedColor":"#6B3F2A"}',
      );
      expect(config.displayName, 'Restore by Maya');
      expect(config.seedColorHex, '#6B3F2A');
      expect(config.bodyFont, 'Inter');
    });

    test('malformed JSON falls back to defaults, never throws', () async {
      final config = await BrandConfig.load(jsonString: '{oops');
      expect(config.displayName, 'RestoraHub');
    });

    test('current defaults to compiled-in defaults', () {
      expect(BrandConfig.current.displayName, 'RestoraHub');
      expect(BrandConfig.current.seedColorHex, '#2F5D50');
      expect(BrandConfig.current.photoOverride('massage'), isNull);
    });

    test('setCurrentForTest round-trips custom config', () async {
      final custom = await BrandConfig.load(
        jsonString: '{"displayName":"Test Salon","seedColor":"#123456"}',
      );
      BrandConfig.setCurrentForTest(custom);
      addTearDown(() async {
        BrandConfig.setCurrentForTest(
          await BrandConfig.load(jsonString: '{}'),
        );
      });
      expect(BrandConfig.current.displayName, 'Test Salon');
      expect(BrandConfig.current.seedColorHex, '#123456');
    });
  });
}
