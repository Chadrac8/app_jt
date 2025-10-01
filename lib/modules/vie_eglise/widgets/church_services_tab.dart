import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme.dart';
import '../models/church_service.dart';
import '../services/church_service_service.dart';
import '../../../theme.dart';

class ChurchServicesTab extends StatefulWidget {
  const ChurchServicesTab({Key? key}) : super(key: key);

  @override
  State<ChurchServicesTab> createState() => _ChurchServicesTabState();
}

class _ChurchServicesTabState extends State<ChurchServicesTab> {
  String _selectedType = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {'value': 'all', 'label': 'Tout', 'icon': Icons.all_inclusive},
    {'value': 'worship', 'label': 'Culte', 'icon': Icons.church},
    {'value': 'prayer', 'label': 'Prière', 'icon': Icons.handshake},
    {'value': 'bible_study', 'label': 'Étude biblique', 'icon': Icons.menu_book},
    {'value': 'youth', 'label': 'Jeunesse', 'icon': Icons.groups_2},
    {'value': 'children', 'label': 'Enfants', 'icon': Icons.child_care},
    {'value': 'ministry', 'label': 'Ministère', 'icon': Icons.volunteer_activism},
    {'value': 'event', 'label': 'Événement', 'icon': Icons.event},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTypeFilter(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services & Activités',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Participez à nos services et activités communautaires',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher des services...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.white100,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.white100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.grey500,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'],
                      color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      type['label'],
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontMedium,
                        color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<ChurchService>>(
      stream: ChurchServiceService.getActiveServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.redStandard),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur de chargement',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        List<ChurchService> services = snapshot.data ?? [];

        // Filtrer par type
        if (_selectedType != 'all') {
          services = services.where((service) => service.serviceType == _selectedType).toList();
        }

        // Filtrer par recherche
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          services = services.where((service) {
            return service.title.toLowerCase().contains(query) ||
                   service.description.toLowerCase().contains(query) ||
                   (service.location?.toLowerCase().contains(query) ?? false);
          }).toList();
        }

        // Trier par date (si disponible)
        services.sort((a, b) {
          if (a.scheduleDate == null && b.scheduleDate == null) return 0;
          if (a.scheduleDate == null) return 1;
          if (b.scheduleDate == null) return -1;
          return a.scheduleDate!.compareTo(b.scheduleDate!);
        });

        if (services.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppTheme.grey500,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _selectedType == 'all' 
                ? 'Aucun service programmé'
                : 'Aucun service de ce type',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ChurchService service) {
    final type = ServiceType.fromValue(service.serviceType);
    final isUpcoming = service.scheduleDate?.isAfter(DateTime.now()) ?? false;
    final timeUntil = service.scheduleDate?.difference(DateTime.now()) ?? Duration.zero;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: InkWell(
        onTap: () => _showServiceDetails(service),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: AppTheme.grey500,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150,
                        color: AppTheme.grey500,
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUpcoming ? AppTheme.greenStandard.withOpacity(0.9) : AppTheme.grey500.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          isUpcoming ? 'À venir' : 'Passé',
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontMedium,
                            color: AppTheme.white100,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getServiceIcon(type.value),
                              color: AppTheme.primaryColor,
                              size: 14,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Text(
                              type.label,
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSize12,
                                fontWeight: AppTheme.fontMedium,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isUpcoming && timeUntil.inDays < 7)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeStandard.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            _getTimeUntilText(timeUntil),
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontMedium,
                              color: AppTheme.orangeStandard,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    service.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    service.description,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  if (service.scheduleDate != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          _formatDateTimeWithTime(service.scheduleDate!, service.scheduleTime),
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize13,
                            fontWeight: AppTheme.fontMedium,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                  ],
                  if (service.location != null && service.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.grey500,
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Expanded(
                          child: Text(
                            service.location!,
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize13,
                              color: AppTheme.grey500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                  ],
                  if (service.pastor != null && service.pastor!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.grey500,
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          'Pasteur: ${service.pastor}',
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize13,
                            color: AppTheme.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDetails(ChurchService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.white100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.grey500,
                        borderRadius: BorderRadius.circular(AppTheme.radius2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  if (service.imageUrl != null && service.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: CachedNetworkImage(
                        imageUrl: service.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                  ],
                  Text(
                    service.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize24,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  if (service.scheduleDate != null) ...[
                    _buildDetailRow(
                      Icons.access_time, 
                      'Date et heure', 
                      _formatDateTimeWithTime(service.scheduleDate!, service.scheduleTime)
                    ),
                  ],
                  if (service.location != null && service.location!.isNotEmpty)
                    _buildDetailRow(Icons.location_on, 'Lieu', service.location!),
                  if (service.pastor != null && service.pastor!.isNotEmpty)
                    _buildDetailRow(Icons.person, 'Pasteur', service.pastor!),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    service.description,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize16,
                      color: AppTheme.textPrimaryColor,
                      height: 1.6,
                    ),
                  ),
                  if (service.isRecurring && service.recurrencePattern != null) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Récurrence',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize18,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      _getRecurrenceText(service.recurrencePattern!),
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize16,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.space12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'worship':
        return Icons.church;
      case 'prayer':
        return Icons.handshake;
      case 'bible_study':
        return Icons.menu_book;
      case 'youth':
        return Icons.groups_2;
      case 'children':
        return Icons.child_care;
      case 'ministry':
        return Icons.volunteer_activism;
      case 'event':
        return Icons.event;
      default:
        return Icons.church;
    }
  }

  String _getTimeUntilText(Duration duration) {
    if (duration.inDays > 0) {
      return 'Dans ${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'Dans ${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else {
      return 'Bientôt';
    }
  }

  String _formatDateTimeWithTime(DateTime dateTime, String? time) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    
    String result = '$dayName ${dateTime.day} $monthName';
    if (time != null && time.isNotEmpty) {
      result += ' à $time';
    }
    
    return result;
  }

  String _getRecurrenceText(String recurrence) {
    switch (recurrence) {
      case 'daily':
        return 'Tous les jours';
      case 'weekly':
        return 'Chaque semaine';
      case 'monthly':
        return 'Chaque mois';
      case 'yearly':
        return 'Chaque année';
      default:
        return 'Événement unique';
    }
  }
}
