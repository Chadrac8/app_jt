import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/push_notifications_widget.dart';
import '../services/push_notification_service.dart';

/// Page d'affichage et de gestion des notifications push
class PushNotificationsPage extends StatefulWidget {
  const PushNotificationsPage({super.key});

  @override
  State<PushNotificationsPage> createState() => _PushNotificationsPageState();
}

class _PushNotificationsPageState extends State<PushNotificationsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: PushNotificationService.getUnreadNotificationsCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return TextButton(
                onPressed: _isLoading ? null : _markAllAsRead,
                child: const Text('Tout marquer lu'),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Tout marquer lu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const PushNotificationsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications Push',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restez informé des dernières actualités',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: PushNotificationService.getUnreadNotificationsCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              if (unreadCount == 0) {
                return const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                );
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PushNotificationService.markAllNotificationsAsRead();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildNotificationSettings(),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Paramètres des notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Types de notifications'),
            subtitle: const Text('Choisir les types de notifications à recevoir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showNotificationTypes();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Horaires de notification'),
            subtitle: const Text('Définir les heures de réception'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showNotificationSchedule();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Sons et vibrations'),
            subtitle: const Text('Configurer les alertes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showSoundSettings();
            },
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showNotificationTypes() {
    // TODO: Implémenter la configuration des types de notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration des types de notifications')),
    );
  }

  void _showNotificationSchedule() {
    // TODO: Implémenter la configuration des horaires
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration des horaires')),
    );
  }

  void _showSoundSettings() {
    // TODO: Implémenter la configuration des sons
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration des sons et vibrations')),
    );
  }
}
