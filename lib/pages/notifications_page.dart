import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/empty_state_widget.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      if (auth.currentUser != null) {
        final userId = auth.currentUser!.id;
        final businessId = businessProvider.currentBusiness?.id;
        if (userId != null) {
          notifProvider.loadNotifications(userId, businessId: businessId);
          notifProvider.startRealtimeNotifications(userId, businessId: businessId);
        }
      }
    });
  }

  @override
  void dispose() {
    Provider.of<NotificationProvider>(context, listen: false)
        .stopRealtimeNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.notifications ?? 'Notifications'),
        actions: [
          if (notifProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: AppLocalizations.of(context)?.ok ?? 'Mark all as read',
              onPressed: () {
                final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
                notifProvider.markAllAsRead(user.id!, businessId: businessProvider.currentBusiness?.id);
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              subtitle: 'Notifications about your appointments will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () {
                    notifProvider.markAsRead(notif.id!);
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.bookingRequested:
        return Icons.bookmark_add;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle;
      case NotificationType.bookingCancelled:
        return Icons.cancel;
      case NotificationType.bookingRescheduled:
        return Icons.swap_horiz;
      case NotificationType.bookingCompleted:
        return Icons.flag;
      case NotificationType.upcomingReminder:
        return Icons.alarm;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.bookingConfirmed:
        return Colors.green;
      case NotificationType.bookingCancelled:
        return Colors.red;
      case NotificationType.bookingCompleted:
        return Colors.blue;
      case NotificationType.upcomingReminder:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _iconColor.withValues(alpha: 0.1),
        child: Icon(_icon, color: _iconColor),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.status == NotificationStatus.unread
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
      subtitle: Text(notification.message),
      trailing: Text(
        _formatTime(notification.createdAt),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}