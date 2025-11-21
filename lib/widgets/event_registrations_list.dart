import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../../theme.dart';

class EventRegistrationsList extends StatefulWidget {
  final EventModel event;

  const EventRegistrationsList({super.key, required this.event});

  @override
  State<EventRegistrationsList> createState() => _EventRegistrationsListState();
}

class _EventRegistrationsListState extends State<EventRegistrationsList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _statusFilters = {
    'all': 'Tous',
    'confirmed': 'Confirmés',
    'waiting': 'En attente',
    'cancelled': 'Annulés',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addManualRegistration() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inscription manuelle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inscrire'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('event_registrations').add({
          'eventId': widget.event.id,
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'status': 'confirmed',
          'registrationType': 'manual',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription ajoutée avec succès'),
              backgroundColor: AppTheme.successColor,
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
      }
    }
    
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _markAttendance(EventRegistrationModel registration, bool isPresent) async {
    try {
      await EventsFirebaseService.markAttendance(registration.id, isPresent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPresent 
                  ? '${registration.fullName} marqué présent'
                  : 'Présence annulée pour ${registration.fullName}',
            ),
            backgroundColor: AppTheme.successColor,
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
    }
  }

  Future<void> _cancelRegistration(EventRegistrationModel registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inscription'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler l\'inscription de ${registration.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await EventsFirebaseService.cancelRegistration(registration.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inscription de ${registration.fullName} annulée'),
              backgroundColor: AppTheme.successColor,
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
      }
    }
  }

  Future<void> _exportRegistrations() async {
    try {
      final data = await EventsFirebaseService.exportEventRegistrations(widget.event.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.length} inscription(s) exportée(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
      // Créer le contenu CSV
      final csvContent = StringBuffer();
      csvContent.writeln('Nom,Email,Téléphone,Statut,Date inscription');
      
      for (final reg in data) {
        final name = reg['name'] ?? '';
        final email = reg['email'] ?? '';
        final phone = reg['phone'] ?? '';
        final status = reg['status'] ?? '';
        final date = reg['createdAt'] != null 
          ? (reg['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
          : '';
        csvContent.writeln('"$name","$email","$phone","$status","$date"');
      }
      
      // Note: Pour un export réel, utiliser package:path_provider et share_plus
      // Ici on stocke temporairement dans Firestore pour téléchargement
      try {
        await FirebaseFirestore.instance.collection('exports').add({
          'type': 'event_registrations',
          'eventId': widget.event.id,
          'content': csvContent.toString(),
          'format': 'csv',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export préparé - disponible dans les exports'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (exportError) {
        print('Erreur export: $exportError');
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
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.successColor;
      case 'waiting': return AppTheme.warningColor;
      case 'cancelled': return AppTheme.errorColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Confirmé';
      case 'waiting': return 'En attente';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.event.isRegistrationEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_reg_outlined,
              size: 64,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Inscriptions désactivées',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Les inscriptions ne sont pas activées pour cet événement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: AppTheme.white100,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              children: [
                // Champ de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un participant...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Filtres et actions
                Row(
                  children: [
                    // Filtre par statut
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                        ),
                        items: _statusFilters.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _statusFilter = value!),
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.space12),
                    
                    // Bouton d'ajout manuel
                    IconButton(
                      onPressed: _addManualRegistration,
                      icon: const Icon(Icons.person_add),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white100,
                      ),
                      tooltip: 'Ajouter manuellement',
                    ),
                    
                    // Bouton d'export
                    IconButton(
                      onPressed: _exportRegistrations,
                      icon: const Icon(Icons.download),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: AppTheme.white100,
                      ),
                      tooltip: 'Exporter',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Liste des inscriptions
          Expanded(
            child: StreamBuilder<List<EventRegistrationModel>>(
              stream: EventsFirebaseService.getEventRegistrationsStream(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text('${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var registrations = snapshot.data!;
                
                // Appliquer les filtres
                if (_statusFilter != 'all') {
                  registrations = registrations.where((r) => r.status == _statusFilter).toList();
                }
                
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  registrations = registrations.where((r) {
                    return r.fullName.toLowerCase().contains(searchLower) ||
                           r.email.toLowerCase().contains(searchLower) ||
                           (r.phone?.toLowerCase().contains(searchLower) ?? false);
                  }).toList();
                }

                if (registrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textTertiaryColor,
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          'Aucune inscription',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          _searchQuery.isNotEmpty || _statusFilter != 'all'
                              ? 'Aucun résultat pour les critères sélectionnés'
                              : 'Aucune inscription pour cet événement',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textTertiaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  itemCount: registrations.length,
                  itemBuilder: (context, index) {
                    final registration = registrations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRegistrationCard(registration),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(EventRegistrationModel registration) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    registration.firstName.isNotEmpty 
                        ? registration.firstName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.space12),
                
                // Nom et email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      Text(
                        registration.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(registration.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    _getStatusLabel(registration.status),
                    style: TextStyle(
                      color: _getStatusColor(registration.status),
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            // Informations supplémentaires
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  'Inscrit le ${_formatDate(registration.registrationDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                
                if (registration.phone != null) ...[
                  const SizedBox(width: AppTheme.spaceMedium),
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    registration.phone!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
            
            // Présence
            if (registration.isConfirmed) ...[
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Icon(
                    registration.isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: registration.isPresent ? AppTheme.successColor : AppTheme.textTertiaryColor,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    registration.isPresent ? 'Présent' : 'Absence non marquée',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: registration.isPresent ? AppTheme.successColor : AppTheme.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ],
            
            // Réponses du formulaire
            if (registration.formResponses.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              ExpansionTile(
                title: const Text('Réponses du formulaire'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                children: registration.formResponses.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Actions
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                // Marquer présent/absent
                if (registration.isConfirmed) ...[
                  TextButton.icon(
                    onPressed: () => _markAttendance(registration, !registration.isPresent),
                    icon: Icon(
                      registration.isPresent ? Icons.remove_circle_outline : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(registration.isPresent ? 'Marquer absent' : 'Marquer présent'),
                    style: TextButton.styleFrom(
                      foregroundColor: registration.isPresent ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Annuler inscription
                if (!registration.isCancelled) ...[
                  TextButton.icon(
                    onPressed: () => _cancelRegistration(registration),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Annuler'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'aujourd\'hui à ${_formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'hier à ${_formatTime(date)}';
    } else {
      final months = [
        'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
        'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year != now.year ? date.year : ''}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }
}