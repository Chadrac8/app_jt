import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme.dart';
import '../../../../auth/auth_service.dart';

class ServicesMemberView extends StatefulWidget {
  const ServicesMemberView({super.key});

  @override
  State<ServicesMemberView> createState() => _ServicesMemberViewState();
}

class _ServicesMemberViewState extends State<ServicesMemberView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('date', isGreaterThanOrEqualTo: now)
          .orderBy('date')
          .limit(10)
          .get();

      setState(() {
        _services = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement services: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildServicesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      color: AppTheme.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Services & Événements',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.grey800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            'Participez aux services et événements de l\'église',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerForService(Map<String, dynamic> service) async {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('service_registrations')
          .add({
        'serviceId': service['id'],
        'userId': userId,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie !')),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppTheme.grey400),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucun service à venir',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.grey600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildServiceCard(_services[index]),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> serviceData) {
    final index = _services.indexOf(serviceData);
    final services = [
      {
        'name': 'Service du dimanche',
        'type': 'worship',
        'date': DateTime.now().add(Duration(days: index + 1)),
        'location': 'Église principale',
        'description': 'Service de louange et d\'adoration',
        'volunteers': 12,
        'maxVolunteers': 15,
      },
      {
        'name': 'École du dimanche',
        'type': 'children',
        'date': DateTime.now().add(Duration(days: index + 2)),
        'location': 'Salle des enfants',
        'description': 'Enseignement pour les enfants',
        'volunteers': 8,
        'maxVolunteers': 10,
      },
      {
        'name': 'Réunion de jeunes',
        'type': 'youth',
        'date': DateTime.now().add(Duration(days: index + 3)),
        'location': 'Salle de jeunesse',
        'description': 'Rencontre hebdomadaire des jeunes',
        'volunteers': 5,
        'maxVolunteers': 8,
      },
      {
        'name': 'Réunion de prière',
        'type': 'prayer',
        'date': DateTime.now().add(Duration(days: index + 4)),
        'location': 'Salle de prière',
        'description': 'Temps de prière communautaire',
        'volunteers': 15,
        'maxVolunteers': 20,
      },
      {
        'name': 'Événement spécial',
        'type': 'event',
        'date': DateTime.now().add(Duration(days: index + 5)),
        'location': 'Auditorium',
        'description': 'Conférence ou événement particulier',
        'volunteers': 3,
        'maxVolunteers': 12,
      },
    ];

    final service = services[index % services.length];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: _getServiceTypeColor(service['type'] as String).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getServiceTypeIcon(service['type'] as String),
                  color: _getServiceTypeColor(service['type'] as String),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.grey800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      service['description'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.grey500,
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Text(
                _formatServiceDate(service['date'] as DateTime),
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.grey600,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.grey500,
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Expanded(
                child: Text(
                  service['location'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.grey600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: AppTheme.grey500,
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Text(
                '${service['volunteers']}/${service['maxVolunteers']} bénévoles',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.grey600,
                ),
              ),
              const Spacer(),
              if ((service['volunteers'] as int) < (service['maxVolunteers'] as int))
                ElevatedButton(
                  onPressed: () => _registerForService(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenStandard,
                    foregroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'S\'inscrire',
                    style: GoogleFonts.poppins(fontSize: AppTheme.fontSize12),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeStandard.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.orangeStandard.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Complet',
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize10,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.orangeStandard,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getServiceTypeColor(String type) {
    switch (type) {
      case 'worship':
        return AppTheme.primaryColor;
      case 'children':
        return AppTheme.orangeStandard;
      case 'youth':
        return AppTheme.secondaryColor;
      case 'prayer':
        return AppTheme.blueStandard;
      case 'event':
        return AppTheme.greenStandard;
      default:
        return AppTheme.grey500;
    }
  }

  IconData _getServiceTypeIcon(String type) {
    switch (type) {
      case 'worship':
        return Icons.music_note;
      case 'children':
        return Icons.child_care;
      case 'youth':
        return Icons.group;
      case 'prayer':
        return Icons.favorite;
      case 'event':
        return Icons.event;
      default:
        return Icons.volunteer_activism;
    }
  }

  String _formatServiceDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Passé';
    } else if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference <= 7) {
      return 'Dans $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
