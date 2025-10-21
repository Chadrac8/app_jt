import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: isIOS ? 400 : 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: isIOS ? 600 : 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: isIOS ? Curves.easeOut : Curves.easeOutCubic,
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading 
            ? _buildLoadingState(colorScheme, isIOS)
            : _filteredSermons.isEmpty
                ? _buildEmptyStateWithScrollableSearch(colorScheme, isIOS)
                : _buildSermonsListWithScrollableSearch(colorScheme, isIOS),
      ),
    );
  }

  Widget _buildSermonsListWithScrollableSearch(ColorScheme colorScheme, bool isIOS) {
    return RefreshIndicator(
      onRefresh: _refreshSermons,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        physics: isIOS ? const BouncingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Barre de recherche et filtres - Scrolle avec le contenu
          SliverToBoxAdapter(
            child: _buildSearchSection(colorScheme, isIOS),
          ),
          // Liste des sermons
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isIOS ? 20 : AppTheme.spaceLarge,
              vertical: isIOS ? 12 : AppTheme.spaceMedium,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, isIOS ? 0.2 : 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        (index * (isIOS ? 0.08 : 0.1)).clamp(0.0, 1.0),
                        1.0,
                        curve: isIOS ? Curves.easeOutCubic : Curves.easeOutQuart,
                      ),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(CurvedAnimation(
                        parent: _listAnimationController,
                        curve: Interval(
                          (index * (isIOS ? 0.08 : 0.1)).clamp(0.0, 1.0),
                          1.0,
                          curve: isIOS ? Curves.easeOutCubic : Curves.easeOut,
                        ),
                      )),
                      child: _buildSermonCard(_filteredSermons[index], index, colorScheme, isIOS),
                    ),
                  );
                },
                childCount: _filteredSermons.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithScrollableSearch(ColorScheme colorScheme, bool isIOS) {
    return RefreshIndicator(
      onRefresh: _refreshSermons,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        physics: isIOS ? const BouncingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Barre de recherche et filtres - Scrolle avec le contenu
          if (_sermons.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSearchSection(colorScheme, isIOS),
            ),
          // État vide
          SliverFillRemaining(
            child: _buildEmptyStateContent(colorScheme, isIOS),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ColorScheme colorScheme, bool isIOS) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isIOS ? AppTheme.space20 : AppTheme.spaceLarge, 
        isIOS ? AppTheme.spaceMedium : AppTheme.spaceLarge, 
        isIOS ? AppTheme.space20 : AppTheme.spaceLarge, 
        isIOS ? AppTheme.spaceMedium : AppTheme.space20
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: isIOS ? 0.6 : 0.8),
                    borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
                    border: isIOS ? Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 0.5,
                    ) : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: isIOS ? 17 : AppTheme.fontSize16,
                      color: colorScheme.onSurface,
                      letterSpacing: isIOS ? -0.2 : 0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un sermon...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: isIOS ? 17 : AppTheme.fontSize16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: isIOS ? 0.6 : 0.7),
                        letterSpacing: isIOS ? -0.2 : 0,
                      ),
                      prefixIcon: Icon(
                        isIOS ? CupertinoIcons.search : Icons.search_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: isIOS ? 18 : 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: Icon(
                                isIOS ? CupertinoIcons.clear_circled_solid : Icons.clear_rounded,
                                color: colorScheme.onSurfaceVariant,
                                size: isIOS ? 18 : 20,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isIOS ? 16 : 20,
                        vertical: isIOS ? 12 : 16,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isIOS ? AppTheme.space10 : AppTheme.space12),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      _refreshSermons();
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
                          isIOS ? CupertinoIcons.refresh : Icons.refresh_rounded,
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
                    value: 'filter',
                    child: Row(
                      children: [
                        Icon(
                          isIOS ? CupertinoIcons.line_horizontal_3_decrease : Icons.filter_list_rounded,
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
                icon: Container(
                  padding: EdgeInsets.all(isIOS ? AppTheme.space10 : AppTheme.space12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: isIOS ? 0.6 : 0.8),
                    borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXLarge),
                    border: isIOS ? Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 0.5,
                    ) : null,
                  ),
                  child: Icon(
                    isIOS ? CupertinoIcons.slider_horizontal_3 : Icons.tune_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: isIOS ? 18 : 20,
                  ),
                ),
              ),
            ],
          ),
          // Filtre actuel
          if (_selectedFilter != 'Tous') ...[
            SizedBox(height: isIOS ? AppTheme.space10 : AppTheme.space12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isIOS ? 12 : 14, 
                    vertical: isIOS ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: isIOS ? 0.7 : 0.8),
                    borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
                    border: isIOS ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 0.5,
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _filters.firstWhere((f) => f['key'] == _selectedFilter)['icon'],
                        size: isIOS ? 16 : 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      SizedBox(width: isIOS ? AppTheme.space6 : AppTheme.spaceSmall),
                      Text(
                        _selectedFilter,
                        style: GoogleFonts.inter(
                          fontSize: isIOS ? AppTheme.fontSize12 : AppTheme.fontSize13,
                          fontWeight: isIOS ? AppTheme.fontMedium : AppTheme.fontSemiBold,
                          color: colorScheme.onPrimaryContainer,
                          letterSpacing: isIOS ? -0.1 : 0,
                        ),
                      ),
                      SizedBox(width: isIOS ? AppTheme.space6 : AppTheme.spaceSmall),
                      GestureDetector(
                        onTap: () {
                          if (isIOS) HapticFeedback.lightImpact();
                          if (mounted) setState(() => _selectedFilter = 'Tous');
                          _applyFilters();
                        },
                        child: Icon(
                          isIOS ? CupertinoIcons.clear_circled_solid : Icons.close_rounded,
                          size: isIOS ? 14 : 16,
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, bool isIOS) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isIOS ? AppTheme.space20 : AppTheme.spaceLarge),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: isIOS ? 0.2 : 0.3),
              borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusRound),
            ),
            child: isIOS 
                ? CupertinoActivityIndicator(
                    radius: 16,
                    color: colorScheme.primary,
                  )
                : CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    strokeWidth: 3,
                  ),
          ),
          SizedBox(height: isIOS ? AppTheme.space20 : AppTheme.spaceLarge),
          Text(
            'Chargement des sermons...',
            style: GoogleFonts.inter(
              fontSize: isIOS ? 17.0 : AppTheme.fontSize16,
              fontWeight: isIOS ? AppTheme.fontMedium : AppTheme.fontMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: isIOS ? -0.2 : 0,
            ),
          ),
          SizedBox(height: isIOS ? AppTheme.space6 : AppTheme.spaceSmall),
          Text(
            'Veuillez patienter',
            style: GoogleFonts.inter(
              fontSize: isIOS ? AppTheme.fontSize13 : AppTheme.fontSize14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: isIOS ? 0.6 : 0.7),
              letterSpacing: isIOS ? -0.1 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent(ColorScheme colorScheme, bool isIOS) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isIOS ? AppTheme.spaceXLarge : AppTheme.space40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isIOS ? AppTheme.spaceLarge + AppTheme.spaceSmall : AppTheme.spaceXLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainerHigh,
                  ],
                ),
                borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusXLarge : 40),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: isIOS ? 0.06 : 0.1),
                    blurRadius: isIOS ? 12 : 20,
                    offset: Offset(0, isIOS ? 4 : 8),
                  ),
                ],
              ),
              child: Icon(
                isIOS ? CupertinoIcons.play_circle : Icons.play_circle_outline_rounded,
                size: isIOS ? 56 : 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isIOS ? AppTheme.spaceLarge : AppTheme.spaceXLarge),
            Text(
              'Aucun sermon trouvé',
              style: GoogleFonts.inter(
                fontSize: isIOS ? AppTheme.fontSize22 : AppTheme.fontSize20,
                fontWeight: isIOS ? AppTheme.fontSemiBold : AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
                letterSpacing: isIOS ? -0.3 : 0,
              ),
            ),
            SizedBox(height: isIOS ? AppTheme.space10 : AppTheme.spaceSmall),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Aucun résultat pour "${_searchQuery}"'
                  : _selectedFilter != 'Tous'
                      ? 'Aucun sermon dans cette catégorie'
                      : 'Les sermons apparaîtront ici bientôt',
              style: GoogleFonts.inter(
                fontSize: isIOS ? AppTheme.fontSize15 : AppTheme.fontSize14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: isIOS ? 0.75 : 0.8),
                letterSpacing: isIOS ? -0.1 : 0,
                height: isIOS ? 1.3 : 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'Tous') ...[
              SizedBox(height: isIOS ? AppTheme.space20 : AppTheme.spaceLarge),
              isIOS 
                  ? CupertinoButton.filled(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _clearSearch();
                        setState(() => _selectedFilter = 'Tous');
                        _applyFilters();
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        'Voir tous les sermons',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize15,
                          fontWeight: AppTheme.fontMedium,
                          letterSpacing: -0.1,
                        ),
                      ),
                    )
                  : FilledButton.tonal(
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



  Widget _buildSermonCard(Sermon sermon, int index, ColorScheme colorScheme, bool isIOS) {
    return Container(
      margin: EdgeInsets.only(
        bottom: index == _filteredSermons.length - 1
            ? (isIOS ? 100 : 80) // Space for FAB
            : (isIOS ? 20 : 24), // Espacement généreux et professionnel
      ),
      child: _ProfessionalSermonCard(
        sermon: sermon,
        colorScheme: colorScheme,
        isIOS: isIOS,
        onTap: () {
          if (isIOS) HapticFeedback.lightImpact();
          _showSermonDetails(sermon);
        },
        onPlayTap: sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty
            ? () {
                if (isIOS) HapticFeedback.lightImpact();
                _launchYouTube(sermon.lienYoutube!);
              }
            : null,
        onNotesTap: () {
          if (isIOS) HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SermonNotesView(sermon: sermon),
            ),
          );
        },
      ),
    );
  }
                        padding: EdgeInsets.symmetric(),
                        decoration: BoxDecoration(
                          color = _getSermonTypeColor(sermon, colorScheme).withOpacity(isIOS ? 0.15 : 0.12),
                          borderRadius = BorderRadius.circular(isIOS ? 8 : AppTheme.radiusXLarge),
                          border = isIOS ? Border.all(
                            color: _getSermonTypeColor(sermon, colorScheme).withOpacity(0.3),
                            width: 0.5,
                          ) : null,
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(sermon.date),
                          style: GoogleFonts.inter(
                            fontSize: isIOS ? 11 : AppTheme.fontSize12,
                            fontWeight: isIOS ? FontWeight.w600 : AppTheme.fontSemiBold,
                            color: _getSermonTypeColor(sermon, colorScheme),
                            letterSpacing: isIOS ? -0.2 : 0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (sermon.duree, > 0)
                        Container(
                          padding = EdgeInsets.symmetric(
                            horizontal: isIOS ? 8 : 10,
                            vertical: isIOS ? 4 : 6,
                          ),
                          decoration = BoxDecoration(
                            color: colorScheme.secondaryContainer.withOpacity(isIOS ? 0.8 : 1.0),
                            borderRadius: BorderRadius.circular(isIOS ? 6 : AppTheme.radiusLarge),
                          ),
                          child = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: AppTheme.spaceXSmall),
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
                  const SizedBox(height = AppTheme.space20),

                  // Titre du sermon
                  Text(
                    sermon.titre,
                    style = GoogleFonts.inter(
                      fontSize: isIOS ? AppTheme.fontSize20 : AppTheme.fontSize18,
                      fontWeight: isIOS ? AppTheme.fontSemiBold : AppTheme.fontSemiBold,
                      color: colorScheme.onSurface,
                      height: isIOS ? 1.25 : 1.3,
                      letterSpacing: isIOS ? -0.3 : 0,
                    ),
                    maxLines = 2,
                    overflow = TextOverflow.ellipsis,
                  ),
                  SizedBox(height = isIOS ? AppTheme.space10 : AppTheme.space12),

                  // Informations d'orateur
                  Row(
                    children = [
                      Container(
                        padding: EdgeInsets.all(isIOS ? 7 : AppTheme.space6),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withOpacity(isIOS ? 0.8 : 1.0),
                          borderRadius: BorderRadius.circular(isIOS ? 6 : AppTheme.radiusMedium),
                          border: isIOS ? Border.all(
                            color: colorScheme.onTertiaryContainer.withOpacity(0.1),
                            width: 0.5,
                          ) : null,
                        ),
                        child: Icon(
                          isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
                          size: isIOS ? 14 : 16,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      SizedBox(width: isIOS ? AppTheme.space12 : AppTheme.space10),
                      Expanded(
                        child: Text(
                          sermon.orateur,
                          style: GoogleFonts.inter(
                            fontSize: isIOS ? AppTheme.fontSize15 : AppTheme.fontSize14,
                            fontWeight: isIOS ? AppTheme.fontMedium : AppTheme.fontMedium,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: isIOS ? -0.1 : 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Description si disponible
                  if (sermon.description != null && sermon.description!.isNotEmpty) ...[
                    const SizedBox(height = AppTheme.spaceMedium),
                    Container(
                      padding = const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration = BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child = Text(
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
                    const SizedBox(height = AppTheme.spaceMedium),
                    Wrap(
                      spacing = 8,
                      runSpacing = 8,
                      children = sermon.tags.take(3).map((tag) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isIOS ? 10 : 12, 
                          vertical: isIOS ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(alpha: isIOS ? 0.6 : 0.7),
                          borderRadius: BorderRadius.circular(isIOS ? 12 : AppTheme.radiusXLarge),
                          border: isIOS ? Border.all(
                            color: colorScheme.onSecondaryContainer.withOpacity(0.1),
                            width: 0.5,
                          ) : null,
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: isIOS ? 10 : AppTheme.fontSize11,
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: isIOS ? FontWeight.w600 : AppTheme.fontMedium,
                            letterSpacing: isIOS ? -0.1 : 0,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height = AppTheme.spaceLarge),

                  // Actions
                  Row(
                    children = [
                      Expanded(
                        child: isIOS 
                            ? CupertinoButton.filled(
                                onPressed: sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty
                                    ? () {
                                        HapticFeedback.lightImpact();
                                        _launchYouTube(sermon.lienYoutube!);
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.play_fill,
                                      size: 18,
                                    ),
                                    const SizedBox(width: AppTheme.spaceSmall),
                                    Text(
                                      'Écouter',
                                      style: GoogleFonts.inter(
                                        fontSize: AppTheme.fontSize15,
                                        fontWeight: AppTheme.fontMedium,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FilledButton.icon(
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
                      SizedBox(width: isIOS ? AppTheme.space10 : AppTheme.space12),
                      Expanded(
                        child: isIOS 
                            ? CupertinoButton(
                                onPressed: sermon.notes != null && sermon.notes!.isNotEmpty
                                    ? () {
                                        HapticFeedback.lightImpact();
                                        _showNotes(sermon);
                                      }
                                    : null,
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc_text_fill,
                                      size: 16,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: AppTheme.spaceSmall),
                                    Text(
                                      'Notes',
                                      style: GoogleFonts.inter(
                                        fontSize: AppTheme.fontSize15,
                                        fontWeight: AppTheme.fontMedium,
                                        color: colorScheme.onSecondaryContainer,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FilledButton.tonalIcon(
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
          ),
        ),
    );
  }

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
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    // Feedback haptique sur iOS
    if (isIOS) {
      HapticFeedback.lightImpact();
    }
    
    isIOS 
        ? showCupertinoModalPopup<void>(
            context: context,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: _buildSermonDetailsContent(sermon, colorScheme, isIOS),
            ),
          )
        : showModalBottomSheet(
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
              child: _buildSermonDetailsContent(sermon, colorScheme, isIOS),
            ),
          );
  }

  Widget _buildSermonDetailsContent(Sermon sermon, ColorScheme colorScheme, bool isIOS) {
    return Column(
      children: [
        // Handle pour Android ou barre de navigation pour iOS
        if (isIOS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      color: colorScheme.primary,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                ),
                Text(
                  'Détails du sermon',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 80), // Pour équilibrer le layout
              ],
            ),
          )
        else
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
            physics: isIOS ? const BouncingScrollPhysics() : null,
            padding: EdgeInsets.fromLTRB(
              isIOS ? 20 : 24, 
              isIOS ? 8 : 0, 
              isIOS ? 20 : 24, 
              isIOS ? 40 : 32
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSermonDetailsSections(sermon, colorScheme, isIOS),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSermonDetailsSections(Sermon sermon, ColorScheme colorScheme, bool isIOS) {
    return [
      // En-tête du sermon
      Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isIOS ? 14 : 16, 
              vertical: isIOS ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy', 'fr_FR').format(sermon.date),
              style: GoogleFonts.inter(
                fontSize: isIOS ? AppTheme.fontSize12 : AppTheme.fontSize13,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onPrimaryContainer,
                letterSpacing: isIOS ? -0.1 : 0,
              ),
            ),
          ),
          const Spacer(),
          if (sermon.duree > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isIOS ? 10 : 12, 
                vertical: isIOS ? 6 : 8
              ),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusMedium : AppTheme.radiusXLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIOS ? CupertinoIcons.clock_fill : Icons.access_time_rounded,
                    size: isIOS ? 14 : 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  SizedBox(width: isIOS ? AppTheme.spaceXSmall : AppTheme.space6),
                  Text(
                    '${sermon.duree} min',
                    style: GoogleFonts.inter(
                      fontSize: isIOS ? AppTheme.fontSize11 : AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: colorScheme.onSecondaryContainer,
                      letterSpacing: isIOS ? -0.1 : 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      SizedBox(height: isIOS ? AppTheme.space20 : AppTheme.spaceLarge),

      // Titre du sermon
      Text(
        sermon.titre,
        style: GoogleFonts.inter(
          fontSize: isIOS ? AppTheme.fontSize28 : AppTheme.fontSize24,
          fontWeight: isIOS ? AppTheme.fontSemiBold : AppTheme.fontBold,
          color: colorScheme.onSurface,
          height: isIOS ? 1.1 : 1.2,
          letterSpacing: isIOS ? -0.4 : 0,
        ),
      ),
      SizedBox(height: isIOS ? AppTheme.space12 : AppTheme.spaceMedium),

      // Orateur
      Container(
        padding: EdgeInsets.all(isIOS ? AppTheme.space12 : AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: isIOS ? 0.4 : 0.3),
          borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
          border: isIOS ? null : Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isIOS ? AppTheme.space6 : AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusSmall : AppTheme.radiusLarge),
              ),
              child: Icon(
                isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
                size: isIOS ? 18 : 20,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            SizedBox(width: isIOS ? AppTheme.space12 : AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orateur',
                    style: GoogleFonts.inter(
                      fontSize: isIOS ? AppTheme.fontSize11 : AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: isIOS ? -0.1 : 0,
                    ),
                  ),
                  SizedBox(height: isIOS ? 1 : 2),
                  Text(
                    sermon.orateur,
                    style: GoogleFonts.inter(
                      fontSize: isIOS ? 17 : AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onSurface,
                      letterSpacing: isIOS ? -0.2 : 0,
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
        SizedBox(height: isIOS ? AppTheme.space20 : AppTheme.spaceLarge),
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: isIOS ? 17 : AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onSurface,
            letterSpacing: isIOS ? -0.2 : 0,
          ),
        ),
        SizedBox(height: isIOS ? AppTheme.space10 : AppTheme.space12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isIOS ? AppTheme.spaceMedium : AppTheme.space20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
            border: isIOS ? null : Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            sermon.description!,
            style: GoogleFonts.inter(
              fontSize: isIOS ? AppTheme.fontSize15 : AppTheme.fontSize15,
              color: colorScheme.onSurfaceVariant,
              height: isIOS ? 1.4 : 1.5,
              letterSpacing: isIOS ? -0.1 : 0,
            ),
          ),
        ),
      ],

      // Tags si disponibles
      if (sermon.tags.isNotEmpty) ...[
        SizedBox(height: isIOS ? AppTheme.space20 : AppTheme.spaceLarge),
        Text(
          'Thèmes',
          style: GoogleFonts.inter(
            fontSize: isIOS ? 17 : AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onSurface,
            letterSpacing: isIOS ? -0.2 : 0,
          ),
        ),
        SizedBox(height: isIOS ? AppTheme.space10 : AppTheme.space12),
        Wrap(
          spacing: isIOS ? 10 : 12,
          runSpacing: isIOS ? 6 : 8,
          children: sermon.tags.map((tag) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: isIOS ? 12 : 16, 
              vertical: isIOS ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusXXLarge),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: isIOS ? AppTheme.fontSize12 : AppTheme.fontSize13,
                color: colorScheme.onSecondaryContainer,
                fontWeight: AppTheme.fontMedium,
                letterSpacing: isIOS ? -0.1 : 0,
              ),
            ),
          )).toList(),
        ),
      ],

      SizedBox(height: isIOS ? AppTheme.spaceLarge + AppTheme.spaceSmall : AppTheme.spaceXLarge),

      // Actions
      _buildSermonActions(sermon, colorScheme, isIOS),
    ];
  }

  Widget _buildSermonActions(Sermon sermon, ColorScheme colorScheme, bool isIOS) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: isIOS 
              ? CupertinoButton.filled(
                  onPressed: sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty
                      ? () {
                          HapticFeedback.lightImpact();
                          _launchYouTube(sermon.lienYoutube!);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.play_fill,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Écouter le sermon',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: AppTheme.fontMedium,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton.icon(
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
          SizedBox(height: isIOS ? AppTheme.space10 : AppTheme.space12),
          SizedBox(
            width: double.infinity,
            child: isIOS 
                ? CupertinoButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showNotes(sermon);
                    },
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(
                          'Voir les Écritures & Notes',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize15,
                            fontWeight: AppTheme.fontMedium,
                            color: colorScheme.onSecondaryContainer,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  )
                : FilledButton.tonalIcon(
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
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    // Feedback haptique sur iOS
    if (isIOS) {
      HapticFeedback.mediumImpact();
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        if (mounted) {
          _showErrorSnackBar(
            'Impossible d\'ouvrir le lien YouTube',
            colorScheme,
            isIOS,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Erreur lors de l\'ouverture du lien',
          colorScheme,
          isIOS,
        );
      }
    }
  }

  /// Couleur de type du sermon basée sur sa catégorie ou ses caractéristiques
  Color _getSermonTypeColor(Sermon sermon, ColorScheme colorScheme) {
    // Classification selon la durée et le contenu
    if (sermon.duree > 60) {
      return colorScheme.primary; // Sermons longs - couleur primaire
    } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('témoignage') || 
                                     tag.toLowerCase().contains('testimony'))) {
      return colorScheme.tertiary; // Témoignages - couleur tertiaire
    } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('enseignement') ||
                                     tag.toLowerCase().contains('étude'))) {
      return colorScheme.secondary; // Enseignements - couleur secondaire
    } else {
      return colorScheme.primary; // Par défaut - couleur primaire
    }
  }

  /// Couleur de fond de la carte selon le type et la plateforme
  Color _getSermonCardBackgroundColor(Sermon sermon, ColorScheme colorScheme, bool isIOS) {
    final baseColor = colorScheme.surfaceContainerLow;
    
    if (isIOS) {
      // iOS : fond très subtil pour distinction
      if (sermon.duree > 60) {
        return baseColor;
      } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('témoignage'))) {
        return Color.lerp(baseColor, colorScheme.tertiaryContainer, 0.02) ?? baseColor;
      } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('enseignement'))) {
        return Color.lerp(baseColor, colorScheme.secondaryContainer, 0.02) ?? baseColor;
      } else {
        return baseColor;
      }
    } else {
      // Android : fond légèrement teinté pour MD3
      if (sermon.duree > 60) {
        return baseColor;
      } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('témoignage'))) {
        return Color.lerp(baseColor, colorScheme.tertiaryContainer, 0.05) ?? baseColor;
      } else if (sermon.tags.any((tag) => tag.toLowerCase().contains('enseignement'))) {
        return Color.lerp(baseColor, colorScheme.secondaryContainer, 0.05) ?? baseColor;
      } else {
        return baseColor;
      }
    }
  }

  void _showErrorSnackBar(String message, ColorScheme colorScheme, bool isIOS) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isIOS ? CupertinoIcons.exclamationmark_triangle_fill : Icons.error_outline,
              color: colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: isIOS ? AppTheme.fontSize15 : AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  letterSpacing: isIOS ? -0.1 : 0,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? AppTheme.radiusLarge : AppTheme.radiusMedium),
        ),
        margin: EdgeInsets.all(isIOS ? AppTheme.spaceMedium : AppTheme.space12),
      ),
    );
  }

  void _showNotes(Sermon sermon) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    // Feedback haptique sur iOS
    if (isIOS) {
      HapticFeedback.lightImpact();
    }
    
    Navigator.push(
      context,
      isIOS 
          ? CupertinoPageRoute(
              builder: (context) => SermonNotesView(sermon: sermon),
            )
          : MaterialPageRoute(
              builder: (context) => SermonNotesView(sermon: sermon),
            ),
    );
  }
}

