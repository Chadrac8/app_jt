import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../pages/setlist_detail_page.dart';
import '../../../theme.dart';

/// Onglet Setlists - Material Design 3
class SetlistsTabMD3 extends StatefulWidget {
  const SetlistsTabMD3({super.key});

  @override
  State<SetlistsTabMD3> createState() => _SetlistsTabMD3State();
}

class _SetlistsTabMD3State extends State<SetlistsTabMD3>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  
  String _searchQuery = '';
  String? _selectedSetlistFilter;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Démarrer l'animation des cartes
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête de recherche et filtres
        _buildSearchHeader(),
        
        // Filtres rapides
        _buildQuickFilters(),
        
        // Liste des setlists
        Expanded(
          child: StreamBuilder<List<SetlistModel>>(
            stream: SongsFirebaseService.getSetlists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final allSetlists = snapshot.data ?? [];
              final filteredSetlists = _filterSetlists(allSetlists);

              if (filteredSetlists.isEmpty) {
                return _buildEmptyState(allSetlists.isEmpty);
              }

              return _buildSetlistsList(filteredSetlists);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                border: Border.all(
                  color: _isSearchExpanded 
                      ? colorScheme.primary 
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onTap: () {
                  if (!_isSearchExpanded) {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                    _searchAnimationController.forward();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher une setlist...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _isSearchExpanded = false;
                            });
                            _searchAnimationController.reverse();
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _searchQuery.isNotEmpty || _isSearchExpanded ? 60 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', null),
            const SizedBox(width: AppTheme.space12),
            _buildFilterChip('Cette semaine', 'week'),
            const SizedBox(width: AppTheme.space12),
            _buildFilterChip('Ce mois', 'month'),
            const SizedBox(width: AppTheme.space12),
            _buildFilterChip('Récents', 'recent'),
            const SizedBox(width: AppTheme.space12),
            _buildFilterChip('Favoris', 'favorites'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterType) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedSetlistFilter == filterType;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSetlistFilter = selected ? filterType : null;
        });
      },
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(
        fontSize: AppTheme.fontSize13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected 
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: isSelected 
            ? colorScheme.primary 
            : colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement des setlists...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Impossible de charger les setlists',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            FilledButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Réessayer',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompletelyEmpty ? Icons.playlist_add_outlined : Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              isCompletelyEmpty ? 'Aucune setlist disponible' : 'Aucun résultat',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              isCompletelyEmpty 
                  ? 'Les setlists créées apparaîtront ici'
                  : 'Essayez de modifier votre recherche',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistsList(List<SetlistModel> setlists) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        itemCount: setlists.length,
        itemBuilder: (context, index) {
          final setlist = setlists[index];
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final offset = index * 0.1;
              
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(offset, (offset + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(offset, (offset + 0.3).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                    ),
                  ),
                  child: _buildSetlistCard(setlist, index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSetlistCard(SetlistModel setlist, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        elevation: 0,
        child: InkWell(
          onTap: () => _showSetlistDetails(setlist),
          borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et actions
                Row(
                  children: [
                    // Icône de setlist avec gradient
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.spaceMedium),
                    
                    // Titre et type de service
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setlist.name,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize18,
                              fontWeight: AppTheme.fontBold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          if (setlist.serviceType != null) ...[
                            const SizedBox(height: AppTheme.spaceXSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              ),
                              child: Text(
                                setlist.serviceType!,
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Menu d'actions
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) => _handleSetlistAction(value, setlist),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_rounded,
                                size: 20,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Text(
                                'Voir les détails',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 20,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Text(
                                'Jouer la setlist',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                Icons.share_rounded,
                                size: 20,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Text(
                                'Partager',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 20,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Text(
                                'Dupliquer',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Description si présente
                if (setlist.description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    setlist.description,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Informations et badges
                Row(
                  children: [
                    // Badge de date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppTheme.space6),
                          Text(
                            _formatDate(setlist.serviceDate),
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontSemiBold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.space12),
                    
                    // Badge nombre de chants
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 14,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: AppTheme.space6),
                          Text(
                            '${setlist.songIds.length} chant${setlist.songIds.length > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontSemiBold,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Indicateur de statut
                    _buildSetlistProgress(setlist),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetlistProgress(SetlistModel setlist) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final diff = setlist.serviceDate.difference(now).inDays;
    
    String label;
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (diff > 7) {
      label = 'Planifiée';
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      icon = Icons.schedule_rounded;
    } else if (diff >= 0) {
      label = 'Bientôt';
      backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.7);
      textColor = colorScheme.onErrorContainer;
      icon = Icons.warning_rounded;
    } else if (diff >= -1) {
      label = 'Actuelle';
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      icon = Icons.play_circle_rounded;
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize11,
              fontWeight: AppTheme.fontSemiBold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  List<SetlistModel> _filterSetlists(List<SetlistModel> setlists) {
    var filtered = setlists;

    // Filtrer par recherche textuelle
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((setlist) =>
          setlist.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          setlist.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (setlist.serviceType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Filtrer par période
    if (_selectedSetlistFilter != null) {
      final now = DateTime.now();
      switch (_selectedSetlistFilter) {
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(weekStart) &&
              setlist.serviceDate.isBefore(weekEnd)
          ).toList();
          break;
        case 'month':
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 0);
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(monthStart) &&
              setlist.serviceDate.isBefore(monthEnd)
          ).toList();
          break;
        case 'recent':
          final lastWeek = now.subtract(const Duration(days: 7));
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(lastWeek)
          ).toList();
          break;
        case 'favorites':
          // Pour l'instant, on peut simuler avec les setlists les plus récentes
          // Plus tard, on pourrait ajouter un système de favoris
          filtered = filtered.take(5).toList();
          break;
      }
    }

    // Trier par date de service (plus récent en premier)
    filtered.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    return filtered;
  }

  void _handleSetlistAction(String action, SetlistModel setlist) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetlistDetailPage(setlist: setlist),
          ),
        );
        break;
      case 'play':
        _playSetlist(setlist);
        break;
      case 'share':
        _shareSetlist(setlist);
        break;
      case 'copy':
        _duplicateSetlist(setlist);
        break;
    }
  }

  void _playSetlist(SetlistModel setlist) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (setlist.songIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cette setlist ne contient aucun chant',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
      );
      return;
    }

    try {
      final songs = await SongsFirebaseService.getSetlistSongs(setlist.songIds);
      if (songs.isNotEmpty && mounted) {
        // Pour l'instant, naviguer vers les détails de la setlist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetlistDetailPage(setlist: setlist),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement: $e',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        );
      }
    }
  }

  void _shareSetlist(SetlistModel setlist) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fonctionnalité de partage bientôt disponible',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  void _duplicateSetlist(SetlistModel setlist) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fonctionnalité de duplication bientôt disponible',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  void _showSetlistDetails(SetlistModel setlist) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistDetailPage(setlist: setlist),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}