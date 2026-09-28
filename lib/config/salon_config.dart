/// Salon-wide configuration for the white-label SaaS platform.
class SalonConfig {
  const SalonConfig._();

  /// Default business id used when the user has none.
  ///
  /// MAYA's id is filled when known. Null preserves current behavior
  /// (business-less users follow the existing setup/login path).
  static const String? defaultBusinessId = null;
}
