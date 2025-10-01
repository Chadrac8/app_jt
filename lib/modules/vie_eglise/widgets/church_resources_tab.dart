import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme.dart';
import '../models/church_resource.dart';
import '../services/church_resource_service.dart';
import '../../../theme.dart';

class ChurchResourcesTab extends StatefulWidget {
  const ChurchResourcesTab({Key? key}) : super(key: key);

  @override
  State<ChurchResourcesTab> createState() => _ChurchResourcesTabState();
}

class _ChurchResourcesTabState extends State<ChurchResourcesTab> {
  String _selectedType = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {'value': 'all', 'label': 'Tout', 'icon': Icons.all_inclusive},
    {'value': 'video', 'label': 'Vidéos', 'icon': Icons.video_library},
    {'value': 'audio', 'label': 'Audios', 'icon': Icons.audiotrack},
    {'value': 'document', 'label': 'Documents', 'icon': Icons.description},
    {'value': 'link', 'label': 'Liens', 'icon': Icons.link},
    {'value': 'book', 'label': 'Livres', 'icon': Icons.book},
    {'value': 'study', 'label': 'Études', 'icon': Icons.school},
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
            'Ressources',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Découvrez nos ressources spirituelles et éducatives',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher des ressources...',
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
    return StreamBuilder<List<ChurchResource>>(
      stream: ChurchResourceService.getActiveResourcesStream(),
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

        List<ChurchResource> resources = snapshot.data ?? [];

        // Filtrer par type
        if (_selectedType != 'all') {
          resources = resources.where((resource) => resource.resourceType == _selectedType).toList();
        }

        // Filtrer par recherche
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          resources = resources.where((resource) {
            return resource.title.toLowerCase().contains(query) ||
                   resource.description.toLowerCase().contains(query);
          }).toList();
        }

        if (resources.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            return _buildResourceCard(resources[index]);
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
            Icons.library_books_outlined,
            size: 80,
            color: AppTheme.grey500,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _selectedType == 'all' 
                ? 'Aucune ressource disponible'
                : 'Aucune ressource de ce type',
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

  Widget _buildResourceCard(ChurchResource resource) {
    final type = ResourceType.fromValue(resource.resourceType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: InkWell(
        onTap: () => _handleResourceTap(resource),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.imageUrl != null && resource.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: resource.imageUrl!,
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
                          color: AppTheme.black100.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(type.value),
                              color: AppTheme.white100,
                              size: 14,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Text(
                              type.label,
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSize12,
                                fontWeight: AppTheme.fontMedium,
                                color: AppTheme.white100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (resource.resourceType == 'video')
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: AppTheme.white100,
                            size: 50,
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
                  if (resource.imageUrl == null || resource.imageUrl!.isEmpty)
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
                                _getTypeIcon(type.value),
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
                        Text(
                          _formatDate(resource.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    resource.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  if (resource.createdBy != null)
                    Text(
                      'Par ${resource.createdBy}',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize13,
                        color: AppTheme.primaryColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    resource.description,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (resource.downloadCount > 0) ...[
                    const SizedBox(height: AppTheme.spaceSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 16,
                          color: AppTheme.grey500,
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          '${resource.downloadCount} téléchargements',
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize12,
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

  void _handleResourceTap(ChurchResource resource) async {
    // Incrémenter le compteur de téléchargements/vues
    await ChurchResourceService.incrementDownloadCount(resource.id);

    if (resource.fileUrl != null && resource.fileUrl!.isNotEmpty) {
      final Uri url = Uri.parse(resource.fileUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir cette ressource'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } else {
      _showResourceDetails(resource);
    }
  }

  void _showResourceDetails(ChurchResource resource) {
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
                  if (resource.imageUrl != null && resource.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: CachedNetworkImage(
                        imageUrl: resource.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                  ],
                  Text(
                    resource.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize24,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  if (resource.createdBy != null)
                    Text(
                      'Par ${resource.createdBy}',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize16,
                        color: AppTheme.primaryColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    _formatDate(resource.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    resource.description,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize16,
                      color: AppTheme.textPrimaryColor,
                      height: 1.6,
                    ),
                  ),
                  if (resource.fileUrl != null && resource.fileUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleResourceTap(resource),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir la ressource'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.white100,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      case 'book':
        return Icons.book;
      case 'study':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
