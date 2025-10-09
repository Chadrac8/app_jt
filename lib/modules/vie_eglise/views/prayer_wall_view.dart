import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../../../models/prayer_model.dart';
import '../../../services/prayers_firebase_service.dart';
import '../widgets/prayer_request_card.dart';
import '../widgets/prayer_filter_widget.dart';
import 'prayer_request_form_view.dart';
import 'prayer_request_details_view.dart';

/// Vue principale du mur de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerWallView extends StatefulWidget {
  const PrayerWallView({super.key});

  @override
  State<PrayerWallView> createState() => _PrayerWallViewState();
}

class _PrayerWallViewState extends State<PrayerWallView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PrayerModel> _prayers = [];
  List<PrayerModel> _filteredPrayers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PrayerType? _selectedType;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadPrayers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Détecter si l'utilisateur a scrollé au-delà de la zone de recherche
      final hasScrolledPastSearch = _scrollController.offset > 200;
      
      // Afficher/masquer le bouton de retour en haut
      if (hasScrolledPastSearch != !_showFab) {
        setState(() => _showFab = !hasScrolledPastSearch);
      }
    });
  }

  Future<void> _loadPrayers() async {
    try {
      setState(() => _isLoading = true);

      PrayersFirebaseService.getPrayersStream().listen((prayers) {
        if (mounted) {
          setState(() {
            _prayers = prayers
                .where((p) => p.isApproved && !p.isArchived)
                .toList();
            _isLoading = false;
          });
          _applyFilters();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement: ${e.toString()}');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPrayers = _prayers.where((prayer) {
        if (_selectedType != null && prayer.type != _selectedType) {
          return false;
        }

        if (_searchQuery.isNotEmpty) {
          final searchTerm = _searchQuery.toLowerCase();
          return prayer.title.toLowerCase().contains(searchTerm) ||
              prayer.content.toLowerCase().contains(searchTerm) ||
              prayer.authorName.toLowerCase().contains(searchTerm);
        }

        return true;
      }).toList();

      _filteredPrayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(PrayerType? type) {
    setState(() => _selectedType = type);
    _applyFilters();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.onError,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onError,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrayerRequestFormView(),
      ),
    );

    if (result == true) {
      _loadPrayers();
    }
  }

  void _navigateToDetails(PrayerModel prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerRequestDetailsView(prayer: prayer),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton de retour en haut (quand on a scrollé)
          if (!_showFab) ...[
            FloatingActionButton(
              heroTag: "scroll_to_top",
              onPressed: _scrollToTop,
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.onSurface,
              elevation: AppTheme.elevation2,
              child: const Icon(Icons.search, size: 20),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
          ],
          
          // Bouton principal d'ajout
          FloatingActionButton.extended(
            heroTag: "add_prayer",
            onPressed: _navigateToForm,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.onPrimaryColor,
            elevation: AppTheme.elevation3,
            icon: const Icon(Icons.add, size: 24),
            label: Text(
              'Nouvelle demande',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadPrayers,
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surface,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header avec recherche et filtres
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.background,
              child: Column(
                children: [
                  // Barre de recherche et filtres
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLarge),
                    child: Column(
                      children: [
                        // Barre de recherche
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                            border: Border.all(
                              color: AppTheme.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize16,
                              color: AppTheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une prière...',
                              hintStyle: GoogleFonts.inter(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: AppTheme.fontSize16,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppTheme.onSurfaceVariant,
                                size: 24,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: AppTheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceLarge,
                                vertical: AppTheme.spaceMedium,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceMedium),

                        // Filtres par catégorie
                        PrayerFilterWidget(
                          selectedType: _selectedType,
                          onFilterChanged: _onFilterChanged,
                        ),
                      ],
                    ),
                  ),
                  // Séparateur subtil pour délimiter la zone de recherche
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                ],
              ),
            ),
          ),

          // Liste des prières
          if (_filteredPrayers.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prayer = _filteredPrayers[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _filteredPrayers.length - 1
                            ? 80 // Space for FAB
                            : AppTheme.spaceMedium,
                      ),
                      child: PrayerRequestCard(
                        prayer: prayer,
                        onTap: () => _navigateToDetails(prayer),
                      ),
                    );
                  },
                  childCount: _filteredPrayers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Chargement des prières...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty || _selectedType != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.volunteer_activism,
                size: 56,
                color: AppTheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              hasSearch
                  ? 'Aucune prière trouvée'
                  : 'Aucune prière pour le moment',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              hasSearch
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Soyez le premier à partager une demande de prière',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.icon(
                onPressed: _navigateToForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLarge,
                    vertical: AppTheme.spaceMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Ajouter une prière',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
