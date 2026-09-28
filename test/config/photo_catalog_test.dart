import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/brand_config.dart';
import 'package:restorahub/config/photo_catalog.dart';

void main() {
  group('photo catalog', () {
    test('massage names map to massage photo', () {
      expect(photoForService('Swedish Massage'), contains('massage-deep-tissue'));
      expect(photoForService('HOT STONE therapy'), contains('massage'));
    });

    test('facial, nails, hair map to their photos', () {
      expect(photoForService('HydraFacial'), contains('facial'));
      expect(photoForService('Gel Manicure'), contains('nails'));
      expect(photoForService('Balayage'), contains('hair'));
    });

    test('unknown service falls back to hero still-life', () {
      expect(photoForService('Quantum Alignment'), contains('hero-spa-still-life'));
    });

    test('staff avatars rotate deterministically', () {
      expect(staffAvatar(0), contains('staff-elena'));
      expect(staffAvatar(3), staffAvatar(0));
    });

    test('hero image is the still-life', () {
      expect(heroImage(), contains('hero-spa-still-life'));
    });

    test('photo override hit returns the override', () async {
      BrandConfig.setCurrentForTest(
        await BrandConfig.load(
          jsonString:
              '{"photoOverrides":{"swedish massage":"custom/massage.jpg","hero":"custom/hero.jpg","staff0":"custom/staff0.jpg"}}',
        ),
      );
      addTearDown(() async {
        BrandConfig.setCurrentForTest(
          await BrandConfig.load(jsonString: '{}'),
        );
      });
      expect(photoForService('Swedish Massage'), 'custom/massage.jpg');
      expect(heroImage(), 'custom/hero.jpg');
      expect(staffAvatar(0), 'custom/staff0.jpg');
    });

    test('photo override miss falls through to the catalog', () async {
      BrandConfig.setCurrentForTest(
        await BrandConfig.load(jsonString: '{"photoOverrides":{}}'),
      );
      addTearDown(() async {
        BrandConfig.setCurrentForTest(
          await BrandConfig.load(jsonString: '{}'),
        );
      });
      expect(
          photoForService('Swedish Massage'), contains('massage-deep-tissue'));
      expect(heroImage(), contains('hero-spa-still-life'));
      expect(staffAvatar(0), contains('staff-elena'));
    });
  });
}
