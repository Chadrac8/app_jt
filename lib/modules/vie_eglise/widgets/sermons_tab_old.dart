import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';
import '../views/sermon_notes_view.dart';
import '../../../theme.dart';

class SermonsTab extends StatefulWidget {
  const SermonsTab({Key? key}) : super(key: key);

  @override
  State<SermonsTab> createState() => _SermonsTabState();
}

class _SermonsTabState extends State<SermonsTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  bool _isLoading = true;
  bool _isSearching = false;
  List<Sermon> _sermons = [];
  List<Sermon> _filteredSermons = [];

  final List<Map<String, dynamic>> _filters = [
    {'key': 'Tous', 'icon': Icons.all_inclusive_rounded},
    {'key': 'Récents', 'icon': Icons.schedule_rounded},
    {'key': 'Avec Écritures & Notes', 'icon': Icons.notes_rounded},
    {'key': 'Avec Vidéo', 'icon': Icons.play_circle_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSermons();
    _loadOrateurs();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState(colorScheme)
                  : _filteredSermons.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : _buildSermonsList(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                ),
                child: Icon(
                  Icons.play_circle_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sermons',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: AppTheme.fontBold,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      'Écoutez et relisez les messages inspirants',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontRegular,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _sermons.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _refreshSermons();
                        break;
                      case 'search':
                        if (mounted) setState(() => _isSearching = true);
                        break;
                      case 'filter':
                        _showFilterDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Actualiser',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Rechercher',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Filtrer',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: AppTheme.space20),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize15,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un sermon, orateur...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: AppTheme.fontSize15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            if (mounted) setState(() => _isSearching = false);
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
          if (_selectedFilter != 'Tous') ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filters.firstWhere((f) => f['key'] == _selectedFilter)['icon'],
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    _selectedFilter,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize13,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  GestureDetector(
                    onTap: () {
                      if (mounted) setState(() => _selectedFilter = 'Tous');
                      _applyFilters();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_isLoading && _sermons.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      '${_filteredSermons.length} sermon${_filteredSermons.length > 1 ? 's' : ''} disponible${_filteredSermons.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize13,
                        fontWeight: AppTheme.fontMedium,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Chargement des sermons...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Veuillez patienter',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainerHigh,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            Text(
              'Aucun sermon trouvé',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Aucun résultat pour "${_searchQuery}"'
                  : _selectedFilter != 'Tous'
                      ? 'Aucun sermon dans cette catégorie'
                      : 'Les sermons apparaîtront ici bientôt',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'Tous') ...[
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.tonal(
                onPressed: () {
                  _clearSearch();
                  setState(() => _selectedFilter = 'Tous');
                  _applyFilters();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                  ),
                ),
                child: Text(
                  'Voir tous les sermons',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSermonsList(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshSermons,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = AppTheme.getGridColumns(screenWidth);
            
            return GridView.builder(
              padding: EdgeInsets.all(AppTheme.adaptivePadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppTheme.gridSpacing,
                mainAxisSpacing: AppTheme.gridSpacing,
                childAspectRatio: AppTheme.isDesktop ? 0.8 : 0.75,
              ),
              itemCount: _filteredSermons.length,
              itemBuilder: (context, index) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOutQuart,
                    ),
                  )),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 0,
                      end: 1,
                    ).animate(CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        (index * 0.1).clamp(0.0, 1.0),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: _buildSermonCard(_filteredSermons[index], index, colorScheme),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSermonCard(Sermon sermon, int index, ColorScheme colorScheme) {
    final borderRadius = BorderRadius.circular(AppTheme.adaptiveBorderRadius);
    
    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: colorScheme.surfaceContainerLow,
        border: AppTheme.isApplePlatform 
          ? Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: AppTheme.actionCardBorderWidth,
            )
          : null,
        boxShadow: AppTheme.isApplePlatform 
          ? null 
          : [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.actionCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(sermon.date),
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                if (sermon.duree > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sermon.duree} min',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize11,
                            fontWeight: AppTheme.fontMedium,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),

            // Titre du sermon
            Text(
              sermon.titre,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space12),

            // Informations d'orateur
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space6),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Text(
                    sermon.orateur,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Description si disponible
            if (sermon.description != null && sermon.description!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  sermon.description!,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Tags si disponibles
            if (sermon.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sermon.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize11,
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: AppTheme.spaceLarge),

            // Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty
                        ? () => _launchYouTube(sermon.lienYoutube!)
                        : null,
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      'Écouter',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: sermon.notes != null && sermon.notes!.isNotEmpty
                        ? () => _showNotes(sermon)
                        : null,
                    icon: Icon(
                      Icons.notes_rounded,
                      size: 18,
                    ),
                    label: Text(
                      'Notes',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Interaction adaptative selon la plateforme
    return AppTheme.isApplePlatform
        ? GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSermonDetails(sermon);
            },
            child: cardContent,
          )
        : Material(
            elevation: 0,
            borderRadius: borderRadius,
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: () => _showSermonDetails(sermon),
              splashColor: colorScheme.primary.withValues(alpha: AppTheme.interactionOpacity),
              child: cardContent,
            ),
          );
  // Méthodes utilitaires et logique métier
  Future<void> _loadSermons() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final sermonsStream = SermonService.getSermons();
      await for (final sermons in sermonsStream.take(1)) {
        if (!mounted) return;
        setState(() {
          _sermons = sermons;
          _isLoading = false;
        });
        await _applyFilters();
        // Déclencher l'animation de la liste après le chargement
        if (_filteredSermons.isNotEmpty) {
          _listAnimationController.forward();
        }
        break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshSermons() async {
    await _loadSermons();
  }

  Future<void> _loadOrateurs() async {
    try {
      final orateurs = await SermonService.getOrateurs();
      // Les orateurs sont chargés pour d'éventuelles futures fonctionnalités
      print('Orateurs disponibles: $orateurs');
    } catch (e) {
      print('Erreur lors du chargement des orateurs: $e');
    }
  }

  Future<void> _applyFilters() async {
    if (!mounted) return;
    
    setState(() {
      _filteredSermons = _sermons.where((sermon) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final searchTerm = _searchQuery.toLowerCase();
          if (!sermon.titre.toLowerCase().contains(searchTerm) &&
              !sermon.orateur.toLowerCase().contains(searchTerm) &&
              !sermon.tags.any((tag) => tag.toLowerCase().contains(searchTerm))) {
            return false;
          }
        }

        // Filtre par catégorie
        switch (_selectedFilter) {
          case 'Récents':
            final now = DateTime.now();
            final thirtyDaysAgo = now.subtract(const Duration(days: 30));
            return sermon.date.isAfter(thirtyDaysAgo);
          case 'Avec Écritures & Notes':
            return sermon.notes != null && sermon.notes!.isNotEmpty;
          case 'Avec Vidéo':
            return sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty;
          default:
            return true;
        }
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _applyFilters();
  }

  void _showSermonDetails(Sermon sermon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppTheme.radius2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête du sermon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy', 'fr_FR').format(sermon.date),
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize13,
                              fontWeight: AppTheme.fontSemiBold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (sermon.duree > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: AppTheme.space6),
                                Text(
                                  '${sermon.duree} min',
                                  style: GoogleFonts.inter(
                                    fontSize: AppTheme.fontSize12,
                                    fontWeight: AppTheme.fontMedium,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLarge),

                    // Titre du sermon
                    Text(
                      sermon.titre,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),

                    // Orateur
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceSmall),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orateur',
                                  style: GoogleFonts.inter(
                                    fontSize: AppTheme.fontSize12,
                                    fontWeight: AppTheme.fontMedium,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sermon.orateur,
                                  style: GoogleFonts.inter(
                                    fontSize: AppTheme.fontSize16,
                                    fontWeight: AppTheme.fontSemiBold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Description si disponible
                    if (sermon.description != null && sermon.description!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceLarge),
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.space20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          sermon.description!,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize15,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // Tags si disponibles
                    if (sermon.tags.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceLarge),
                      Text(
                        'Thèmes',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: sermon.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize13,
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spaceXLarge),

                    // Actions
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty
                                ? () => _launchYouTube(sermon.lienYoutube!)
                                : null,
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: Text(
                              'Écouter le sermon',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize16,
                                fontWeight: AppTheme.fontSemiBold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                              ),
                            ),
                          ),
                        ),
                        if (sermon.notes != null && sermon.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _showNotes(sermon),
                              icon: const Icon(Icons.notes_rounded, size: 20),
                              label: Text(
                                'Voir les Écritures & Notes',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize15,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          'Filtrer les sermons',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) => RadioListTile<String>(
            value: filter['key'],
            groupValue: _selectedFilter,
            onChanged: (value) => Navigator.pop(context, value),
            title: Text(
              filter['key'],
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize15,
                color: colorScheme.onSurface,
              ),
            ),
            secondary: Icon(
              filter['icon'],
              color: _selectedFilter == filter['key'] 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant,
            ),
            activeColor: colorScheme.primary,
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: colorScheme.primary,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result != _selectedFilter) {
      if (mounted) setState(() => _selectedFilter = result);
      _applyFilters();
    }
  }

  Future<void> _launchYouTube(String url) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible d\'ouvrir le lien YouTube',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ouverture du lien',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showNotes(Sermon sermon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonNotesView(sermon: sermon),
      ),
    );
  }
}