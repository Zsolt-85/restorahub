import 'package:restorahub/exceptions/app_exception.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelledByCustomer, cancelledByProfessional, noShow }

extension AppointmentStatusLabel on AppointmentStatus {
  String get displayLabel {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelledByCustomer:
        return 'Cancelled by Customer';
      case AppointmentStatus.cancelledByProfessional:
        return 'Declined';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

class Appointment {
  String? id;
  String service;
  DateTime dateTime;
  int durationMinutes;
  AppointmentStatus status;
  String? paymentId;

  String? customerId;
  String? customerName;
  String? customerPhone;
  String? customerEmail;

  String? professionalId;
  String? professionalName;
  String? professionalPhone;
  String? professionalEmail;

  Appointment({
    this.id,
    this.paymentId,
    required this.service,
    required this.dateTime,
    this.durationMinutes = 60,
    this.status = AppointmentStatus.pending,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.professionalId,
    this.professionalName,
    this.professionalPhone,
    this.professionalEmail,
  });

  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));

  bool get isPast => dateTime.isBefore(DateTime.now());

  static const _terminalStatuses = {
    AppointmentStatus.completed,
    AppointmentStatus.cancelledByCustomer,
    AppointmentStatus.cancelledByProfessional,
    AppointmentStatus.noShow,
  };

  static const _cancelledStatuses = {
    AppointmentStatus.cancelledByCustomer,
    AppointmentStatus.cancelledByProfessional,
  };

  bool get isTerminal => _terminalStatuses.contains(status);

  bool get isCancelled => _cancelledStatuses.contains(status);

  bool canTransitionTo(AppointmentStatus newStatus) {
    if (isTerminal) return false;
    if (newStatus == status) return false;
    return true;
  }

  bool canBeCancelledByCustomer({Duration cancellationWindow = const Duration(hours: 2)}) {
    if (isTerminal) return false;
    if (isCancelled) return false;
    final now = DateTime.now();
    final timeUntilStart = dateTime.difference(now);
    return timeUntilStart > cancellationWindow;
  }

  bool canBeCancelled() => canBeCancelledByCustomer();

  bool canBeRescheduled() {
    if (isTerminal) return false;
    if (isCancelled) return false;
    return true;
  }

  Appointment withStatus(AppointmentStatus newStatus) {
    if (!canTransitionTo(newStatus)) {
      throw AppException(
        'Invalid status transition from ${status.name} to ${newStatus.name}',
      );
    }
    return copyWith(status: newStatus);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'service': service,
      'dateTime': dateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'professionalPhone': professionalPhone,
      'professionalEmail': professionalEmail,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final rawService = map['service'] as String;
    final type = map['type'] as String?;
    String service;
    if (type != null && type.isNotEmpty && type != 'Default' && type != 'Standard') {
      service = '$rawService \u2014 $type';
    } else {
      service = rawService;
    }

    final statusRaw = map['status'] as String?;
    AppointmentStatus status;
    if (statusRaw == null) {
      status = AppointmentStatus.pending;
    } else if (statusRaw == 'cancelled') {
      status = AppointmentStatus.cancelledByCustomer;
    } else {
      status = AppointmentStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => AppointmentStatus.pending,
      );
    }

    return Appointment(
      id: map['id']?.toString(),
      paymentId: map['paymentId']?.toString(),
      service: service,
      dateTime: DateTime.parse(map['dateTime'] as String),
      durationMinutes: map['durationMinutes'] as int? ?? 60,
      status: status,
      customerId: map['customerId']?.toString(),
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerEmail: map['customerEmail'] as String?,
      professionalId: map['professionalId']?.toString(),
      professionalName: map['professionalName'] as String?,
      professionalPhone: map['professionalPhone'] as String?,
      professionalEmail: map['professionalEmail'] as String?,
    );
  }

  Appointment copyWith({
    String? id,
    String? paymentId,
    String? service,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentStatus? status,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? professionalId,
    String? professionalName,
    String? professionalPhone,
    String? professionalEmail,
  }) {
    return Appointment(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      service: service ?? this.service,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalPhone: professionalPhone ?? this.professionalPhone,
      professionalEmail: professionalEmail ?? this.professionalEmail,
    );
  }
}
