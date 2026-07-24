class Appointment {
  String? id;
  String service;
  DateTime dateTime;
  int durationMinutes;

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
    required this.service,
    required this.dateTime,
    this.durationMinutes = 60,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'dateTime': dateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
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
    final service = (type != null &&
            type.isNotEmpty &&
            type != 'Default' &&
            type != 'Standard' &&
            !rawService.contains('—'))
        ? '$rawService — $type'
        : rawService;

    return Appointment(
      id: map['id']?.toString(),
      service: service,
      dateTime: DateTime.parse(map['dateTime'] as String),
      durationMinutes: map['durationMinutes'] as int? ?? 60,
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
    String? service,
    DateTime? dateTime,
    int? durationMinutes,
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
      service: service ?? this.service,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
