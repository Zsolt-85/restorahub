import 'package:flutter/material.dart';

import '../models/appointment.dart';

/// Single source for appointment-status colors. Hues follow Material roles
/// so white-label themes recolor statuses automatically; never hardcode
/// Colors.orange/green/blue/red/grey at call sites.
class StatusColorHelper {
  static Color forStatus(AppointmentStatus status, ColorScheme scheme) {
    switch (status) {
      case AppointmentStatus.pending:
        return scheme.tertiary;
      case AppointmentStatus.confirmed:
        return scheme.primary;
      case AppointmentStatus.completed:
        return scheme.secondary;
      case AppointmentStatus.cancelledByCustomer:
      case AppointmentStatus.cancelledByProfessional:
        return scheme.error;
      case AppointmentStatus.noShow:
        return scheme.onSurfaceVariant;
    }
  }
}