/// Carte de sermon professionnelle conforme MD3/HIG
class _ProfessionalSermonCard extends StatefulWidget {
  final Sermon sermon;
  final ColorScheme colorScheme;
  final bool isIOS;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback onNotesTap;

  const _ProfessionalSermonCard({
    required this.sermon,
    required this.colorScheme,
    required this.isIOS,
    required this.onTap,
    this.onPlayTap,
    required this.onNotesTap,
  });

  @override
  State<_ProfessionalSermonCard> createState() => _ProfessionalSermonCardState();
}

class _ProfessionalSermonCardState extends State<_ProfessionalSermonCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.isIOS ? 200 : 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isIOS ? 0.96 : 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.isIOS ? Curves.easeOut : Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.isIOS ? 0.0 : 1.0,
      end: widget.isIOS ? 0.0 : 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getSermonTypeColor() {
    final hasVideo = widget.sermon.lienYoutube?.isNotEmpty == true;
    final hasNotes = widget.sermon.notes?.isNotEmpty == true;
    final hasTags = widget.sermon.tags.isNotEmpty;

    if (hasVideo && hasNotes && hasTags) {
      return widget.colorScheme.primary; // Complet
    } else if (hasVideo && (hasNotes || hasTags)) {
      return widget.colorScheme.secondary; // Riche
    } else if (hasVideo) {
      return widget.colorScheme.tertiary; // Avec vidéo
    } else {
      return widget.colorScheme.outline; // Basique
    }
  }

  String _getSermonTypeLabel() {
    final hasVideo = widget.sermon.lienYoutube?.isNotEmpty == true;
    final hasNotes = widget.sermon.notes?.isNotEmpty == true;
    final hasTags = widget.sermon.tags.isNotEmpty;

    if (hasVideo && hasNotes && hasTags) {
      return 'Complet';
    } else if (hasVideo && (hasNotes || hasTags)) {
      return 'Enrichi';
    } else if (hasVideo) {
      return 'Vidéo';
    } else {
      return 'Sermon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sermonTypeColor = _getSermonTypeColor();
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isIOS ? 16 : 20),
              boxShadow: widget.isIOS ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Material(
              elevation: _elevationAnimation.value,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(widget.isIOS ? 16 : 20),
              color: widget.colorScheme.surfaceContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.isIOS ? 16 : 20),
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: Padding(
                  padding: EdgeInsets.all(widget.isIOS ? 20 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec date et durée
                      Row(
                        children: [
                          // Badge de type de sermon
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isIOS ? 12 : 16,
                              vertical: widget.isIOS ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: sermonTypeColor.withValues(alpha: widget.isIOS ? 0.15 : 0.12),
                              borderRadius: BorderRadius.circular(widget.isIOS ? 8 : 12),
                              border: widget.isIOS ? Border.all(
                                color: sermonTypeColor.withValues(alpha: 0.3),
                                width: 0.5,
                              ) : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSermonTypeIcon(),
                                  size: widget.isIOS ? 14 : 16,
                                  color: sermonTypeColor,
                                ),
                                SizedBox(width: widget.isIOS ? 6 : 8),
                                Text(
                                  _getSermonTypeLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: widget.isIOS ? 12 : 13,
                                    fontWeight: AppTheme.fontSemiBold,
                                    color: sermonTypeColor,
                                    letterSpacing: widget.isIOS ? -0.2 : 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Date
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isIOS ? 10 : 12,
                              vertical: widget.isIOS ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(widget.isIOS ? 6 : 8),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yy').format(widget.sermon.date),
                              style: GoogleFonts.inter(
                                fontSize: widget.isIOS ? 11 : 12,
                                fontWeight: AppTheme.fontMedium,
                                color: widget.colorScheme.onSurfaceVariant,
                                letterSpacing: widget.isIOS ? -0.1 : 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: widget.isIOS ? 16 : 20),
                      
                      // Titre du sermon
                      Text(
                        widget.sermon.titre,
                        style: GoogleFonts.inter(
                          fontSize: widget.isIOS ? 20 : 18,
                          fontWeight: AppTheme.fontSemiBold,
                          color: widget.colorScheme.onSurface,
                          height: widget.isIOS ? 1.25 : 1.3,
                          letterSpacing: widget.isIOS ? -0.4 : 0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: widget.isIOS ? 12 : 14),
                      
                      // Orateur avec icône
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(widget.isIOS ? 8 : 10),
                            decoration: BoxDecoration(
                              color: widget.colorScheme.primaryContainer.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(widget.isIOS ? 8 : 10),
                            ),
                            child: Icon(
                              widget.isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
                              size: widget.isIOS ? 16 : 18,
                              color: widget.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(width: widget.isIOS ? 12 : 14),
                          Expanded(
                            child: Text(
                              widget.sermon.orateur,
                              style: GoogleFonts.inter(
                                fontSize: widget.isIOS ? 16 : 15,
                                fontWeight: AppTheme.fontMedium,
                                color: widget.colorScheme.onSurfaceVariant,
                                letterSpacing: widget.isIOS ? -0.2 : 0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Durée si disponible
                          if (widget.sermon.duree > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.isIOS ? 8 : 10,
                                vertical: widget.isIOS ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.colorScheme.secondaryContainer.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(widget.isIOS ? 6 : 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: widget.colorScheme.onSecondaryContainer,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.sermon.duree}min',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: AppTheme.fontMedium,
                                      color: widget.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      // Description si disponible
                      if (widget.sermon.description?.isNotEmpty == true) ...[
                        SizedBox(height: widget.isIOS ? 14 : 16),
                        Container(
                          padding: EdgeInsets.all(widget.isIOS ? 12 : 14),
                          decoration: BoxDecoration(
                            color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(widget.isIOS ? 10 : 12),
                            border: Border.all(
                              color: widget.colorScheme.outline.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            widget.sermon.description!,
                            style: GoogleFonts.inter(
                              fontSize: widget.isIOS ? 14 : 13,
                              color: widget.colorScheme.onSurfaceVariant,
                              height: 1.4,
                              letterSpacing: widget.isIOS ? -0.1 : 0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      
                      SizedBox(height: widget.isIOS ? 18 : 20),
                      
                      // Actions en bas
                      Row(
                        children: [
                          // Bouton principal d'écoute
                          Expanded(
                            flex: 2,
                            child: _buildActionButton(
                              onPressed: widget.onPlayTap,
                              icon: widget.isIOS ? CupertinoIcons.play_fill : Icons.play_arrow_rounded,
                              label: 'Écouter',
                              isPrimary: true,
                              isEnabled: widget.onPlayTap != null,
                            ),
                          ),
                          
                          SizedBox(width: widget.isIOS ? 12 : 14),
                          
                          // Bouton notes
                          Expanded(
                            child: _buildActionButton(
                              onPressed: widget.onNotesTap,
                              icon: widget.isIOS ? CupertinoIcons.doc_text : Icons.notes_rounded,
                              label: 'Notes',
                              isPrimary: false,
                              isEnabled: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isEnabled,
  }) {
    final backgroundColor = isPrimary
        ? (isEnabled ? widget.colorScheme.primary : widget.colorScheme.surfaceContainerHighest)
        : widget.colorScheme.surfaceContainerHigh;
    
    final foregroundColor = isPrimary
        ? (isEnabled ? widget.colorScheme.onPrimary : widget.colorScheme.onSurfaceVariant)
        : widget.colorScheme.onSurfaceVariant;

    return Container(
      height: widget.isIOS ? 44 : 48,
      child: widget.isIOS 
          ? CupertinoButton(
              onPressed: isEnabled ? onPressed : null,
              padding: EdgeInsets.zero,
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: foregroundColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: foregroundColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              onPressed: isEnabled ? onPressed : null,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: isPrimary ? 2 : 0,
                shadowColor: isPrimary ? widget.colorScheme.primary.withValues(alpha: 0.3) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
    );
  }

  IconData _getSermonTypeIcon() {
    final hasVideo = widget.sermon.lienYoutube?.isNotEmpty == true;
    final hasNotes = widget.sermon.notes?.isNotEmpty == true;
    final hasTags = widget.sermon.tags.isNotEmpty;

    if (hasVideo && hasNotes && hasTags) {
      return widget.isIOS ? CupertinoIcons.star_fill : Icons.star_rounded;
    } else if (hasVideo && (hasNotes || hasTags)) {
      return widget.isIOS ? CupertinoIcons.play_rectangle_fill : Icons.play_circle_filled_rounded;
    } else if (hasVideo) {
      return widget.isIOS ? CupertinoIcons.videocam_fill : Icons.videocam_rounded;
    } else {
      return widget.isIOS ? CupertinoIcons.mic_fill : Icons.mic_rounded;
    }
  }
}