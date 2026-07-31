enum PaymentMethod { cash, card, transfer, other }
enum PaymentStatus { pending, completed, refunded }

class Payment {
  String? id;
  String appointmentId;
  String customerId;
  String customerName;
  String customerPhone;
  String customerEmail;
  String professionalId;
  String professionalName;
  String professionalPhone;
  String professionalEmail;
  String service;
  String specialty;
  DateTime appointmentDate;
  String appointmentTime;
  int appointmentDurationMinutes;
  double amount;
  String currency;
  PaymentMethod method;
  PaymentStatus status;
  bool receiptGenerated;

  Payment({
    this.id,
    required this.appointmentId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.professionalId,
    required this.professionalName,
    required this.professionalPhone,
    required this.professionalEmail,
    required this.service,
    required this.specialty,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentDurationMinutes,
    required this.amount,
    this.currency = 'EUR',
    this.method = PaymentMethod.cash,
    this.status = PaymentStatus.pending,
    this.receiptGenerated = false,
  });

  String get methodLabel {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'professionalPhone': professionalPhone,
      'professionalEmail': professionalEmail,
      'service': service,
      'specialty': specialty,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'appointmentDurationMinutes': appointmentDurationMinutes,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'receiptGenerated': receiptGenerated,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString(),
      appointmentId: map['appointmentId']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      customerEmail: map['customerEmail']?.toString() ?? '',
      professionalId: map['professionalId']?.toString() ?? '',
      professionalName: map['professionalName']?.toString() ?? '',
      professionalPhone: map['professionalPhone']?.toString() ?? '',
      professionalEmail: map['professionalEmail']?.toString() ?? '',
      service: map['service']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      appointmentDate: DateTime.parse(map['appointmentDate'] as String),
      appointmentTime: map['appointmentTime']?.toString() ?? '',
      appointmentDurationMinutes:
          map['appointmentDurationMinutes'] as int? ?? 60,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'EUR',
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == (map['method'] as String?),
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => PaymentStatus.pending,
      ),
      receiptGenerated: map['receiptGenerated'] as bool? ?? false,
    );
  }

  Payment copyWith({
    String? id,
    String? appointmentId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? professionalId,
    String? professionalName,
    String? professionalPhone,
    String? professionalEmail,
    String? service,
    String? specialty,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? appointmentDurationMinutes,
    double? amount,
    String? currency,
    PaymentMethod? method,
    PaymentStatus? status,
    bool? receiptGenerated,
  }) {
    return Payment(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalPhone: professionalPhone ?? this.professionalPhone,
      professionalEmail: professionalEmail ?? this.professionalEmail,
      service: service ?? this.service,
      specialty: specialty ?? this.specialty,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentDurationMinutes:
          appointmentDurationMinutes ?? this.appointmentDurationMinutes,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      receiptGenerated: receiptGenerated ?? this.receiptGenerated,
    );
  }
}