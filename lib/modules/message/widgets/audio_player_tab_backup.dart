import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/branham_audio_player_service.dart';

/// Onglet "Écouter La Voix du 7ème ange" - Prédications de frère Branham
class AudioPlayerTab extends StatefulWidget {
  const AudioPlayerTab({Key? key}) : super(key: key);

  @override
  State<AudioPlayerTab> createState() => _AudioPlayerTabState();
}

class _AudioPlayerTabState extends State<AudioPlayerTab>
    with TickerProviderStateMixin {
  final BranhamAudioPlayerService _audioPlayer = BranhamAudioPlayerService();
  
  List<BranhamSermon> _allSermons = [];
  BranhamSermon? _currentSermon;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Filtres
  String _searchQuery = '';
  int? _selectedYear;
  String? _selectedSeries;
  bool _isSearching = false; // Nouvel état pour le mode recherche
  
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadSermons();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadSermons({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Chargement des prédications de frère Branham...');
      
      // Charger uniquement les prédications admin actives
      final sermons = await AdminBranhamSermonService.getActiveSermons();
      
      setState(() {
        _allSermons = sermons;
        _isLoading = false;
        
        // Auto-sélectionner la première prédication si aucune n'est sélectionnée
        if (_currentSermon == null && sermons.isNotEmpty) {
          // Utiliser la première prédication filtrée (respecte les filtres actifs)
          final filteredSermons = _filteredSermons;
          if (filteredSermons.isNotEmpty) {
            _currentSermon = filteredSermons.first;
            print('📻 Prédication auto-sélectionnée: ${_currentSermon!.title}');
          }
        }
      });
      
      if (sermons.isEmpty) {
        print('⚠️ Aucune prédication trouvée. Les administrateurs doivent ajouter du contenu.');
      } else {
        print('✅ ${sermons.length} prédications chargées depuis l\'administration');
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _loadSermons(forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });
    
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration ?? Duration.zero);
      }
    });
    
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
        // Animation de rotation supprimée - l'image reste statique
      }
    });

    _audioPlayer.speedStream.listen((speed) {
      if (mounted) {
        setState(() => _playbackSpeed = speed);
      }
    });
  }

  // Méthodes de filtrage
  List<BranhamSermon> get _filteredSermons {
    var filtered = _allSermons.where((sermon) {
      // Filtre par recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!sermon.title.toLowerCase().contains(query) &&
            !sermon.location.toLowerCase().contains(query) &&
            !sermon.keywords.any((k) => k.toLowerCase().contains(query))) {
          return false;
        }
      }
      
      // Filtre par année
      if (_selectedYear != null && sermon.year != _selectedYear) {
        return false;
      }
      
      // Filtre par série
      if (_selectedSeries != null && sermon.series != _selectedSeries) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Tri par date (plus récent en premier)
    filtered.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    return filtered;
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateYearFilter(int? year) {
    setState(() {
      _selectedYear = year;
    });
  }

  void _updateSeriesFilter(String? series) {
    setState(() {
      _selectedSeries = series;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedYear = null;
      _selectedSeries = null;
    });
  }

  void _enterSearchMode() {
    setState(() {
      _isSearching = true;
    });
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _showYearFilterDialog() async {
    final availableYears = _allSermons.map((s) => s.year).where((year) => year != null).cast<int>().toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par année'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Toutes les années'),
                leading: Radio<int?>(
                  value: null,
                  groupValue: _selectedYear,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(null),
              ),
              ...availableYears.map((year) => ListTile(
                title: Text(year.toString()),
                leading: Radio<int?>(
                  value: year,
                  groupValue: _selectedYear,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(year),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (result != _selectedYear) {
      _updateYearFilter(result);
    }
  }

  Future<void> _showSeriesFilterDialog() async {
    final availableSeries = _allSermons.map((s) => s.series).where((s) => s != null && s.isNotEmpty).cast<String>().toSet().toList()
      ..sort();
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par série'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Toutes les séries'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedSeries,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(null),
              ),
              ...availableSeries.map((series) => ListTile(
                title: Text(series),
                leading: Radio<String?>(
                  value: series,
                  groupValue: _selectedSeries,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(series),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (result != _selectedSeries) {
      _updateSeriesFilter(result);
    }
  }

  // Méthodes de lecture
  Future<void> _playSermon(BranhamSermon sermon) async {
    try {
      setState(() {
        _currentSermon = sermon;
        _isLoading = true;
      });
      
      await _audioPlayer.playSermon(sermon);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _skipForward() async {
    await _audioPlayer.skipForward30();
  }

  Future<void> _skipBackward() async {
    await _audioPlayer.skipBackward30();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // En-tête moderne avec gradient
          _buildModernHeader(),
          
          // Player principal moderne
          _buildMainPlayer(),
          
          // Barre de recherche et filtres modernisée
          _buildSearchAndFilters(),
          
          // Liste des prédications
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildSermonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.headphones,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Écouter le Message',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prédications audio spirituelles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des prédications...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Barre de recherche moderne
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearching ? 50 : 0,
            child: _isSearching
                ? Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      autofocus: true,
                      onChanged: _updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une prédication...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () => _updateSearchQuery(''),
                                icon: const Icon(Icons.close),
                              )
                            : IconButton(
                                onPressed: _exitSearchMode,
                                icon: const Icon(Icons.close),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Contrôles et filtres modernes
          Row(
            children: [
              // Bouton de recherche
              IconButton(
                onPressed: _enterSearchMode,
                icon: Icon(
                  Icons.search,
                  color: _searchQuery.isNotEmpty ? AppTheme.primaryColor : Colors.grey[600],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _searchQuery.isNotEmpty 
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  padding: const EdgeInsets.all(12),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Filtres sous forme de chips modernes
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Filtre par année
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: _selectedYear != null ? Colors.white : Colors.blue,
                          ),
                          label: Text(
                            _selectedYear != null ? '${_selectedYear}' : 'Année',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedYear != null ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: _selectedYear != null,
                          onSelected: (_) => _showYearFilterDialog(),
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _selectedYear != null ? Colors.blue : Colors.grey[300]!,
                          ),
                          showCheckmark: false,
                        ),
                      ),
                      
                      // Filtre par série
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            Icons.category,
                            size: 16,
                            color: _selectedSeries != null ? Colors.white : Colors.purple,
                          ),
                          label: Text(
                            _selectedSeries != null ? 'Série' : 'Série',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedSeries != null ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: _selectedSeries != null,
                          onSelected: (_) => _showSeriesFilterDialog(),
                          selectedColor: Colors.purple,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _selectedSeries != null ? Colors.purple : Colors.grey[300]!,
                          ),
                          showCheckmark: false,
                        ),
                      ),
                      
                      // Bouton reset si des filtres sont actifs
                      if (_selectedYear != null || _selectedSeries != null || _searchQuery.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: IconButton(
                            onPressed: () {
                              _clearAllFilters();
                              _exitSearchMode();
                            },
                            icon: const Icon(Icons.clear_all),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.all(8),
                            ),
                            tooltip: 'Effacer tous les filtres',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayer() {
          ] else ...[
            // Mode normal : afficher les icônes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône de recherche
                IconButton(
                  onPressed: _enterSearchMode,
                  icon: Icon(
                    Icons.search,
                    color: _searchQuery.isNotEmpty ? AppTheme.primaryColor : Colors.grey[600],
                    size: 20,
                  ),
                  tooltip: _searchQuery.isNotEmpty ? 'Recherche: $_searchQuery' : 'Rechercher',
                  style: IconButton.styleFrom(
                    backgroundColor: _searchQuery.isNotEmpty 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Icône filtre par année
                IconButton(
                  onPressed: _showYearFilterDialog,
                  icon: Icon(
                    Icons.calendar_today,
                    color: _selectedYear != null ? AppTheme.primaryColor : Colors.grey[600],
                    size: 20,
                  ),
                  tooltip: _selectedYear != null ? 'Année: $_selectedYear' : 'Filtrer par année',
                  style: IconButton.styleFrom(
                    backgroundColor: _selectedYear != null 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Icône filtre par série
                IconButton(
                  onPressed: _showSeriesFilterDialog,
                  icon: Icon(
                    Icons.library_books,
                    color: _selectedSeries != null ? AppTheme.primaryColor : Colors.grey[600],
                    size: 20,
                  ),
                  tooltip: _selectedSeries != null ? 'Série: $_selectedSeries' : 'Filtrer par série',
                  style: IconButton.styleFrom(
                    backgroundColor: _selectedSeries != null 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Bouton de rafraîchissement
                IconButton(
                  onPressed: () => _loadSermons(forceRefresh: true),
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  tooltip: 'Actualiser',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                
                // Bouton pour effacer tous les filtres (avec espacement conditionnel)
                if (_searchQuery.isNotEmpty || _selectedYear != null || _selectedSeries != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearAllFilters,
                    icon: Icon(
                      Icons.clear_all,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    tooltip: 'Effacer tous les filtres',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/table.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            // Overlay sombre pour améliorer la lisibilité du texte
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Section artwork et infos - Plus compacte
                  Row(
                    children: [
                      // Artwork plus petit
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Artwork principal - statique
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/branham.jpg',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback vers l'icône si l'image ne charge pas
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1DB954),
                                    const Color(0xFF1ED760),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.library_music_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Indicateur de lecture plus petit
                    if (_isPlaying)
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            width: 72 + (_waveController.value * 6),
                            height: 72 + (_waveController.value * 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1DB954).withOpacity(
                                  0.5 - (_waveController.value * 0.3),
                                ),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Informations du sermon - Optimisées
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSermon?.title ?? 'Choisissez une prédication dans la liste ci-dessous',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentSermon != null
                            ? '${_currentSermon!.date} • ${_currentSermon!.location}'
                            : 'Prédications de William Marrion Branham',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFB3B3B3), // Gris Spotify
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_currentSermon == null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Sélectionnez une prédication pour commencer l\'écoute',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF6B6B6B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions rapides - Plus compactes
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactSpeedButton(),
                    const SizedBox(width: 4),
                    _buildCompactOptionsMenu(),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Barre de progression - Plus fine
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF1DB954), // Vert Spotify
                    inactiveTrackColor: const Color(0xFF3E3E3E), // Gris foncé
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _totalDuration.inMilliseconds > 0
                        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                        : 0.0,
                    onChanged: (value) {
                      final position = Duration(
                        milliseconds: (value * _totalDuration.inMilliseconds).round(),
                      );
                      _seekTo(position);
                    },
                  ),
                ),
                
                // Temps - Plus discrets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 18),
            
            // Contrôles de lecture - Plus compacts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous
                _buildCompactControlButton(
                  icon: Icons.skip_previous_rounded,
                  size: 24,
                  onPressed: _currentSermon != null ? _previousSermon : null,
                ),
                
                const SizedBox(width: 12),
                
                // Reculer 30s
                _buildCompactControlButton(
                  icon: Icons.replay_30_rounded,
                  size: 20,
                  onPressed: _currentSermon != null ? _skipBackward : null,
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause principal - Réduit
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _currentSermon != null ? _togglePlayPause : null,
                    icon: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Avancer 30s
                _buildCompactControlButton(
                  icon: Icons.forward_30_rounded,
                  size: 20,
                  onPressed: _currentSermon != null ? _skipForward : null,
                ),
                
                const SizedBox(width: 12),
                
                // Next
                _buildCompactControlButton(
                  icon: Icons.skip_next_rounded,
                  size: 24,
                  onPressed: _currentSermon != null ? _nextSermon : null,
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
  }

  // Nouveau widget pour les boutons de contrôle compacts
  Widget _buildCompactControlButton({
    required IconData icon,
    required double size,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: size,
          color: onPressed != null 
            ? Colors.white 
            : const Color(0xFF6B6B6B), // Désactivé
        ),
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Version compacte du bouton de vitesse
  Widget _buildCompactSpeedButton() {
    return PopupMenuButton<double>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF404040),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed_rounded,
              color: const Color(0xFFB3B3B3),
              size: 12,
            ),
            const SizedBox(width: 2),
            Text(
              '${_playbackSpeed}x',
              style: GoogleFonts.inter(
                color: const Color(0xFFB3B3B3),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      color: const Color(0xFF282828),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => [
        _buildSpeedMenuItem(0.5, '0.5x'),
        _buildSpeedMenuItem(0.75, '0.75x'),
        _buildSpeedMenuItem(1.0, '1x (Normal)'),
        _buildSpeedMenuItem(1.25, '1.25x'),
        _buildSpeedMenuItem(1.5, '1.5x'),
        _buildSpeedMenuItem(2.0, '2x'),
      ],
      onSelected: (speed) {
        setState(() => _playbackSpeed = speed);
        _audioPlayer.setSpeed(speed);
      },
    );
  }

  // Version compacte du menu d'options
  Widget _buildCompactOptionsMenu() {
    return PopupMenuButton(
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: const Color(0xFFB3B3B3),
          size: 18,
        ),
      ),
      color: const Color(0xFF282828),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => [
        _buildOptionMenuItem(
          value: 'shuffle',
          icon: Icons.shuffle_rounded,
          text: 'Mode aléatoire',
        ),
        _buildOptionMenuItem(
          value: 'repeat',
          icon: Icons.repeat_rounded,
          text: 'Répéter',
        ),
        _buildOptionMenuItem(
          value: 'timer',
          icon: Icons.timer_rounded,
          text: 'Minuteur d\'arrêt',
        ),
        _buildOptionMenuItem(
          value: 'share',
          icon: Icons.share_rounded,
          text: 'Partager',
        ),
      ],
      onSelected: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Option "$value" à venir'),
            backgroundColor: const Color(0xFF282828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
      },
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double value, String text) {
    final isSelected = _playbackSpeed == value;
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: const Color(0xFF1DB954),
                size: 16,
              )
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildOptionMenuItem({
    required String value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFB3B3B3),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonsList() {
    if (_filteredSermons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _allSermons.isEmpty ? Icons.admin_panel_settings : Icons.library_music_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _allSermons.isEmpty 
                ? 'Aucune prédication disponible'
                : 'Aucune prédication ne correspond aux critères',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (_allSermons.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Les administrateurs doivent ajouter des prédications\ndepuis l\'interface d\'administration.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSermons.length,
      itemBuilder: (context, index) => _buildSermonTile(_filteredSermons[index]),
    );
  }

  Widget _buildSermonTile(BranhamSermon sermon) {
    final isCurrentSermon = _currentSermon?.id == sermon.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentSermon ? 4 : 1,
      color: isCurrentSermon ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.headphones,
                color: isCurrentSermon ? AppTheme.primaryColor : Colors.grey[600],
              ),
            ),
            if (isCurrentSermon && _isPlaying)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          sermon.title,
          style: GoogleFonts.crimsonText(
            fontWeight: isCurrentSermon ? FontWeight.bold : FontWeight.w500,
            color: isCurrentSermon ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sermon.date),
            Text(
              sermon.location,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (sermon.series?.isNotEmpty == true)
              Text(
                sermon.series!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurrentSermon && _isPlaying
                  ? Icons.pause_circle
                  : Icons.play_circle,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ],
        ),
        onTap: () => _playSermon(sermon),
      ),
    );
  }

  void _previousSermon() {
    if (_currentSermon == null) return;
    
    final currentIndex = _filteredSermons.indexWhere((s) => s.id == _currentSermon!.id);
    if (currentIndex > 0) {
      _playSermon(_filteredSermons[currentIndex - 1]);
    }
  }

  void _nextSermon() {
    if (_currentSermon == null) return;
    
    final currentIndex = _filteredSermons.indexWhere((s) => s.id == _currentSermon!.id);
    if (currentIndex < _filteredSermons.length - 1) {
      _playSermon(_filteredSermons[currentIndex + 1]);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
