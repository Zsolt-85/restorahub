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

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    this.appointmentId,
    required this.receiverId,
    required this.senderId,
    this.status = NotificationStatus.unread,
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
    );
  }
}