import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/semantic_color_helper.dart';

void main() {
  group('SemanticColorHelper', () {
    test('maps roles to color scheme without hardcoded colors', () {
      const scheme = ColorScheme.light();
      expect(SemanticColorHelper.errorOf(scheme), scheme.error);
      expect(SemanticColorHelper.successOf(scheme), scheme.secondary);
      expect(SemanticColorHelper.infoOf(scheme), scheme.primary);
      expect(SemanticColorHelper.warningOf(scheme), scheme.tertiary);
    });

    test('dark scheme resolves to dark roles, not hardcoded values', () {
      const scheme = ColorScheme.dark();
      expect(SemanticColorHelper.errorOf(scheme), scheme.error);
      expect(SemanticColorHelper.successOf(scheme), isNot(Colors.green));
    });
  });
}
