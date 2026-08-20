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
    final typeRaw = map['type'] as String;
    final statusRaw = map['status'] as String?;
    return AppNotification(
      id: map['id']?.toString(),
      type: NotificationType.values.firstWhere((t) => t.name == typeRaw),
      title: map['title'] as String,
      message: map['message'] as String,
      appointmentId: map['appointmentId']?.toString(),
      receiverId: map['receiverId'] as String,
      senderId: map['senderId'] as String,
      status: statusRaw != null
          ? NotificationStatus.values.firstWhere(
              (s) => s.name == statusRaw,
              orElse: () => NotificationStatus.unread,
            )
          : NotificationStatus.unread,
      createdAt: DateTime.parse(map['createdAt'] as String),
      businessId: map['businessId']?.toString(),
      businessName: map['businessName']?.toString(),
    );
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