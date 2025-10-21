import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  /// Affiche une erreur avec style adaptatif selon la plateforme
  void _showErrorSnackBar(String message) {
    // Feedback haptique d'erreur
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isIOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline_rounded,
              color: AppTheme.onError,
              size: isIOS ? 18 : 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onError,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  letterSpacing: isIOS ? -0.3 : 0,
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
        duration: const Duration(seconds: 4),
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
    // Feedback haptique selon la plateforme
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Construit le bouton de retour en haut adaptatif selon la plateforme
  Widget _buildScrollToTopButton() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return FloatingActionButton(
        heroTag: "scroll_to_top",
        onPressed: _scrollToTop,
        backgroundColor: AppTheme.surface.withOpacity(0.9),
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        child: const Icon(CupertinoIcons.arrow_up, size: 20),
      );
    }

    return FloatingActionButton(
      heroTag: "scroll_to_top",
      onPressed: _scrollToTop,
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.onSurface,
      elevation: AppTheme.elevation2,
      child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
    );
  }

  /// Construit le bouton d'ajout de prière adaptatif selon la plateforme
  Widget _buildAddPrayerButton() {
    void onPressed() {
      // Feedback haptique selon la plateforme
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
      _navigateToForm();
    }

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return FloatingActionButton.extended(
        heroTag: "add_prayer",
        onPressed: onPressed,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        icon: const Icon(CupertinoIcons.add, size: 20),
        label: Text(
          'Nouvelle demande',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      heroTag: "add_prayer",
      onPressed: onPressed,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.onPrimaryColor,
      elevation: AppTheme.elevation3,
      icon: const Icon(Icons.add_rounded, size: 24),
      label: Text(
        'Nouvelle demande',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
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
            _buildScrollToTopButton(),
            const SizedBox(height: AppTheme.spaceSmall),
          ],
          
          // Bouton principal d'ajout - Adaptatif selon la plateforme
          _buildAddPrayerButton(),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: Theme.of(context).platform == TargetPlatform.iOS ? 20 : AppTheme.spaceLarge,
                      vertical: Theme.of(context).platform == TargetPlatform.iOS ? 16 : AppTheme.spaceLarge,
                    ),
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
                              fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 17 : AppTheme.fontSize16,
                              color: AppTheme.onSurface,
                              letterSpacing: Theme.of(context).platform == TargetPlatform.iOS ? -0.4 : 0,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une prière...',
                              hintStyle: GoogleFonts.inter(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 17 : AppTheme.fontSize16,
                                letterSpacing: Theme.of(context).platform == TargetPlatform.iOS ? -0.4 : 0,
                              ),
                              prefixIcon: Icon(
                                Theme.of(context).platform == TargetPlatform.iOS
                                    ? CupertinoIcons.search
                                    : Icons.search_rounded,
                                color: AppTheme.onSurfaceVariant,
                                size: Theme.of(context).platform == TargetPlatform.iOS ? 20 : 24,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        // Feedback haptique selon la plateforme
                                        if (Theme.of(context).platform == TargetPlatform.iOS) {
                                          HapticFeedback.lightImpact();
                                        }
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                      icon: Icon(
                                        Theme.of(context).platform == TargetPlatform.iOS
                                            ? CupertinoIcons.clear_circled_solid
                                            : Icons.clear_rounded,
                                        color: AppTheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      tooltip: 'Effacer la recherche',
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
              padding: EdgeInsets.symmetric(
                horizontal: Theme.of(context).platform == TargetPlatform.iOS ? 20 : AppTheme.spaceLarge,
                vertical: Theme.of(context).platform == TargetPlatform.iOS ? 12 : AppTheme.spaceMedium,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prayer = _filteredPrayers[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _filteredPrayers.length - 1
                            ? (Theme.of(context).platform == TargetPlatform.iOS ? 100 : 80) // Space for FAB
                            : (Theme.of(context).platform == TargetPlatform.iOS ? 16 : 20), // Espacement amélioré entre cartes
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

  /// État de chargement adaptatif selon la plateforme
  Widget _buildLoadingState() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 16,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Chargement des prières...',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );
    }

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
                hasSearch 
                    ? (Theme.of(context).platform == TargetPlatform.iOS 
                        ? CupertinoIcons.search_circle 
                        : Icons.search_off_rounded)
                    : (Theme.of(context).platform == TargetPlatform.iOS 
                        ? CupertinoIcons.heart_circle 
                        : Icons.volunteer_activism_rounded),
                size: Theme.of(context).platform == TargetPlatform.iOS ? 48 : 56,
                color: AppTheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              hasSearch
                  ? 'Aucune prière trouvée'
                  : 'Aucune prière pour le moment',
              style: GoogleFonts.inter(
                fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 19 : AppTheme.fontSize20,
                fontWeight: Theme.of(context).platform == TargetPlatform.iOS ? AppTheme.fontSemiBold : FontWeight.w600,
                color: AppTheme.onSurface,
                letterSpacing: Theme.of(context).platform == TargetPlatform.iOS ? -0.4 : 0,
                height: Theme.of(context).platform == TargetPlatform.iOS ? 1.2 : 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Theme.of(context).platform == TargetPlatform.iOS ? 8 : AppTheme.spaceSmall),
            Text(
              hasSearch
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Soyez le premier à partager une demande de prière',
              style: GoogleFonts.inter(
                fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 15 : AppTheme.fontSize16,
                color: AppTheme.onSurfaceVariant,
                height: Theme.of(context).platform == TargetPlatform.iOS ? 1.3 : 1.4,
                letterSpacing: Theme.of(context).platform == TargetPlatform.iOS ? -0.3 : 0,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: AppTheme.spaceLarge),
              _buildEmptyStateButton(),
            ],
          ],
        ),
      ),
    );
  }

  /// Bouton adaptatif pour l'état vide
  Widget _buildEmptyStateButton() {
    void onPressed() {
      // Feedback haptique selon la plateforme
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
      _navigateToForm();
    }

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLarge,
          vertical: AppTheme.spaceMedium,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 18),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              'Ajouter une prière',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
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
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        'Ajouter une prière',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize16,
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
    );
  }
}
