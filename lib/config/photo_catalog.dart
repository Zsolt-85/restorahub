import 'brand_config.dart';

const _massage = 'assets/images/stock/massage-deep-tissue.jpg';
const _hero = 'assets/images/stock/hero-spa-still-life.jpg';
const _facial = 'assets/images/stock/facial-hydra.jpg';
const _nails = 'assets/images/stock/nails-gel.jpg';
const _hair = 'assets/images/stock/hair-stylist-work.jpg';

const _staff = [
  'assets/images/stock/staff-elena.jpg',
  'assets/images/stock/staff-sofia.jpg',
  'assets/images/stock/staff-ana.jpg',
];

String photoForService(String serviceName) {
  final override =
      BrandConfig.current.photoOverride(serviceName.toLowerCase());
  if (override != null && override.isNotEmpty) return override;
  final s = serviceName.toLowerCase();
  if (s.contains('massag') || s.contains('stone')) return _massage;
  if (s.contains('facial') || s.contains('skin') || s.contains('peel')) return _facial;
  if (s.contains('nail') || s.contains('manicure') || s.contains('pedicure')) return _nails;
  if (s.contains('hair') || s.contains('cut') || s.contains('color') || s.contains('balayage')) return _hair;
  if (s.contains('aroma') || s.contains('oil')) {
    return 'assets/images/stock/aromatherapy-oils.jpg';
  }
  return _hero;
}

String staffAvatar(int index) {
  final override = BrandConfig.current.photoOverride('staff$index');
  if (override != null && override.isNotEmpty) return override;
  return _staff[index % _staff.length];
}

String heroImage() {
  final override = BrandConfig.current.photoOverride('hero');
  if (override != null && override.isNotEmpty) return override;
  return _hero;
}
