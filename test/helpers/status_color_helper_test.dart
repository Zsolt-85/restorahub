import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/status_color_helper.dart';
import 'package:restorahub/models/appointment.dart';

void main() {
  group('StatusColorHelper', () {
    const scheme = ColorScheme.light();

    test('maps every status to a theme role, never a hardcoded color', () {
      expect(StatusColorHelper.forStatus(AppointmentStatus.pending, scheme),
          scheme.tertiary);
      expect(StatusColorHelper.forStatus(AppointmentStatus.confirmed, scheme),
          scheme.primary);
      expect(StatusColorHelper.forStatus(AppointmentStatus.completed, scheme),
          scheme.secondary);
      expect(
          StatusColorHelper.forStatus(
              AppointmentStatus.cancelledByCustomer, scheme),
          scheme.error);
      expect(
          StatusColorHelper.forStatus(
              AppointmentStatus.cancelledByProfessional, scheme),
          scheme.error);
      expect(StatusColorHelper.forStatus(AppointmentStatus.noShow, scheme),
          scheme.onSurfaceVariant);
    });
  });
}
