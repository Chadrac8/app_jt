import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_message_model.dart';
import '../services/contact_service.dart';
import '../../../theme.dart';

/// Page d'administration pour gérer les messages de contact
class ContactMessagesAdminPage extends StatefulWidget {
  const ContactMessagesAdminPage({super.key});

  @override
  State<ContactMessagesAdminPage> createState() => _ContactMessagesAdminPageState();
}

class _ContactMessagesAdminPageState extends State<ContactMessagesAdminPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages de contact'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white100,
          labelColor: AppTheme.white100,
          unselectedLabelColor: AppTheme.white100.withOpacity(0.70),
          tabs: [
            Tab(
              icon: StreamBuilder<int>(
                stream: ContactService.getUnreadCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.mark_email_unread),
                  );
                },
              ),
              text: 'Non lus',
            ),
            const Tab(
              icon: Icon(Icons.all_inbox),
              text: 'Tous',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnreadMessages(),
          _buildAllMessages(),
        ],
      ),
    );
  }

  Widget _buildUnreadMessages() {
    return StreamBuilder<List<ContactMessage>>(
      stream: ContactService.getUnreadMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.redStandard),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read, size: 64, color: AppTheme.grey500),
                SizedBox(height: 16),
                Text(
                  'Aucun message non lu',
                  style: TextStyle(fontSize: 18, color: AppTheme.grey500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageCard(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildAllMessages() {
    return StreamBuilder<List<ContactMessage>>(
      stream: ContactService.getAllMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.redStandard),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: AppTheme.grey500),
                SizedBox(height: 16),
                Text(
                  'Aucun message reçu',
                  style: TextStyle(fontSize: 18, color: AppTheme.grey500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageCard(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageCard(ContactMessage message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: message.isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: message.isRead ? AppTheme.grey500 : AppTheme.primaryColor,
          child: Icon(
            message.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
            color: AppTheme.white100,
            size: 20,
          ),
        ),
        title: Text(
          message.subject,
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : AppTheme.fontBold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: ${message.name} (${message.email})'),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy à HH:mm').format(message.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'read':
                _markAsRead(message);
                break;
              case 'delete':
                _deleteMessage(message);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!message.isRead)
              const PopupMenuItem(
                value: 'read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Marquer comme lu'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppTheme.redStandard),
                title: Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showMessageDetails(message),
      ),
    );
  }

  void _showMessageDetails(ContactMessage message) {
    // Marquer comme lu automatiquement quand on ouvre
    if (!message.isRead) {
      _markAsRead(message);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.subject,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'De: ${message.name}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Email: ${message.email}',
                          style: const TextStyle(color: AppTheme.grey500),
                        ),
                        Text(
                          'Reçu le: ${DateFormat('dd/MM/yyyy à HH:mm').format(message.createdAt)}',
                          style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const Divider(height: 32),
              
              // Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.grey50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.grey300!),
                ),
                child: Text(
                  message.message,
                  style: const TextStyle(height: 1.5),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMessage(message);
                      },
                      icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                      label: const Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white100,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsRead(ContactMessage message) async {
    try {
      await ContactService.markAsRead(message.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message marqué comme lu'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _deleteMessage(ContactMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.white100)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ContactService.deleteMessage(message.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message supprimé'),
              backgroundColor: AppTheme.greenStandard,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.redStandard,
            ),
          );
        }
      }
    }
  }
}
