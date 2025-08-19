import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import '../theme.dart';

/// Widget d'affichage des notifications push
class PushNotificationsWidget extends StatefulWidget {
  const PushNotificationsWidget({super.key});

  @override
  State<PushNotificationsWidget> createState() => _PushNotificationsWidgetState();
}

class _PushNotificationsWidgetState extends State<PushNotificationsWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PushNotificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement des notifications',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final type = data['type'] as String? ?? 'general';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNotificationIcon(type),
            color: _getNotificationColor(type),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: body.isNotEmpty
            ? Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              )
            : null,
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment':
        return Colors.blue;
      case 'service':
        return Colors.green;
      case 'event':
        return Colors.orange;
      case 'bible_study':
        return Colors.purple;
      case 'urgent':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'service':
        return Icons.work;
      case 'event':
        return Icons.event;
      case 'bible_study':
        return Icons.book;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final type = data['type'] as String? ?? '';
    
    // Marquer comme lue si pas encore lue
    if (!(notification['isRead'] as bool? ?? false)) {
      // TODO: Implémenter le marquage comme lue
    }

    // Navigation basée sur le type
    switch (type) {
      case 'appointment':
        _navigateToAppointments();
        break;
      case 'service':
        _navigateToServices();
        break;
      case 'event':
        _navigateToEvents();
        break;
      case 'bible_study':
        _navigateToBibleStudy();
        break;
      default:
        break;
    }
  }

  void _navigateToAppointments() {
    // TODO: Implémenter la navigation vers les rendez-vous
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les rendez-vous')),
    );
  }

  void _navigateToServices() {
    // TODO: Implémenter la navigation vers les services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les services')),
    );
  }

  void _navigateToEvents() {
    // TODO: Implémenter la navigation vers les événements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les événements')),
    );
  }

  void _navigateToBibleStudy() {
    // TODO: Implémenter la navigation vers les études bibliques
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les études bibliques')),
    );
  }
}

/// Widget compact pour afficher le badge de notifications
class NotificationBadgeWidget extends StatelessWidget {
  final Widget child;

  const NotificationBadgeWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: PushNotificationService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            child,
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
