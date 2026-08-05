import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/app_exception.dart';
import 'package:restorahub/models/appointment.dart';

void main() {
  group('AppointmentStatus', () {
    test('legacy cancelled maps to cancelledByCustomer', () {
      final map = {
        'service': 'Massage',
        'dateTime': DateTime(2026, 8, 1, 10, 0).toIso8601String(),
        'status': 'cancelled',
      };
      final appt = Appointment.fromMap(map);
      expect(appt.status, AppointmentStatus.cancelledByCustomer);
    });

    test('unknown status defaults to pending', () {
      final map = {
        'service': 'Massage',
        'dateTime': DateTime(2026, 8, 1, 10, 0).toIso8601String(),
        'status': 'unknown_status',
      };
      final appt = Appointment.fromMap(map);
      expect(appt.status, AppointmentStatus.pending);
    });
  });

  group('Appointment State Machine', () {
    late Appointment pendingAppt;
    late Appointment confirmedAppt;
    late Appointment completedAppt;
    late Appointment cancelledAppt;
    late Appointment noShowAppt;

    setUp(() {
      pendingAppt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.pending,
      );
      confirmedAppt = Appointment(
        id: '2',
        service: 'Facial',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.confirmed,
      );
      completedAppt = Appointment(
        id: '3',
        service: 'Spa',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.completed,
      );
      cancelledAppt = Appointment(
        id: '4',
        service: 'Haircut',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.cancelledByCustomer,
      );
      noShowAppt = Appointment(
        id: '5',
        service: 'Manicure',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.noShow,
      );
    });

    group('canTransitionTo', () {
      test('pending can transition to confirmed', () {
        expect(pendingAppt.canTransitionTo(AppointmentStatus.confirmed), isTrue);
      });

      test('pending can transition to cancelledByCustomer', () {
        expect(pendingAppt.canTransitionTo(AppointmentStatus.cancelledByCustomer), isTrue);
      });

      test('confirmed can transition to completed', () {
        expect(confirmedAppt.canTransitionTo(AppointmentStatus.completed), isTrue);
      });

      test('confirmed can transition to cancelledByProfessional', () {
        expect(confirmedAppt.canTransitionTo(AppointmentStatus.cancelledByProfessional), isTrue);
      });

      test('terminal statuses cannot transition to any other status', () {
        expect(completedAppt.canTransitionTo(AppointmentStatus.pending), isFalse);
        expect(cancelledAppt.canTransitionTo(AppointmentStatus.pending), isFalse);
        expect(noShowAppt.canTransitionTo(AppointmentStatus.pending), isFalse);
        expect(completedAppt.canTransitionTo(AppointmentStatus.cancelledByCustomer), isFalse);
      });

      test('same status transition is not allowed', () {
        expect(pendingAppt.canTransitionTo(AppointmentStatus.pending), isFalse);
      });
    });

    group('withStatus', () {
      test('valid transition succeeds', () {
        final updated = pendingAppt.withStatus(AppointmentStatus.confirmed);
        expect(updated.status, AppointmentStatus.confirmed);
      });

      test('invalid transition throws AppException', () {
        expect(
          () => completedAppt.withStatus(AppointmentStatus.pending),
          throwsA(isA<AppException>()),
        );
      });
    });

    group('isTerminal', () {
      test('pending is not terminal', () {
        expect(pendingAppt.isTerminal, isFalse);
      });

      test('completed is terminal', () {
        expect(completedAppt.isTerminal, isTrue);
      });

      test('cancelledByCustomer is terminal', () {
        expect(cancelledAppt.isTerminal, isTrue);
      });

      test('noShow is terminal', () {
        expect(noShowAppt.isTerminal, isTrue);
      });
    });

    group('isCancelled', () {
      test('cancelledByCustomer returns true', () {
        expect(cancelledAppt.isCancelled, isTrue);
      });

      test('cancelledByProfessional returns true', () {
        final appt = Appointment(
          id: '6',
          service: 'Massage',
          dateTime: DateTime(2026, 8, 1, 10, 0),
          status: AppointmentStatus.cancelledByProfessional,
        );
        expect(appt.isCancelled, isTrue);
      });

      test('pending returns false', () {
        expect(pendingAppt.isCancelled, isFalse);
      });
    });

    group('canBeCancelledByCustomer', () {
      test('terminal appointment cannot be cancelled', () {
        expect(completedAppt.canBeCancelledByCustomer(), isFalse);
        expect(cancelledAppt.canBeCancelledByCustomer(), isFalse);
      });

      test('appointment within 2-hour window cannot be cancelled', () {
        final soonAppt = Appointment(
          id: '7',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(soonAppt.canBeCancelledByCustomer(), isFalse);
      });

      test('appointment outside 2-hour window can be cancelled', () {
        final futureAppt = Appointment(
          id: '8',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
        );
        expect(futureAppt.canBeCancelledByCustomer(), isTrue);
      });
    });

    group('canBeRescheduled', () {
      test('terminal appointment cannot be rescheduled', () {
        expect(completedAppt.canBeRescheduled(), isFalse);
        expect(cancelledAppt.canBeRescheduled(), isFalse);
      });

      test('active appointment can be rescheduled', () {
        expect(pendingAppt.canBeRescheduled(), isTrue);
        expect(confirmedAppt.canBeRescheduled(), isTrue);
      });
    });

    group('toMap / fromMap roundtrip', () {
      test('all statuses roundtrip correctly', () {
        for (final status in AppointmentStatus.values) {
          final appt = Appointment(
            id: 'test',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: status,
          );
          final map = appt.toMap();
          final restored = Appointment.fromMap(map);
          expect(restored.status, status);
        }
      });
    });
  });
}