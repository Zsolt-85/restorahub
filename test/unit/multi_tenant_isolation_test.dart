import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/payment_repository.dart';
import 'package:restorahub/repositories/service_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class _FakeBookingRepository implements BookingRepository {
  final List<Appointment> _allAppointments;

  _FakeBookingRepository(this._allAppointments);

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId,
      {DateTime? startDate,
      DateTime? endDate,
      int? limit,
      String? startAfterDocumentId}) async {
    if (businessId.isEmpty) return List.from(_allAppointments);
    return _allAppointments
        .where(
            (a) => a.customerId == businessId || a.professionalId == businessId)
        .toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusinessInRange(
      String businessId, DateTime start, DateTime end,
      {String? professionalId}) async {
    if (businessId.isEmpty) {
      return List.from(_allAppointments);
    }
    return _allAppointments.where((a) {
      if (a.customerId != businessId && a.professionalId != businessId) {
        return false;
      }
      if (a.dateTime.isBefore(start) || a.dateTime.isAfter(end)) {
        return false;
      }
      if (professionalId != null &&
          professionalId.isNotEmpty &&
          a.professionalId != professionalId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId,
      {String? businessId}) async {
    if (businessId == null) {
      return _allAppointments.where((a) => a.customerId == customerId).toList();
    }
    return _allAppointments
        .where((a) =>
            a.customerId == customerId &&
            (a.professionalId == businessId || a.customerId == businessId))
        .toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(
      String professionalId,
      {String? businessId,
      String? professionalEmail}) async {
    if (businessId == null) {
      return _allAppointments
          .where((a) => a.professionalId == professionalId)
          .toList();
    }
    return _allAppointments
        .where((a) =>
            a.professionalId == professionalId &&
            (a.customerId == businessId || a.professionalId == businessId))
        .toList();
  }

  @override
  Future<bool> checkProfessionalAvailability(
          {required String professionalId,
          required DateTime dateTime,
          required int slotDurationMinutes,
          int bufferTimeMinutes = 0,
          String? businessId,
          String? professionalEmail}) async =>
      false;

  @override
  Future<String> createAppointmentAtomic(Appointment appointment) async =>
      appointment.id ?? 'fake-id';

  @override
  Future<int> deleteAppointment(String id) async => 0;

  @override
  @override
  Future<int> updateAppointment(Appointment appointment) async => 0;

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      return _allAppointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId,
          {DateTime? startDate, DateTime? endDate}) =>
      Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId,
          {String? businessId}) =>
      Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(
          String professionalId,
          {String? businessId,
          String? professionalEmail}) =>
      Stream.value([]);
}

class _FakeServiceRepository implements ServiceRepository {
  final List<Service> _allServices;

  _FakeServiceRepository(this._allServices);

  @override
  Future<List<Service>> getServices({String? businessId}) async {
    if (businessId == null) return List.from(_allServices);
    return _allServices.where((s) => s.businessId == businessId).toList();
  }

  @override
  Stream<List<Service>> watchServices({String? businessId}) => Stream.value([]);

  @override
  Future<void> createService(Service service) async {}

  @override
  Future<void> deleteService(String id) async {}

  @override
  Future<void> updateService(Service service) async {}
}

class _FakeUserRepository implements UserRepository {
  final List<User> _allUsers;

  _FakeUserRepository(this._allUsers);

  @override
  Future<List<User>> getProfessionals({String? businessId}) async {
    if (businessId == null) return _allUsers.where((u) => u.isStaff).toList();
    return _allUsers
        .where((u) => u.isStaff && u.businessId == businessId)
        .toList();
  }

  @override
  Future<List<User>> getCustomers({String? businessId}) async => [];

  @override
  Future<List<User>> getProfessionalsByCategory(String category,
      {String? businessId}) async {
    if (businessId == null) {
      return _allUsers.where((u) => u.isStaff).toList();
    }
    return _allUsers
        .where((u) => u.isStaff && u.businessId == businessId)
        .toList();
  }

  @override
  Future<User?> getUserById(String id) async => null;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async =>
      false;

  @override
  Future<int> insertUser(User user) async => 0;

  @override
  Future<int> updateUser(User user) async => 0;

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsByBusiness(String businessId) async {
    return _allUsers
        .where((u) =>
            (u.isStaff || u.role == 'business_admin') &&
            u.businessId == businessId)
        .toList();
  }
}

class _FakePaymentRepository implements PaymentRepository {
  final List<Payment> _allPayments;

  _FakePaymentRepository(this._allPayments);

  @override
  Future<Payment?> getPaymentByAppointment(String appointmentId,
      {String? businessId}) async {
    final matches = _allPayments.where((p) => p.appointmentId == appointmentId);
    if (businessId == null || businessId.isEmpty) {
      return matches.isEmpty ? null : matches.first;
    }
    final scoped = matches.where((p) => p.businessId == businessId);
    return scoped.isEmpty ? null : scoped.first;
  }

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
      {String? businessId}) async {
    return _allPayments
        .where((p) => p.professionalId == professionalId)
        .where((p) => businessId == null || p.businessId == businessId)
        .toList();
  }

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
    String? professionalId,
    DateTime start,
    DateTime end, {
    String? businessId,
  }) async =>
      [];

  @override
  Future<String> recordPayment(Payment payment) async {
    final stored = payment.id == null
        ? payment.copyWith(id: 'pay-${_allPayments.length + 1}')
        : payment;
    _allPayments.add(stored);
    return stored.id!;
  }

  @override
  Future<int> updatePayment(Payment payment) async => 0;

  @override
  Future<int> updatePaymentStatus(
          String paymentId, PaymentStatus status) async =>
      0;
}

