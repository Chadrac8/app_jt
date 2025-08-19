import 'package:flutter/material.dart';
import '../../../models/prayer_model.dart';
import '../../../services/prayers_firebase_service.dart';
import '../../../widgets/prayer_card.dart';
import '../../../widgets/prayer_search_filter_bar.dart';
import '../../../theme.dart';
import '../../../auth/auth_service.dart';
import '../../../pages/prayer_form_page.dart';
import '../../../pages/prayer_detail_page.dart';

/// Onglet "Prières & Témoignages" du module Vie de l'église
/// Version adaptée du MemberPrayerWallPage pour l'intégration dans les onglets
class PrayerWallTab extends StatefulWidget {
  const PrayerWallTab({Key? key}) : super(key: key);

  @override
  State<PrayerWallTab> createState() => _PrayerWallTabState();
}

class _PrayerWallTabState extends State<PrayerWallTab>
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
  
  List<String> _availableCategories = [];

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

    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      final categories = await PrayersFirebaseService.getUsedCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategory = null;
      _searchController.clear();
    });
  }

  Stream<List<PrayerModel>> _getPrayersStream() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    if (_selectedTab == 'my') {
      return PrayersFirebaseService.getUserPrayersStream();
    } else {
      // Utiliser la méthode simplifiée pour éviter les erreurs d'index
      if (_selectedType == null && _selectedCategory == null && _searchQuery.isEmpty) {
        // Cas simple : utiliser le stream simplifié
        return PrayersFirebaseService.getSimplePrayersStream(limit: 100);
      } else {
        // Cas avec filtres : utiliser la méthode optimisée
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sélecteur d'onglets
          _buildTabSelector(),

          // Espacement entre le sélecteur et la section suivante
          const SizedBox(height: 16),

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
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
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
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadCategories();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: prayers.length,
                    itemBuilder: (context, index) {
                      final prayer = prayers[index];
                      return PrayerCard(
                        prayer: prayer,
                        onTap: () => _navigateToDetail(prayer),
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
          onPressed: _navigateToAddPrayer,
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'all',
              'Toutes',
              Icons.list,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'my',
              'Mes prières',
              Icons.person,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    final isSelected = _selectedTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune prière trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager une intention de prière',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddPrayer,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une prière'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(PrayerModel prayer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrayerDetailPage(prayer: prayer),
      ),
    );
  }

  void _navigateToAddPrayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerFormPage(),
      ),
    );
  }
}
