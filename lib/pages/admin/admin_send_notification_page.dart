import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/person_model.dart';
import '../../services/push_notification_service.dart';
import '../../services/rich_notification_service.dart';
import '../../models/rich_notification_model.dart';
import '../../theme.dart';

class AdminSendNotificationPage extends StatefulWidget {
  const AdminSendNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminSendNotificationPage> createState() => _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState extends State<AdminSendNotificationPage> {
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
  DateTime? _scheduledTime;

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

  final Map<NotificationPriority, String> _priorityLabels = {
    NotificationPriority.low: 'Faible',
    NotificationPriority.normal: 'Normale',
    NotificationPriority.high: 'Élevée',
    NotificationPriority.urgent: 'Urgente',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
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
      // Charger tous les utilisateurs actifs
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('people')
          .where('isActive', isEqualTo: true)
          .get();

      final users = usersSnapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();

      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des utilisateurs: $e');
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

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAudience == 'specific' && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un utilisateur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final data = {
        'type': _selectedType,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'source': 'admin',
      };

      int successCount = 0;
      int totalCount = 0;
      List<String> userIds = [];

      switch (_selectedAudience) {
        case 'all':
          // Envoyer à tous les utilisateurs
          userIds = _allUsers.map((user) => user.id).toList();
          break;

        case 'specific':
          // Envoyer aux utilisateurs sélectionnés
          userIds = _selectedUsers.map((user) => user.id).toList();
          break;

        case 'admins':
          // Envoyer uniquement aux administrateurs
          userIds = _allUsers
              .where((user) => user.roles.contains('admin'))
              .map((user) => user.id)
              .toList();
          break;

        case 'members':
          // Envoyer uniquement aux membres (non-admins)
          userIds = _allUsers
              .where((user) => !user.roles.contains('admin'))
              .map((user) => user.id)
              .toList();
          break;
      }

      totalCount = userIds.length;

      if (userIds.isNotEmpty) {
        // Choisir le service approprié selon le type de notification
        if (_selectedAudience == 'rich' || _enableRichNotifications) {
          // Utiliser le service de notifications riches
          await RichNotificationService.sendRichNotification(
            title: title,
            body: body,
            recipients: userIds,
            imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
            data: data,
            priority: _selectedPriority,
          );
        } else {
          // Utiliser le service standard selon l'audience
          switch (_selectedAudience) {
            case 'all':
              await RichNotificationService.sendToAllUsers(
                title: title,
                body: body,
                data: data,
                priority: _selectedPriority,
              );
              break;
            case 'admins':
              await RichNotificationService.sendToAdmins(
                title: title,
                body: body,
                data: data,
                priority: _selectedPriority,
              );
              break;
            default:
              // Envoyer via le service traditionnel
              await PushNotificationService.sendNotificationToUsers(
                userIds: userIds,
                title: title,
                body: body,
                data: data,
              );
          }
        }
        successCount = userIds.length;
      }

      setState(() {
        _isLoading = false;
      });

      // Afficher le résultat
      if (mounted) {
        final message = totalCount > 0 
            ? '$successCount/$totalCount notifications envoyées avec succès'
            : 'Aucun destinataire trouvé';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        // Effacer le formulaire si envoi réussi
        if (successCount > 0) {
          _titleController.clear();
          _bodyController.clear();
          setState(() {
            _selectedUsers.clear();
          });
        }
      }
    } catch (e) {
      print('Erreur lors de l\'envoi des notifications: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sélectionner les utilisateurs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final isSelected = _selectedUsers.contains(user);
                      
                      return CheckboxListTile(
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUsers.add(user);
                            } else {
                              _selectedUsers.remove(user);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          child: Text(user.fullName[0].toUpperCase()),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                this.setState(() {}); // Mettre à jour l'état principal
              },
              child: Text('Sélectionner (${_selectedUsers.length})'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Envoyer une notification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statistiques
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, 
                         color: AppTheme.primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel d\'administration',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_allUsers.length} utilisateurs avec notifications actives',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingUsers)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Type de notification
              Text(
                'Type de notification',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
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

              const SizedBox(height: 20),

              // Destinataires
              Text(
                'Destinataires',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAudience,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.people),
                ),
                items: _audienceTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAudience = value!;
                    _selectedUsers.clear();
                  });
                },
              ),

              if (_selectedAudience == 'specific') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showUserSelectionDialog,
                  icon: const Icon(Icons.person_add),
                  label: Text(_selectedUsers.isEmpty 
                      ? 'Sélectionner les utilisateurs'
                      : '${_selectedUsers.length} utilisateur(s) sélectionné(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_selectedUsers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selectedUsers.map((user) {
                      return Chip(
                        label: Text(user.fullName),
                        onDeleted: () {
                          setState(() {
                            _selectedUsers.remove(user);
                          });
                        },
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Titre
              Text(
                'Titre de la notification',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                  hintText: 'Exemple: Nouvelle annonce importante',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  if (value.trim().length < 3) {
                    return 'Le titre doit faire au moins 3 caractères';
                  }
                  return null;
                },
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                'Message de la notification',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.message),
                  hintText: 'Tapez votre message ici...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le message est obligatoire';
                  }
                  if (value.trim().length < 10) {
                    return 'Le message doit faire au moins 10 caractères';
                  }
                  return null;
                },
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Options avancées
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Options Avancées',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switch pour notifications riches
                    Row(
                      children: [
                        Switch(
                          value: _enableRichNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableRichNotifications = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications Enrichies',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Permet d\'ajouter des images et des actions',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_enableRichNotifications) ...[
                      const SizedBox(height: 16),
                      
                      // URL de l'image
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.image),
                          labelText: 'URL de l\'image (optionnel)',
                          hintText: 'https://exemple.com/image.jpg',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sélecteur de priorité
                      DropdownButtonFormField<NotificationPriority>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.priority_high),
                          labelText: 'Priorité',
                        ),
                        items: _priorityLabels.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(
                                  entry.key == NotificationPriority.urgent
                                      ? Icons.warning
                                      : entry.key == NotificationPriority.high
                                          ? Icons.notifications_active
                                          : Icons.notifications,
                                  color: entry.key == NotificationPriority.urgent
                                      ? Colors.red
                                      : entry.key == NotificationPriority.high
                                          ? Colors.orange
                                          : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(entry.value),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Envoi en cours...' : 'Envoyer la notification',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Note d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les notifications seront envoyées uniquement aux utilisateurs ayant activé les notifications push.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}