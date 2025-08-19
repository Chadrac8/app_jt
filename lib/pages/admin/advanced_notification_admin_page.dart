import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/rich_notification_service.dart';
import '../../models/rich_notification_model.dart';
import 'notification_diagnostics_page.dart';
import 'notification_history_page.dart';

class AdvancedNotificationAdminPage extends StatefulWidget {
  const AdvancedNotificationAdminPage({Key? key}) : super(key: key);

  @override
  State<AdvancedNotificationAdminPage> createState() => _AdvancedNotificationAdminPageState();
}

class _AdvancedNotificationAdminPageState extends State<AdvancedNotificationAdminPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // Controllers for notification form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Avancées'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryPage(),
                ),
              );
            },
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Diagnostics',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationDiagnosticsPage(),
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Envoyer'),
            Tab(icon: Icon(Icons.account_tree), text: 'Templates'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildTemplatesTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle Notification',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Image (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Priorité'),
                      DropdownButton<NotificationPriority>(
                        value: _selectedPriority,
                        isExpanded: true,
                        onChanged: (NotificationPriority? newValue) {
                          setState(() {
                            _selectedPriority = newValue ?? NotificationPriority.normal;
                          });
                        },
                        items: NotificationPriority.values.map((priority) {
                          return DropdownMenuItem<NotificationPriority>(
                            value: priority,
                            child: Text(_priorityLabel(priority)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _sendToAllUsers(),
                    child: _isLoading 
                      ? const CircularProgressIndicator(strokeWidth: 2) 
                      : const Text('Envoyer à tous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _sendToAdmins(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Envoyer aux admins'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Templates de Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Événement'),
              subtitle: const Text('Template pour les événements'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Implémenter l'édition des templates
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Annonce'),
              subtitle: const Text('Template pour les annonces'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Implémenter l'édition des templates
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.celebration),
              title: const Text('Célébration'),
              subtitle: const Text('Template pour les célébrations'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Implémenter l'édition des templates
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notification_analytics')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Aucune donnée analytique disponible');
              }
              
              final analytics = snapshot.data!.docs;
              int totalSent = analytics.length;
              int totalDelivered = analytics.where((doc) => 
                (doc.data() as Map<String, dynamic>)['status'] == 'delivered'
              ).length;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.send, size: 40, color: Colors.blue),
                                Text('$totalSent', style: Theme.of(context).textTheme.headlineMedium),
                                const Text('Notifications envoyées'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                Text('$totalDelivered', style: Theme.of(context).textTheme.headlineMedium),
                                const Text('Notifications délivrées'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: analytics.length,
                      itemBuilder: (context, index) {
                        final doc = analytics[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              data['status'] == 'delivered' 
                                ? Icons.check_circle 
                                : Icons.schedule,
                              color: data['status'] == 'delivered' 
                                ? Colors.green 
                                : Colors.orange,
                            ),
                            title: Text(data['title'] ?? 'Sans titre'),
                            subtitle: Text(data['type'] ?? 'Type inconnu'),
                            trailing: Text(
                              _formatTimestamp(data['timestamp']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _priorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'Haute';
      case NotificationPriority.normal:
        return 'Normale';
      case NotificationPriority.low:
        return 'Basse';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Date inconnue';
  }

  Future<void> _sendToAllUsers() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RichNotificationService.sendToAllUsers(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        priority: _selectedPriority,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification envoyée à tous les utilisateurs'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendToAdmins() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RichNotificationService.sendToAdmins(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        priority: _selectedPriority,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification envoyée aux administrateurs'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _imageUrlController.clear();
    setState(() {
      _selectedPriority = NotificationPriority.normal;
    });
  }
}
