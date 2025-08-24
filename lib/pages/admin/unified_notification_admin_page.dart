import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/person_model.dart';
import '../../services/push_notification_service.dart';
import '../../models/rich_notification_model.dart';
import '../../theme.dart';
import 'notification_diagnostics_page.dart';
import 'notification_history_page.dart';

class UnifiedNotificationAdminPage extends StatefulWidget {
  const UnifiedNotificationAdminPage({Key? key}) : super(key: key);

  @override
  State<UnifiedNotificationAdminPage> createState() => _UnifiedNotificationAdminPageState();
}

class _UnifiedNotificationAdminPageState extends State<UnifiedNotificationAdminPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // Controllers for notification form
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _selectedType = 'general';
  String _selectedAudience = 'all';
  List<PersonModel> _selectedUsers = [];
  List<PersonModel> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  bool _enableRichNotifications = false;
  NotificationPriority _selectedPriority = NotificationPriority.normal;

  final Map<String, String> _notificationTypes = {
    'general': 'Général',
    'announcement': 'Annonce',
    'event': 'Événement',
    'urgent': 'Urgent',
    'reminder': 'Rappel',
    'bible_study': 'Étude biblique',
    'prayer': 'Prière',
  };

  final Map<String, String> _audienceTypes = {
    'all': 'Tous les utilisateurs',
    'specific': 'Utilisateurs spécifiques',
    'admins': 'Administrateurs uniquement',
    'members': 'Membres uniquement',
    'rich': 'Notification enrichie',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 onglets : Envoyer, Enrichies, Historique, Diagnostics
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      List<PersonModel> users = snapshot.docs.map((doc) {
        return PersonModel.fromFirestore(doc);
      }).toList();

      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des utilisateurs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Envoyer'),
            Tab(icon: Icon(Icons.notification_add), text: 'Enrichies'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
            Tab(icon: Icon(Icons.analytics), text: 'Diagnostics'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendNotificationTab(),
          _buildRichNotificationTab(),
          const NotificationHistoryPage(),
          const NotificationDiagnosticsPage(),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Envoyer une Notification', Icons.send),
            const SizedBox(height: 24),
            
            // Type de notification
            _buildSectionCard(
              'Type de notification',
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _getInputDecoration('Type'),
                items: _notificationTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Audience
            _buildSectionCard(
              'Audience',
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedAudience,
                    decoration: _getInputDecoration('Audience'),
                    items: _audienceTypes.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAudience = value!;
                        if (value != 'specific') {
                          _selectedUsers.clear();
                        }
                      });
                    },
                  ),
                  if (_selectedAudience == 'specific') _buildUserSelection(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contenu
            _buildSectionCard(
              'Contenu de la notification',
              Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _getInputDecoration('Titre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    decoration: _getInputDecoration('Message'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le message est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: _getInputDecoration('URL de l\'image (optionnel)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Options avancées
            _buildSectionCard(
              'Options avancées',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Notifications enrichies'),
                    subtitle: const Text('Activer les fonctionnalités avancées'),
                    value: _enableRichNotifications,
                    onChanged: (value) {
                      setState(() {
                        _enableRichNotifications = value;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Priorité'),
                    subtitle: DropdownButton<NotificationPriority>(
                      value: _selectedPriority,
                      onChanged: (NotificationPriority? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                      items: NotificationPriority.values.map((NotificationPriority priority) {
                        return DropdownMenuItem<NotificationPriority>(
                          value: priority,
                          child: Text(_getPriorityLabel(priority)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton d'envoi
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
                label: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer la notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Notifications Enrichies', Icons.notification_add),
          const SizedBox(height: 24),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Fonctionnalités Avancées',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('🎯', 'Segmentation d\'audience', 'Ciblage précis des utilisateurs'),
                  _buildFeatureItem('📊', 'Analytics en temps réel', 'Suivi des performances'),
                  _buildFeatureItem('🔔', 'Templates personnalisés', 'Modèles réutilisables'),
                  _buildFeatureItem('⏰', 'Planification', 'Envoi différé et récurrent'),
                  _buildFeatureItem('🎨', 'Contenu riche', 'Images, actions et médias'),
                  const SizedBox(height: 16),
                  const Text(
                    'Ces fonctionnalités avancées permettent de créer des campagnes de notifications sophistiquées avec un ciblage précis et un suivi détaillé des performances.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Boutons d'action pour les fonctionnalités avancées
          _buildActionButton(
            'Créer un template',
            'Gérer les modèles de notifications',
            Icons.design_services,
            () => _showTemplateManager(),
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            'Segmentation audience',
            'Configurer les critères de ciblage',
            Icons.group,
            () => _showAudienceSegmentation(),
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            'Planifier campagne',
            'Programmer des envois différés',
            Icons.schedule,
            () => _showCampaignScheduler(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildUserSelection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner les utilisateurs',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingUsers)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  final isSelected = _selectedUsers.contains(user);
                  return CheckboxListTile(
                    title: Text(user.fullName),
                    subtitle: Text(user.email),
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedUsers.add(user);
                        } else {
                          _selectedUsers.remove(user);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selectedUsers.length} utilisateur(s) sélectionné(s)',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Faible';
      case NotificationPriority.normal:
        return 'Normale';
      case NotificationPriority.high:
        return 'Élevée';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser le service de base pour l'envoi simple
      if (_selectedAudience == 'specific' && _selectedUsers.isNotEmpty) {
        for (final user in _selectedUsers) {
          await PushNotificationService.sendNotificationToUser(
            userId: user.id,
            title: _titleController.text,
            body: _bodyController.text,
          );
        }
      } else {
        // Envoi général - afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonctionnalité d\'envoi général en cours de développement'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Réinitialiser le formulaire
      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedType = 'general';
        _selectedAudience = 'all';
        _selectedUsers.clear();
        _enableRichNotifications = false;
        _selectedPriority = NotificationPriority.normal;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification traitée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTemplateManager() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gestionnaire de templates - Fonctionnalité en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAudienceSegmentation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segmentation d\'audience - Fonctionnalité en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCampaignScheduler() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Planificateur de campagnes - Fonctionnalité en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
