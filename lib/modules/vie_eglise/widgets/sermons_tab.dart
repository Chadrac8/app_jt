import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';
import '../views/sermon_notes_view.dart';
import '../views/sermon_infographies_view.dart';
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      // ✅ Pas de style : hérite automatiquement du ChipTheme
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
        onInfographiesTap: () {
          if (isIOS) HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SermonInfographiesView(sermon: sermon),
            ),
          );
        },
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
  final VoidCallback onInfographiesTap;
  final VoidCallback onNotesTap;

  const _ProfessionalSermonCard({
    required this.sermon,
    required this.colorScheme,
    required this.isIOS,
    required this.onTap,
    required this.onInfographiesTap,
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

  // Ouvrir la vidéo YouTube
  Future<void> _openYoutubeVideo(String youtubeUrl) async {
    try {
      final uri = Uri.parse(youtubeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir la vidéo'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lecteur YouTube si disponible
                  if (widget.sermon.lienYoutube?.isNotEmpty == true)
                    _YoutubePlayerWidget(
                      key: ValueKey('youtube_${widget.sermon.id}'),
                      youtubeUrl: widget.sermon.lienYoutube!,
                      colorScheme: widget.colorScheme,
                    ),
                  
                  Padding(
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
                            
                            // Date et durée
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.isIOS ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
                                        size: widget.isIOS ? 12 : 13,
                                        color: widget.colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yy').format(widget.sermon.date),
                                        style: GoogleFonts.inter(
                                          fontSize: widget.isIOS ? 11 : 12,
                                          fontWeight: AppTheme.fontMedium,
                                          color: widget.colorScheme.onSurfaceVariant,
                                          letterSpacing: widget.isIOS ? -0.1 : 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Durée si disponible
                                if (widget.sermon.duree > 0) ...[
                                  SizedBox(width: widget.isIOS ? 6 : 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: widget.isIOS ? 10 : 12,
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
                                          widget.isIOS ? CupertinoIcons.clock : Icons.access_time_rounded,
                                          size: widget.isIOS ? 12 : 13,
                                          color: widget.colorScheme.onSecondaryContainer,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${widget.sermon.duree}min',
                                          style: GoogleFonts.inter(
                                            fontSize: widget.isIOS ? 11 : 12,
                                            fontWeight: AppTheme.fontMedium,
                                            color: widget.colorScheme.onSecondaryContainer,
                                            letterSpacing: widget.isIOS ? -0.1 : 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
                          // Bouton Regarder (YouTube) - mis en évidence si vidéo disponible
                          if (widget.sermon.lienYoutube?.isNotEmpty == true)
                            Expanded(
                              child: _buildActionButton(
                                onPressed: () => _openYoutubeVideo(widget.sermon.lienYoutube!),
                                icon: widget.isIOS ? CupertinoIcons.play_circle : Icons.play_circle_rounded,
                                label: 'Regarder',
                                isPrimary: true,
                                isEnabled: true,
                              ),
                            ),
                          
                          if (widget.sermon.lienYoutube?.isNotEmpty == true)
                            SizedBox(width: widget.isIOS ? 12 : 14),
                          
                          // Bouton Écritures
                          Expanded(
                            child: _buildActionButton(
                              onPressed: widget.onNotesTap,
                              icon: widget.isIOS ? CupertinoIcons.doc_text : Icons.article_rounded,
                              label: 'Écritures',
                              isPrimary: widget.sermon.lienYoutube?.isEmpty ?? true,
                              isEnabled: true,
                            ),
                          ),
                          
                          SizedBox(width: widget.isIOS ? 12 : 14),
                          
                          // Bouton Schémas
                          Expanded(
                            child: _buildActionButton(
                              onPressed: widget.onInfographiesTap,
                              icon: widget.isIOS ? CupertinoIcons.photo : Icons.image_rounded,
                              label: 'Schémas',
                              isPrimary: false,
                              isEnabled: true,
                            ),
                          ),
                          ],
                          ),
                        ],
                      ),
                    ),
                ],
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
    // Couleurs professionnelles et douces
    final backgroundColor = isPrimary
        ? (isEnabled 
            ? widget.colorScheme.primaryContainer 
            : widget.colorScheme.surfaceContainerHighest)
        : widget.colorScheme.surfaceContainerHigh;
    
    final foregroundColor = isPrimary
        ? (isEnabled 
            ? widget.colorScheme.onPrimaryContainer 
            : widget.colorScheme.onSurfaceVariant)
        : widget.colorScheme.onSurfaceVariant;

    return Container(
      height: widget.isIOS ? 44 : 48,
      decoration: isPrimary && isEnabled
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.colorScheme.primaryContainer,
                  widget.colorScheme.primaryContainer.withValues(alpha: 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: widget.isIOS 
          ? CupertinoButton(
              onPressed: isEnabled ? onPressed : null,
              padding: EdgeInsets.zero,
              color: isPrimary && isEnabled ? Colors.transparent : backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: foregroundColor,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: AppTheme.fontSemiBold,
                        color: foregroundColor,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onPressed : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: isPrimary && isEnabled
                      ? null
                      : BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: foregroundColor,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: AppTheme.fontSemiBold,
                            color: foregroundColor,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
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

/// Widget pour le lecteur YouTube intégré
class _YoutubePlayerWidget extends StatefulWidget {
  final String youtubeUrl;
  final ColorScheme colorScheme;

  const _YoutubePlayerWidget({
    super.key,
    required this.youtubeUrl,
    required this.colorScheme,
  });

  @override
  State<_YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<_YoutubePlayerWidget> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  String? _extractYoutubeVideoId(String url) {
    // Essayer d'abord avec la méthode standard
    var videoId = YoutubePlayer.convertUrlToId(url);
    
    if (videoId != null) {
      return videoId;
    }
    
    // Si ça ne marche pas, essayer d'extraire manuellement pour les lives et autres formats
    try {
      final uri = Uri.parse(url);
      
      // Format: youtube.com/live/VIDEO_ID
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'live') {
        return uri.pathSegments[1];
      }
      
      // Format: youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      }
      
      // Format: youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      
      // Format: youtube.com/embed/VIDEO_ID
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return null;
  }

  void _initializePlayer() {
    final videoId = _extractYoutubeVideoId(widget.youtubeUrl);
    
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          showLiveFullscreenButton: true,
          hideControls: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(
        height: 200,
        color: widget.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: widget.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Vidéo non disponible',
                style: GoogleFonts.inter(
                  color: widget.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: ${widget.youtubeUrl}',
                style: GoogleFonts.inter(
                  color: widget.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: widget.colorScheme.primary,
        progressColors: ProgressBarColors(
          playedColor: widget.colorScheme.primary,
          handleColor: widget.colorScheme.primary,
        ),
      ),
    );
  }
}