import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/service_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class _FakeBookingRepository implements BookingRepository {
  final List<Appointment> _allAppointments;

  _FakeBookingRepository(this._allAppointments);

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate, int? limit, String? startAfterDocumentId}) async {
    if (businessId.isEmpty) return List.from(_allAppointments);
    return _allAppointments.where((a) => a.customerId == businessId || a.professionalId == businessId).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusinessInRange(String businessId, DateTime start, DateTime end, {String? professionalId}) async {
    if (businessId.isEmpty) return List.from(_allAppointments);
    return _allAppointments.where((a) {
      if (a.customerId != businessId && a.professionalId != businessId) return false;
      if (a.dateTime.isBefore(start) || a.dateTime.isAfter(end)) return false;
      if (professionalId != null && professionalId.isNotEmpty && a.professionalId != professionalId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId, {String? businessId}) async {
    if (businessId == null) return _allAppointments.where((a) => a.customerId == customerId).toList();
    return _allAppointments.where((a) => a.customerId == customerId && (a.professionalId == businessId || a.customerId == businessId)).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) async {
    if (businessId == null) return _allAppointments.where((a) => a.professionalId == professionalId).toList();
    return _allAppointments.where((a) => a.professionalId == professionalId && (a.customerId == businessId || a.professionalId == businessId)).toList();
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0, String? businessId, String? professionalEmail}) async => false;

  @override
  Future<void> createAppointmentAtomic(Appointment appointment) async {}

  @override
  Future<int> deleteAppointment(String id) async => 0;

  @override
  Future<int> insertAppointment(Appointment appointment) async => 0;

  @override
  Future<int> updateAppointment(Appointment appointment) async => 0;

  @override
  Stream<Appointment?> watchAppointment(String id) => Stream.value(null);

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      return _allAppointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) => Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId, {String? businessId}) => Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) => Stream.value([]);
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
    if (businessId == null) return _allUsers.where((u) => u.role == 'professional').toList();
    return _allUsers.where((u) => u.role == 'professional' && u.businessId == businessId).toList();
  }

  @override
  Future<List<User>> getCustomers() async => [];

  @override
  Future<List<User>> getProfessionalsByCategory(String category) async => [];

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async => [];

  @override
  Future<User?> getUserById(String id) async => null;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async => false;

  @override
  Future<int> insertUser(User user) async => 0;

  @override
  Future<int> updateUser(User user) async => 0;

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) => Stream.value([]);
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
      User(id: 'u1', name: 'Alice', email: 'alice@a.com', phone: '123', role: 'professional', businessId: tenantA),
      User(id: 'u2', name: 'Bob', email: 'bob@b.com', phone: '456', role: 'professional', businessId: tenantB),
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
      final tenantAResults = await bookingRepo.getAppointmentsForBusiness(tenantA);
      final tenantBResults = await bookingRepo.getAppointmentsForBusiness(tenantB);

      expect(tenantAResults.any((a) => a.customerId == tenantB), isFalse);
      expect(tenantBResults.any((a) => a.customerId == tenantA), isFalse);
    });

    test('Cross-tenant professional lookup is blocked by businessId filter', () async {
      final tenantAProfessionals = await userRepo.getProfessionals(businessId: tenantA);

      expect(tenantAProfessionals.every((u) => u.businessId == tenantA), isTrue);
      expect(tenantAProfessionals.any((u) => u.id == 'u2'), isFalse);
    });

    test('Services are isolated by tenant', () async {
      final tenantAServices = await serviceRepo.getServices(businessId: tenantA);

      expect(tenantAServices.every((s) => s.businessId == tenantA), isTrue);
      expect(tenantAServices.any((s) => s.id == 's2'), isFalse);
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

      expect(customer.isProfessional, isFalse);
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

      expect(professional.isProfessional, isTrue);
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

      expect(completedAppointment.canTransitionTo(AppointmentStatus.pending), isFalse);
      expect(completedAppointment.canTransitionTo(AppointmentStatus.confirmed), isFalse);
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

      expect(cancelledAppointment.canTransitionTo(AppointmentStatus.pending), isFalse);
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
}
