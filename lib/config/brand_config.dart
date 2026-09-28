import 'dart:convert';

import 'package:flutter/services.dart';

/// Brand configuration loaded from `assets/brand/maya.json`.
///
/// Pure config layer with compiled-in defaults: absent or malformed JSON
/// falls back to defaults and never throws.
class BrandConfig {
  final Map<String, dynamic> _json;

  const BrandConfig._(this._json);

  const BrandConfig._defaults() : _json = const <String, dynamic>{};

  static const assetPath = 'assets/brand/maya.json';

  static BrandConfig? _current;

  /// Runtime brand configuration, loaded once at startup in `main()`.
  /// Falls back to compiled-in defaults when startup has not run (tests).
  static BrandConfig get current =>
      _current ?? const BrandConfig._defaults();

  /// Test seam: installs a brand configuration for the current isolate.
  /// Reset with a defaults instance, e.g. `await BrandConfig.load(jsonString: '{}')`.
  static void setCurrentForTest(BrandConfig c) {
    _current = c;
  }

  /// Loads brand configuration.
  ///
  /// If [jsonString] is given it is parsed directly (used by tests).
  /// Otherwise `assets/brand/maya.json` is loaded via [bundle] (or
  /// `rootBundle` when null). Any failure falls back to defaults.
  static Future<BrandConfig> load({
    String? jsonString,
    AssetBundle? bundle,
  }) async {
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          return BrandConfig._(decoded);
        }
        if (decoded is Map) {
          return BrandConfig._(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        return const BrandConfig._(<String, dynamic>{});
      }
      return const BrandConfig._(<String, dynamic>{});
    }
    try {
      final source = bundle ?? rootBundle;
      final raw = await source.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return BrandConfig._(decoded);
      }
      if (decoded is Map) {
        return BrandConfig._(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return const BrandConfig._(<String, dynamic>{});
  }

  String get displayName => _json['displayName'] as String? ?? 'RestoraHub';

  String get tagline =>
      _json['tagline'] as String? ?? 'Beauty & wellness bookings';

  String get seedColorHex => _json['seedColor'] as String? ?? '#2F5D50';

  String get displayFont => _json['displayFont'] as String? ?? 'Fraunces';

  String get bodyFont => _json['bodyFont'] as String? ?? 'Inter';

  String? get address => _json['address'] as String?;

  String? get phone => _json['phone'] as String?;

  String? get hours => _json['hours'] as String?;

  String? photoOverride(String key) {
    final overrides = _json['photoOverrides'];
    if (overrides is Map) {
      final v = overrides[key];
      return v is String ? v : null;
    }
    return null;
  }
}
