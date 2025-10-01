import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../services/prayers_firebase_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_search_filter_bar.dart';
import '../../theme.dart';
import '../auth/auth_service.dart';
import 'prayer_form_page.dart';
import 'prayer_detail_page.dart';

class MemberPrayerWallPage extends StatefulWidget {
  const MemberPrayerWallPage({super.key});

  @override
  State<MemberPrayerWallPage> createState() => _MemberPrayerWallPageState();
}

class _MemberPrayerWallPageState extends State<MemberPrayerWallPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  PrayerType? _selectedType;
  String? _selectedCategory;
  bool _showApprovedOnly = true; // Membres voient seulement les prières approuvées
  bool _showActiveOnly = true;
  String _selectedTab = 'all';
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
  List<String> _availableCategories = [];
  PrayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    );
    _tabAnimationController.forward();

    _loadCategories();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await PrayersFirebaseService.getUsedCategories();
    setState(() {
      _availableCategories = categories;
    });
  }

  Future<void> _loadStats() async {
    final stats = await PrayersFirebaseService.getPrayerStats();
    setState(() {
      _stats = stats;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategory = null;
      _showApprovedOnly = true;
      _showActiveOnly = true;
    });
    _searchController.clear();
  }

  void _navigateToPrayerForm([PrayerModel? prayer]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerFormPage(prayer: prayer),
      ),
    ).then((_) {
      _loadStats();
      _loadCategories();
    });
  }

  void _navigateToPrayerDetail(PrayerModel prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerDetailPage(prayer: prayer),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pan_tool,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text(
                  'Mur de Prière Communautaire',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            const Text(
              'Partagez vos demandes, témoignages et actions de grâce avec la communauté',
              style: TextStyle(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.grey500,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '${_stats!.totalPrayers}',
                    Icons.pan_tool,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Aujourd\'hui',
                    '${_stats!.todayPrayers}',
                    Icons.today,
                    AppTheme.blueStandard,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cette semaine',
                    '${_stats!.weekPrayers}',
                    Icons.date_range,
                    AppTheme.greenStandard,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Intercessions',
                    '${_stats!.totalPrayerCount}',
                    Icons.favorite,
                    AppTheme.redStandard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontSize10,
            color: AppTheme.grey500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXSmall),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                'all',
                'Toutes',
                Icons.pan_tool,
                null,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                'my_prayers',
                'Mes prières',
                Icons.person,
                null,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                'my_intercessions',
                'Mes intercessions',
                Icons.favorite,
                null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon, Color? color) {
    final isSelected = _selectedTab == tabId;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabId),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: isSelected 
                ? Border.all(color: AppTheme.primaryColor, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : AppTheme.grey500,
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: isSelected ? AppTheme.fontSemiBold : FontWeight.normal,
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : AppTheme.grey500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<List<PrayerModel>> _getPrayersStream() {
    final user = AuthService.currentUser;
    
    switch (_selectedTab) {
      case 'my_prayers':
        return PrayersFirebaseService.getUserPrayersStream();
      case 'my_intercessions':
        if (user == null) return Stream.value([]);
        return PrayersFirebaseService.getPrayersStream(
          approvedOnly: _showApprovedOnly,
          activeOnly: _showActiveOnly,
          limit: 100,
        ).map((prayers) => prayers.where((prayer) => 
            prayer.prayedByUsers.contains(user.uid)).toList());
      default:
        return PrayersFirebaseService.getPrayersStream(
          type: _selectedType,
          category: _selectedCategory,
          approvedOnly: _showApprovedOnly,
          activeOnly: _showActiveOnly,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          limit: 100,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mur de Prière'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
      ),
      body: Column(
        children: [
          // Statistiques
          _buildStatsHeader(),

          // Sélecteur d'onglets
          _buildTabSelector(),

          // Barre de recherche et filtres (seulement pour "Toutes")
          if (_selectedTab == 'all')
            PrayerSearchFilterBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedType: _selectedType,
              selectedCategory: _selectedCategory,
              availableCategories: _availableCategories,
              showApprovedOnly: _showApprovedOnly,
              showActiveOnly: _showActiveOnly,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              onTypeChanged: (type) => setState(() => _selectedType = type),
              onCategoryChanged: (category) => setState(() => _selectedCategory = category),
              onApprovedOnlyChanged: (value) => setState(() => _showApprovedOnly = value),
              onActiveOnlyChanged: (value) => setState(() => _showActiveOnly = value),
              onClearFilters: _clearFilters,
            ),

          // Liste des prières
          Expanded(
            child: StreamBuilder<List<PrayerModel>>(
              stream: _getPrayersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.redStandard,
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.redStandard),
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

                final prayers = snapshot.data ?? [];

                if (prayers.isEmpty) {
                  String emptyMessage;
                  String emptySubtitle;
                  IconData emptyIcon;

                  switch (_selectedTab) {
                    case 'my_prayers':
                      emptyMessage = 'Aucune prière personnelle';
                      emptySubtitle = 'Créez votre première prière pour commencer';
                      emptyIcon = Icons.person_outline;
                      break;
                    case 'my_intercessions':
                      emptyMessage = 'Aucune intercession';
                      emptySubtitle = 'Les prières pour lesquelles vous intercédez apparaîtront ici';
                      emptyIcon = Icons.favorite_outline;
                      break;
                    default:
                      emptyMessage = _searchQuery.isNotEmpty
                          ? 'Aucune prière trouvée pour "${_searchQuery}"'
                          : 'Aucune prière pour le moment';
                      emptySubtitle = _searchQuery.isNotEmpty
                          ? 'Essayez d\'ajuster vos critères de recherche'
                          : 'Soyez le premier à partager une prière';
                      emptyIcon = Icons.pan_tool_outlined;
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          emptyIcon,
                          size: 64,
                          color: AppTheme.grey400,
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: AppTheme.fontSize16,
                            color: AppTheme.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          emptySubtitle,
                          style: const TextStyle(color: AppTheme.grey500),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedTab == 'all' || _selectedTab == 'my_prayers') ...[
                          const SizedBox(height: AppTheme.spaceLarge),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToPrayerForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer une prière'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.white100,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadStats();
                    await _loadCategories();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: prayers.length,
                    itemBuilder: (context, index) {
                      final prayer = prayers[index];
                      final user = AuthService.currentUser;
                      final isMyPrayer = user != null && prayer.authorId == user.uid;

                      return PrayerCard(
                        prayer: prayer,
                        onTap: () => _navigateToPrayerDetail(prayer),
                        onEdit: isMyPrayer ? () => _navigateToPrayerForm(prayer) : null,
                        onDelete: isMyPrayer ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text('Êtes-vous sûr de vouloir supprimer cette prière ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.redStandard),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await PrayersFirebaseService.deletePrayer(prayer.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Prière supprimée avec succès'),
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
                        } : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () => _navigateToPrayerForm(),
          tooltip: 'Ajouter une prière',
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: AppTheme.white100),
        ),
      ),
    );
  }
}