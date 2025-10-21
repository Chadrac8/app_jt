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
    {'key': 'Avec Notes', 'icon': Icons.notes_rounded},
    {'key': 'Avec Vidéo', 'icon': Icons.play_circle_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSermons();
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
                ? _buildEmptyState(colorScheme, isIOS)
                : _buildSermonsListWithScrollableSearch(colorScheme, isIOS),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, bool isIOS) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isIOS)
            CupertinoActivityIndicator(radius: 20)
          else
            CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Chargement des sermons...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isIOS) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIOS ? CupertinoIcons.music_note_2 : Icons.music_note_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun sermon trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
          // Barre de recherche et filtres
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
          // Barre de recherche
          Container(
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
          
          const SizedBox(height: 16),
          
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      filter['key'],
                      style: GoogleFonts.inter(
                        fontSize: isIOS ? 14 : 13,
                        fontWeight: isSelected ? AppTheme.fontSemiBold : AppTheme.fontMedium,
                        color: isSelected 
                            ? colorScheme.onPrimary 
                            : colorScheme.onSurfaceVariant,
                        letterSpacing: isIOS ? -0.1 : 0,
                      ),
                    ),
                    avatar: Icon(
                      filter['icon'],
                      size: 16,
                      color: isSelected 
                          ? colorScheme.onPrimary 
                          : colorScheme.onSurfaceVariant,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter['key'];
                        });
                        _applyFilters();
                      }
                    },
                    backgroundColor: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primary,
                    showCheckmark: false,
                    elevation: isSelected ? 2 : 0,
                    pressElevation: 4,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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

  // Méthodes utilitaires
  Future<void> _loadSermons() async {
    try {
      SermonService.getSermons().listen((sermons) {
        if (mounted) {
          setState(() {
            _sermons = sermons;
            _isLoading = false;
          });
          _applyFilters();
          _listAnimationController.forward();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erreur lors du chargement des sermons');
      }
    }
  }

  Future<void> _refreshSermons() async {
    await _loadSermons();
  }

  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      _filteredSermons = _sermons.where((sermon) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!sermon.titre.toLowerCase().contains(query) &&
              !sermon.orateur.toLowerCase().contains(query) &&
              !(sermon.description?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }
        
        // Filtre par catégorie
        switch (_selectedFilter) {
          case 'Récents':
            return sermon.date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          case 'Avec Notes':
            return sermon.notes?.isNotEmpty == true;
          case 'Avec Vidéo':
            return sermon.lienYoutube?.isNotEmpty == true;
          default:
            return true;
        }
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _applyFilters();
  }

  void _launchYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Impossible d\'ouvrir le lien YouTube');
    }
  }

  void _showSermonDetails(Sermon sermon) {
    // Logique pour afficher les détails du sermon
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SermonNotesView(sermon: sermon),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: colorScheme.onError,
          ),
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