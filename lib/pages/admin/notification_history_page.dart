import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({Key? key}) : super(key: key);

  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  String _selectedFilter = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes'),
              ),
              const PopupMenuItem(
                value: 'rich',
                child: Text('Notifications riches'),
              ),
              const PopupMenuItem(
                value: 'templated',
                child: Text('Avec template'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Aujourd\'hui'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques rapides
          _buildQuickStats(),
          
          // Liste des notifications
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nouvelle notification',
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rich_notifications')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }

        final notifications = snapshot.data!.docs;
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        final todayCount = notifications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) return false;
          return timestamp.toDate().isAfter(todayStart);
        }).length;

        final totalCount = notifications.length;
        final richCount = notifications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['type'] == 'rich';
        }).length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalCount.toString(), Icons.notifications),
              _buildStatItem('Aujourd\'hui', todayCount.toString(), Icons.today),
              _buildStatItem('Riches', richCount.toString(), Icons.star),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    Query query = FirebaseFirestore.instance
        .collection('rich_notifications')
        .orderBy('timestamp', descending: true);

    // Appliquer les filtres
    if (_selectedFilter == 'rich') {
      query = query.where('type', isEqualTo: 'rich');
    } else if (_selectedFilter == 'templated') {
      query = query.where('type', isEqualTo: 'templated');
    } else if (_selectedFilter == 'today') {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(todayStart));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune notification trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les notifications envoyées apparaîtront ici',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildNotificationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(String id, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Sans titre';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'standard';
    final priority = data['priority'] as String? ?? 'normal';
    final timestamp = data['timestamp'] as Timestamp?;
    final imageUrl = data['imageUrl'] as String?;
    final recipients = data['recipients'] as List<dynamic>? ?? [];
    final senderName = data['senderName'] as String? ?? 'Système';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showNotificationDetails(id, data),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et badge type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeBadge(type),
                ],
              ),
              
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Informations supplémentaires
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.group, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${recipients.length} destinataires',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              
              // Indicateurs visuels
              if (imageUrl != null || priority != 'normal') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (imageUrl != null) ...[
                      Icon(Icons.image, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (priority != 'normal')
                      _buildPriorityIndicator(priority),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    String label;
    
    switch (type) {
      case 'rich':
        color = Colors.purple;
        label = 'RICHE';
        break;
      case 'templated':
        color = Colors.green;
        label = 'TEMPLATE';
        break;
      default:
        color = Colors.blue;
        label = 'STANDARD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color;
    IconData icon;
    
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'normal':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      default:
        color = Colors.grey;
        icon = Icons.low_priority;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          priority.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showNotificationDetails(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Détails de la notification'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', id),
              _buildDetailRow('Type', data['type'] ?? 'Standard'),
              _buildDetailRow('Priorité', data['priority'] ?? 'Normal'),
              _buildDetailRow('Expéditeur', data['senderName'] ?? 'Système'),
              if (data['body'] != null && data['body'].toString().isNotEmpty)
                _buildDetailRow('Contenu', data['body']),
              if (data['imageUrl'] != null)
                _buildDetailRow('Image URL', data['imageUrl']),
              _buildDetailRow('Destinataires', '${(data['recipients'] as List?)?.length ?? 0} utilisateurs'),
              if (data['timestamp'] != null)
                _buildDetailRow('Envoyé le', _formatFullTimestamp(data['timestamp'] as Timestamp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatFullTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
