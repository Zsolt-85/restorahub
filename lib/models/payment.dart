enum PaymentMethod { cash, card, transfer, other }

enum PaymentStatus { pending, completed, refunded }

class Payment {
  final String? id;
  final String appointmentId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String professionalId;
  final String professionalName;
  final String professionalPhone;
  final String professionalEmail;
  final String service;
  final String staffCategory;
  final String? businessId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int appointmentDurationMinutes;
  final double amount;
  final double depositAmount;
  final double noShowFee;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final bool receiptGenerated;

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
    required this.staffCategory,
    this.businessId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentDurationMinutes,
    required this.amount,
    this.depositAmount = 0.0,
    this.noShowFee = 0.0,
    this.currency = 'EUR',
    this.method = PaymentMethod.cash,
    this.status = PaymentStatus.pending,
    this.receiptGenerated = false,
  });

  /// Remaining balance after any deposit. Never negative.
  double get balanceDue {
    final balance = amount - depositAmount;
    return balance < 0 ? 0 : balance;
  }

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
      'staffCategory': staffCategory,
      'specialty': staffCategory,
      'businessId': businessId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'appointmentDurationMinutes': appointmentDurationMinutes,
      'amount': amount,
      'depositAmount': depositAmount,
      'noShowFee': noShowFee,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'receiptGenerated': receiptGenerated,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    final staffCategoryValue = map['staffCategory']?.toString() ?? '';
    final legacySpecialty = map['specialty']?.toString() ?? '';
    final resolvedStaffCategory =
        staffCategoryValue.isNotEmpty ? staffCategoryValue : legacySpecialty;

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
      staffCategory: resolvedStaffCategory,
      businessId: map['businessId']?.toString(),
      appointmentDate: _parseDateTime(map['appointmentDate']),
      appointmentTime: map['appointmentTime']?.toString() ?? '',
      appointmentDurationMinutes:
          map['appointmentDurationMinutes'] as int? ?? 60,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0.0,
      noShowFee: (map['noShowFee'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'EUR',
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == map['method']?.toString(),
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status']?.toString(),
        orElse: () => PaymentStatus.pending,
      ),
      receiptGenerated: map['receiptGenerated'] as bool? ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
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
    String? staffCategory,
    @Deprecated('Use staffCategory instead') String? specialty,
    String? businessId,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? appointmentDurationMinutes,
    double? amount,
    double? depositAmount,
    double? noShowFee,
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
      staffCategory: staffCategory ?? specialty ?? this.staffCategory,
      businessId: businessId ?? this.businessId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentDurationMinutes:
          appointmentDurationMinutes ?? this.appointmentDurationMinutes,
      amount: amount ?? this.amount,
      depositAmount: depositAmount ?? this.depositAmount,
      noShowFee: noShowFee ?? this.noShowFee,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      receiptGenerated: receiptGenerated ?? this.receiptGenerated,
    );
  }
}