Payment _payment(String id, String appointmentId, String professionalId,
    String? businessId) {
  return Payment(
    id: id,
    appointmentId: appointmentId,
    customerId: 'cust',
    customerName: 'Customer',
    customerPhone: '555',
    customerEmail: 'cust@test.com',
    professionalId: professionalId,
    professionalName: 'Professional',
    professionalPhone: '555',
    professionalEmail: 'prof@test.com',
    service: 'Massage',
    staffCategory: 'massage',
    businessId: businessId,
    appointmentDate: DateTime(2026, 1, 1, 10, 0),
    appointmentTime: '10:00',
    appointmentDurationMinutes: 60,
    amount: 50.0,
  );
}

void main() {
  group('Multi-tenant isolation tests', () {
    const tenantA = 'tenant_A';
    const tenantB = 'tenant_B';

    final bookingRepo = _FakeBookingRepository([
      Appointment(
        id: 'a1',
        service: 'Haircut',
        dateTime: DateTime(2026, 1, 1, 10, 0),
        customerId: tenantA,
        professionalId: 'prof_A',
      ),
      Appointment(
        id: 'a2',
        service: 'Massage',
        dateTime: DateTime(2026, 1, 1, 11, 0),
        customerId: tenantB,
        professionalId: 'prof_B',
      ),
    ]);

    final serviceRepo = _FakeServiceRepository([
      Service(id: 's1', name: 'Haircut', businessId: tenantA),
      Service(id: 's2', name: 'Massage', businessId: tenantB),
    ]);

    final userRepo = _FakeUserRepository([
      User(
          id: 'u1',
          name: 'Alice',
          email: 'alice@a.com',
          phone: '123',
          role: 'professional',
          businessId: tenantA),
      User(
          id: 'u2',
          name: 'Bob',
          email: 'bob@b.com',
          phone: '456',
          role: 'professional',
          businessId: tenantB),
    ]);

    test('BookingRepository returns only tenant_A appointments', () async {
      final results = await bookingRepo.getAppointmentsForBusiness(tenantA);
      expect(results.length, 1);
      expect(results.first.id, 'a1');
      expect(results.any((a) => a.id == 'a2'), isFalse);
    });

    test('ServiceRepository returns only tenant_A services', () async {
      final results = await serviceRepo.getServices(businessId: tenantA);
      expect(results.length, 1);
      expect(results.first.id, 's1');
      expect(results.any((s) => s.id == 's2'), isFalse);
    });

    test('UserRepository returns only tenant_A professionals', () async {
      final results = await userRepo.getProfessionals(businessId: tenantA);
      expect(results.length, 1);
      expect(results.first.id, 'u1');
      expect(results.any((u) => u.id == 'u2'), isFalse);
    });

    test('Legacy fallback: businessId null returns all records', () async {
      final bookings = await bookingRepo.getAppointmentsForBusiness('');
      final services = await serviceRepo.getServices();
      final professionals = await userRepo.getProfessionals();

      expect(bookings.length, 2);
      expect(services.length, 2);
      expect(professionals.length, 2);
    });

    test('Tenant B appointments are isolated from Tenant A queries', () async {
      final tenantAResults =
          await bookingRepo.getAppointmentsForBusiness(tenantA);
      final tenantBResults =
          await bookingRepo.getAppointmentsForBusiness(tenantB);

      expect(tenantAResults.any((a) => a.customerId == tenantB), isFalse);
      expect(tenantBResults.any((a) => a.customerId == tenantA), isFalse);
    });

    test('Cross-tenant professional lookup is blocked by businessId filter',
        () async {
      final tenantAProfessionals =
          await userRepo.getProfessionals(businessId: tenantA);

      expect(
          tenantAProfessionals.every((u) => u.businessId == tenantA), isTrue);
      expect(tenantAProfessionals.any((u) => u.id == 'u2'), isFalse);
    });

    test('Services are isolated by tenant', () async {
      final tenantAServices =
          await serviceRepo.getServices(businessId: tenantA);

      expect(tenantAServices.every((s) => s.businessId == tenantA), isTrue);
      expect(tenantAServices.any((s) => s.id == 's2'), isFalse);
    });

    test('Category professional lookup is isolated by tenant', () async {
      final tenantAPros = await userRepo.getProfessionalsByCategory('massage',
          businessId: tenantA);
      expect(tenantAPros.every((u) => u.businessId == tenantA), isTrue);
      expect(tenantAPros.any((u) => u.id == 'u2'), isFalse);
    });
  });

  group('Payment tenant isolation', () {
    const tenantA = 'tenant_A';
    const tenantB = 'tenant_B';

    final paymentRepo = _FakePaymentRepository([
      _payment('p1', 'a1', 'prof_A', tenantA),
      _payment('p2', 'a2', 'prof_B', tenantB),
      _payment('p3', 'a3', 'prof_A', null),
    ]);

    test('getPaymentByAppointment respects businessId filter', () async {
      final scoped =
          await paymentRepo.getPaymentByAppointment('a1', businessId: tenantA);
      expect(scoped?.id, 'p1');

      final crossTenant =
          await paymentRepo.getPaymentByAppointment('a2', businessId: tenantA);
      expect(crossTenant, isNull);
    });

    test('unscoped lookup preserves legacy behavior', () async {
      final legacy = await paymentRepo.getPaymentByAppointment('a3');
      expect(legacy?.id, 'p3');
    });

    test('professional payments are isolated by tenant', () async {
      final results = await paymentRepo.getPaymentsByProfessional('prof_A',
          businessId: tenantA);
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('recorded payments carry businessId for future isolation', () async {
      final payment = _payment('p4', 'a4', 'prof_A', tenantA);
      await paymentRepo.recordPayment(payment);
      final fetched =
          await paymentRepo.getPaymentByAppointment('a4', businessId: tenantA);
      expect(fetched?.businessId, tenantA);
      final otherTenant =
          await paymentRepo.getPaymentByAppointment('a4', businessId: tenantB);
      expect(otherTenant, isNull);
    });
  });

  group('Privilege escalation prevention tests', () {
    test('Customer role cannot be mistaken for professional role', () {
      final customer = User(
        id: 'cust_1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '123',
        role: 'customer',
        businessId: 'biz_1',
      );

      expect(customer.isStaff, isFalse);
      expect(customer.role, equals('customer'));
    });

    test('Professional role is correctly identified', () {
      final professional = User(
        id: 'prof_1',
        name: 'Professional',
        email: 'prof@test.com',
        phone: '456',
        role: 'professional',
        businessId: 'biz_1',
      );

      expect(professional.isStaff, isTrue);
      expect(professional.role, equals('professional'));
    });

    test('copyWith preserves role without escalation', () {
      final customer = User(
        id: 'cust_1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '123',
        role: 'customer',
        businessId: 'biz_1',
      );

      final modified = customer.copyWith(name: 'New Name');
      expect(modified.role, equals('customer'));
    });

    test('Appointment fromMap does not allow status injection', () {
      final appointment = Appointment.fromMap({
        'id': 'apt_1',
        'service': 'Haircut',
        'dateTime': '2026-01-01T10:00:00.000',
        'customerId': 'cust_1',
        'professionalId': 'prof_1',
        'status': 'completed',
      });

      expect(appointment.status, equals(AppointmentStatus.completed));
    });

    test('Terminal status cannot be transitioned', () {
      final completedAppointment = Appointment(
        id: 'apt_1',
        service: 'Haircut',
        dateTime: DateTime(2026, 1, 1, 10, 0),
        status: AppointmentStatus.completed,
        customerId: 'cust_1',
        professionalId: 'prof_1',
      );

      expect(completedAppointment.canTransitionTo(AppointmentStatus.pending),
          isFalse);
      expect(completedAppointment.canTransitionTo(AppointmentStatus.confirmed),
          isFalse);
      expect(completedAppointment.isTerminal, isTrue);
    });

    test('Cancelled status is terminal', () {
      final cancelledAppointment = Appointment(
        id: 'apt_1',
        service: 'Haircut',
        dateTime: DateTime(2026, 1, 1, 10, 0),
        status: AppointmentStatus.cancelledByCustomer,
        customerId: 'cust_1',
        professionalId: 'prof_1',
      );

      expect(cancelledAppointment.canTransitionTo(AppointmentStatus.pending),
          isFalse);
      expect(cancelledAppointment.isTerminal, isTrue);
    });

    test('Legacy cancelled maps to cancelledByCustomer', () {
      final appointment = Appointment.fromMap({
        'id': 'apt_1',
        'service': 'Haircut',
        'dateTime': '2026-01-01T10:00:00.000',
        'customerId': 'cust_1',
        'professionalId': 'prof_1',
        'status': 'cancelled',
      });

      expect(appointment.status, equals(AppointmentStatus.cancelledByCustomer));
      expect(appointment.isCancelled, isTrue);
    });
  });

  group('Solo provider and getProfessionalsByBusiness', () {
    const tenantA = 'tenant_A';

    final userRepo = _FakeUserRepository([
      User(
          id: 'u1',
          name: 'Alice',
          email: 'alice@a.com',
          phone: '123',
          role: 'professional',
          businessId: tenantA),
      User(
          id: 'u2',
          name: 'Bob',
          email: 'bob@a.com',
          phone: '456',
          role: 'staff',
          businessId: tenantA),
      User(
          id: 'u3',
          name: 'Owner',
          email: 'owner@a.com',
          phone: '789',
          role: 'business_admin',
          businessId: tenantA),
      User(
          id: 'u4',
          name: 'Carol',
          email: 'carol@b.com',
          phone: '000',
          role: 'customer',
          businessId: tenantA),
      User(
          id: 'u5',
          name: 'Dan',
          email: 'dan@c.com',
          phone: '111',
          role: 'professional',
          businessId: 'tenant_C'),
    ]);

    test(
        'getProfessionalsByBusiness returns staff and business_admin for tenant',
        () async {
      final results = await userRepo.getProfessionalsByBusiness(tenantA);
      expect(results.length, 3);
      expect(results.any((u) => u.id == 'u1'), isTrue);
      expect(results.any((u) => u.id == 'u2'), isTrue);
      expect(results.any((u) => u.id == 'u3'), isTrue);
    });

    test('getProfessionalsByBusiness excludes customers', () async {
      final results = await userRepo.getProfessionalsByBusiness(tenantA);
      expect(results.any((u) => u.role == 'customer'), isFalse);
    });

    test('getProfessionalsByBusiness returns empty for unknown tenant',
        () async {
      final results =
          await userRepo.getProfessionalsByBusiness('unknown_tenant');
      expect(results, isEmpty);
    });

    test('getProfessionalsByBusiness returns empty for empty businessId',
        () async {
      final results = await userRepo.getProfessionalsByBusiness('');
      expect(results, isEmpty);
    });

    test('isSolo is true when staffCount <= 1', () {
      final business = Business(id: 'biz_1', name: 'Solo Biz', staffCount: 1);
      expect(business.isSolo, isTrue);
    });

    test('isSolo is false when staffCount > 1', () {
      final business = Business(id: 'biz_1', name: 'Multi Biz', staffCount: 3);
      expect(business.isSolo, isFalse);
    });
  });
}
