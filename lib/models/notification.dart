enum NotificationType {
  bookingRequested,
  bookingConfirmed,
  bookingCancelled,
  bookingRescheduled,
  bookingCompleted,
  upcomingReminder,
}

enum NotificationStatus { unread, read, dismissed }

class AppNotification {
  String? id;
  NotificationType type;
  String title;
  String message;
  String? appointmentId;
  String receiverId;
  String senderId;
  NotificationStatus status;
  DateTime createdAt;
  String? businessId;
  String? businessName;

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    this.appointmentId,
    required this.receiverId,
    required this.senderId,
    this.status = NotificationStatus.unread,
    this.businessId,
    this.businessName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'appointmentId': appointmentId,
      'receiverId': receiverId,
      'senderId': senderId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'businessId': businessId,
      'businessName': businessName,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final typeRaw = map['type']?.toString();
    final statusRaw = map['status']?.toString();
    return AppNotification(
      id: map['id']?.toString(),
      type: NotificationType.values.firstWhere(
        (t) => t.name == typeRaw,
        orElse: () => NotificationType.bookingRequested,
      ),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      appointmentId: map['appointmentId']?.toString(),
      receiverId: map['receiverId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      status: statusRaw != null
          ? NotificationStatus.values.firstWhere(
              (s) => s.name == statusRaw,
              orElse: () => NotificationStatus.unread,
            )
          : NotificationStatus.unread,
      createdAt: _parseDateTime(map['createdAt']),
      businessId: map['businessId']?.toString(),
      businessName: map['businessName']?.toString(),
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

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? appointmentId,
    String? receiverId,
    String? senderId,
    NotificationStatus? status,
    DateTime? createdAt,
    String? businessId,
    String? businessName,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      appointmentId: appointmentId ?? this.appointmentId,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
    );
  }
}