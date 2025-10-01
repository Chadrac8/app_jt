import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/family_service.dart';
import '../../theme.dart';
import 'family_detail_page.dart';
import 'family_form_page.dart';

class FamiliesManagementPage extends StatefulWidget {
  const FamiliesManagementPage({Key? key}) : super(key: key);

  @override
  State<FamiliesManagementPage> createState() => _FamiliesManagementPageState();
}

class _FamiliesManagementPageState extends State<FamiliesManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  FamilyStatus? _selectedStatus;
  bool _showStatistics = false;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await FamilyService.getFamilyStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = FamilyStatus.member;
          break;
        case 2:
          _selectedStatus = FamilyStatus.visitor;
          break;
        case 3:
          _selectedStatus = FamilyStatus.attendee;
          break;
        case 4:
          _selectedStatus = FamilyStatus.inactive;
          break;
        case 5:
          _selectedStatus = FamilyStatus.inactive_member;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Familles'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => _onTabChanged(),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Membres'),
            Tab(text: 'Visiteurs'),
            Tab(text: 'Participants'),
            Tab(text: 'Inactifs'),
            Tab(text: 'Ex-membres'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showStatistics ? Icons.list : Icons.analytics),
            onPressed: () {
              setState(() {
                _showStatistics = !_showStatistics;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToFamilyForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showStatistics) _buildStatisticsCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(6, (index) => _buildFamiliesList()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToFamilyForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Famille'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une famille...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchTerm = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchTerm = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques des Familles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Familles',
                      '${_statistics!['totalFamilies']}',
                      Icons.family_restroom,
                      AppTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Total Membres',
                      '${_statistics!['totalMembers']}',
                      Icons.people,
                      AppTheme.secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Taille Moyenne',
                      '${_statistics!['averageFamilySize'].toStringAsFixed(1)}',
                      Icons.analytics,
                      AppTheme.secondaryColor,
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFamiliesList() {
    return StreamBuilder<List<FamilyModel>>(
      stream: FamilyService.getFamiliesStream(status: _selectedStatus),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur lors du chargement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final families = snapshot.data ?? [];
        final filteredFamilies = families.where((family) {
          if (_searchTerm.isEmpty) return true;
          return family.name.toLowerCase().contains(_searchTerm) ||
                 family.fullAddress.toLowerCase().contains(_searchTerm);
        }).toList();

        if (filteredFamilies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  _searchTerm.isNotEmpty
                      ? 'Aucune famille trouvée'
                      : 'Aucune famille enregistrée',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  _searchTerm.isNotEmpty
                      ? 'Essayez avec d\'autres termes de recherche'
                      : 'Commencez par créer une nouvelle famille',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton.icon(
                  onPressed: () => _navigateToFamilyForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une famille'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: filteredFamilies.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (context, index) {
            final family = filteredFamilies[index];
            return _buildFamilyCard(family);
          },
        );
      },
    );
  }

  Widget _buildFamilyCard(FamilyModel family) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => _navigateToFamilyDetail(family),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getStatusColor(family.status).withOpacity(0.2),
                    child: family.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              family.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.family_restroom, color: _getStatusColor(family.status)),
                            ),
                          )
                        : Icon(Icons.family_restroom, color: _getStatusColor(family.status)),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: AppTheme.fontBold,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(family.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              child: Text(
                                _getStatusLabel(family.status),
                                style: TextStyle(
                                  fontSize: AppTheme.fontSize12,
                                  color: _getStatusColor(family.status),
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Text(
                              '${family.memberIds.length} membre${family.memberIds.length > 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleFamilyAction(value, family),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Voir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Modifier'),
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
                ],
              ),
              if (family.fullAddress.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Expanded(
                      child: Text(
                        family.fullAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (family.homePhone != null) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      family.homePhone!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (family.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: family.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: AppTheme.fontSize12),
                    ),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    side: BorderSide.none,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(FamilyStatus status) {
    switch (status) {
      case FamilyStatus.member:
        return AppTheme.greenStandard;
      case FamilyStatus.visitor:
        return AppTheme.blueStandard;
      case FamilyStatus.attendee:
        return AppTheme.orangeStandard;
      case FamilyStatus.inactive:
        return AppTheme.grey500;
      case FamilyStatus.inactive_member:
        return AppTheme.redStandard;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusLabel(FamilyStatus status) {
    switch (status) {
      case FamilyStatus.member:
        return 'Membre';
      case FamilyStatus.visitor:
        return 'Visiteur';
      case FamilyStatus.attendee:
        return 'Participant';
      case FamilyStatus.inactive:
        return 'Inactif';
      case FamilyStatus.inactive_member:
        return 'Ex-membre';
      default:
        return 'Actif';
    }
  }

  void _handleFamilyAction(String action, FamilyModel family) {
    switch (action) {
      case 'view':
        _navigateToFamilyDetail(family);
        break;
      case 'edit':
        _navigateToFamilyForm(family: family);
        break;
      case 'delete':
        _showDeleteConfirmation(family);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(FamilyModel family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Supprimer la famille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la famille "${family.name}" ?\n\n'
          'Cette action supprimera également tous les liens familiaux des membres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: AppTheme.white100,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FamilyService.deleteFamily(family.id);
        await _loadStatistics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Famille "${family.name}" supprimée'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToFamilyForm({FamilyModel? family}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyFormPage(family: family),
      ),
    );

    if (result == true) {
      await _loadStatistics();
    }
  }

  void _navigateToFamilyDetail(FamilyModel family) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyDetailPage(familyId: family.id),
      ),
    );
  }
}