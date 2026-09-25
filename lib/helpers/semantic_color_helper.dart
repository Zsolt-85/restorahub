import 'package:flutter/material.dart';

/// Semantic surfaces derived from [ColorScheme] roles so white-label
/// themes recolor feedback automatically; never hardcode
/// Colors.red/green/blue/amber at call sites.
class SemanticColorHelper {
  static Color errorOf(ColorScheme scheme) => scheme.error;
  static Color successOf(ColorScheme scheme) => scheme.secondary;
  static Color infoOf(ColorScheme scheme) => scheme.primary;
  static Color warningOf(ColorScheme scheme) => scheme.tertiary;
}
