import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme.dart';
import '../models/sermon_model.dart';
import '../services/reading_service.dart';

/// Onglet "Lire le message" - Base de données des prédications avec recherche, surlignage et notes
class ReadMessageTab extends StatefulWidget {
  const ReadMessageTab({Key? key}) : super(key: key);

  @override
  State<ReadMessageTab> createState() => _ReadMessageTabState();
}

class _ReadMessageTabState extends State<ReadMessageTab> with TickerProviderStateMixin {
  final ReadingService _readingService = ReadingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Sermon> _sermons = [];
  List<Sermon> _filteredSermons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _filterController;
  late Animation<double> _filterAnimation;
  
  final List<Map<String, dynamic>> _filters = [
    {'key': 'Tous', 'icon': Icons.library_books, 'color': Colors.blue},
    {'key': 'Favoris', 'icon': Icons.favorite, 'color': Colors.red},
    {'key': '1950-1960', 'icon': Icons.calendar_today, 'color': Colors.green},
    {'key': '1960-1965', 'icon': Icons.calendar_month, 'color': Colors.orange},
    {'key': 'Avec notes', 'icon': Icons.notes, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOut),
    );
    
    _loadSermons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadSermons() async {
    setState(() => _isLoading = true);
    
    try {
      final sermons = await _readingService.getAllSermons();
      setState(() {
        _sermons = sermons;
        _filteredSermons = sermons;
        _isLoading = false;
      });
      _fadeController.forward();
      _filterController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur de chargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredSermons = _sermons.where((sermon) {
        // Filtre par recherche
        bool matchesSearch = _searchQuery.isEmpty ||
            sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            sermon.date.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (sermon.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Filtre par catégorie
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Favoris':
            matchesFilter = sermon.isFavorite;
            break;
          case '1950-1960':
            matchesFilter = (sermon.year != null && sermon.year! >= 1950 && sermon.year! < 1960);
            break;
          case '1960-1965':
            matchesFilter = (sermon.year != null && sermon.year! >= 1960 && sermon.year! <= 1965);
            break;
          case 'Avec notes':
            matchesFilter = (sermon.notes?.isNotEmpty ?? false);
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
      
      // Trier par date (plus récent en premier) puis par titre
      _filteredSermons.sort((a, b) {
        final yearComparison = (b.year ?? 0).compareTo(a.year ?? 0);
        if (yearComparison != 0) return yearComparison;
        return a.title.compareTo(b.title);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.03),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: Column(
        children: [
          // En-tête élégant
          _buildHeader(),
          
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Contenu principal
          Expanded(
            child: _isLoading 
                ? _buildLoadingState()
                : _filteredSermons.isEmpty
                    ? _buildEmptyState()
                    : _buildSermonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
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
              Icons.menu_book,
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
                  'Lire le Message',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Collection de prédications spirituelles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading && _sermons.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${_filteredSermons.length}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isSearching) ...[
            // Mode recherche
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher dans les prédications...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => setState(() => _isSearching = false),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mode normal
            Row(
              children: [
                // Bouton de recherche
                IconButton(
                  onPressed: () => setState(() => _isSearching = true),
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
                
                // Filtres sous forme de chips
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter['key'];
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              filter['icon'],
                              size: 16,
                              color: isSelected ? Colors.white : filter['color'],
                            ),
                            label: Text(
                              filter['key'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter['key']);
                              _applyFilters();
                              HapticFeedback.lightImpact();
                            },
                            selectedColor: filter['color'],
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? filter['color'] : Colors.grey[300]!,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune prédication trouvée pour "${_searchQuery}"'
                  : 'Aucune prédication disponible pour ce filtre',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'Tous';
                  _isSearching = false;
                });
                _applyFilters();
              },
              child: Text(
                'Réinitialiser la recherche',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadSermons,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredSermons.length,
          itemBuilder: (context, index) {
            final sermon = _filteredSermons[index];
            return _buildSermonCard(sermon, index);
          },
        ),
      ),
    );
  }

  Widget _buildSermonCard(Sermon sermon, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openSermonReader(sermon),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.withOpacity(0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de la carte
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sermon.title,
                              style: GoogleFonts.crimsonText(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sermon.date,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (sermon.location?.isNotEmpty == true) ...[
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      sermon.location!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButtons(sermon),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Aperçu du contenu
                  if (sermon.content?.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        _getPreviewText(sermon.content!),
                        style: GoogleFonts.crimsonText(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Métadonnées et badges
                  Row(
                    children: [
                      if (sermon.year != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getYearColor(sermon.year!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getYearColor(sermon.year!).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${sermon.year}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getYearColor(sermon.year!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      if (sermon.notes?.isNotEmpty == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notes,
                                size: 12,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Notes',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      const Spacer(),
                      
                      // Indicateur de progression de lecture
                      if (sermon.readingProgress > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(sermon.readingProgress * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Sermon sermon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _toggleFavorite(sermon),
          icon: Icon(
            sermon.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: sermon.isFavorite ? Colors.red : Colors.grey[400],
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: sermon.isFavorite 
                ? Colors.red.withOpacity(0.1)
                : Colors.grey[50],
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Colors.grey[600],
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[50],
            padding: const EdgeInsets.all(8),
          ),
          onSelected: (value) => _handleMenuAction(value, sermon),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bookmark',
              child: Row(
                children: [
                  Icon(Icons.bookmark_add, size: 18),
                  SizedBox(width: 8),
                  Text('Marque-page'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'notes',
              child: Row(
                children: [
                  Icon(Icons.note_add, size: 18),
                  SizedBox(width: 8),
                  Text('Ajouter note'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPreviewText(String content) {
    // Nettoyer le contenu et extraire les premières phrases
    final cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer HTML
        .replaceAll(RegExp(r'\s+'), ' ') // Normaliser espaces
        .trim();
    
    if (cleanContent.length <= 150) return cleanContent;
    
    // Trouver la fin de phrase la plus proche de 150 caractères
    final cutoff = cleanContent.substring(0, 150);
    final lastPeriod = cutoff.lastIndexOf('.');
    final lastExclamation = cutoff.lastIndexOf('!');
    final lastQuestion = cutoff.lastIndexOf('?');
    
    final endIndex = [lastPeriod, lastExclamation, lastQuestion]
        .reduce((a, b) => a > b ? a : b);
    
    if (endIndex > 50) {
      return cleanContent.substring(0, endIndex + 1);
    }
    
    return '${cleanContent.substring(0, 147)}...';
  }

  Color _getYearColor(int year) {
    if (year >= 1950 && year < 1960) return Colors.green;
    if (year >= 1960 && year <= 1965) return Colors.orange;
    return Colors.blue;
  }

  void _toggleFavorite(Sermon sermon) {
    setState(() {
      sermon.isFavorite = !sermon.isFavorite;
    });
    
    HapticFeedback.lightImpact();
    
    final message = sermon.isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: sermon.isFavorite ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    
    // Réappliquer les filtres si on est dans la vue "Favoris"
    if (_selectedFilter == 'Favoris') {
      _applyFilters();
    }
  }

  void _handleMenuAction(String action, Sermon sermon) {
    switch (action) {
      case 'share':
        _shareSermon(sermon);
        break;
      case 'bookmark':
        _addBookmark(sermon);
        break;
      case 'notes':
        _addNote(sermon);
        break;
    }
  }

  void _shareSermon(Sermon sermon) {
    final shareText = '''📖 ${sermon.title}

📅 ${sermon.date}
${sermon.location?.isNotEmpty == true ? '📍 ${sermon.location}\n' : ''}
${_getPreviewText(sermon.content ?? '')}

Partagé depuis l'application ChurchFlow 🙏''';

    Share.share(shareText, subject: sermon.title);
  }

  void _addBookmark(Sermon sermon) {
    // TODO: Implémenter l'ajout de marque-pages
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marque-page ajouté'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addNote(Sermon sermon) {
    // TODO: Implémenter l'ajout de notes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de notes à venir'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSermonReader(Sermon sermon) {
    // TODO: Implémenter l'ouverture du lecteur de prédication
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonReaderPage(sermon: sermon),
      ),
    );
  }
}

// Page de lecture temporaire
class SermonReaderPage extends StatelessWidget {
  final Sermon sermon;
  
  const SermonReaderPage({Key? key, required this.sermon}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sermon.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sermon.title,
              style: GoogleFonts.crimsonText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${sermon.date} - ${sermon.location ?? 'Lieu non spécifié'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  sermon.content ?? 'Contenu de la prédication à venir...',
                  style: GoogleFonts.crimsonText(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSermons.length,
      itemBuilder: (context, index) => _buildSermonCard(_filteredSermons[index]),
    );
  }

  Widget _buildSermonCard(Sermon sermon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSermonReader(sermon),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sermon.title,
                      style: GoogleFonts.crimsonText(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      sermon.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: sermon.isFavorite ? Colors.red : Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(sermon),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 8),
                            Text('Partager'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text('Télécharger'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notes',
                        child: Row(
                          children: [
                            Icon(Icons.note_add, size: 18),
                            SizedBox(width: 8),
                            Text('Ajouter une note'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleMenuAction(value.toString(), sermon),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations de la prédication
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sermon.date,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sermon.location != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sermon.location!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              if (sermon.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  sermon.description!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Tags et durée
              Row(
                children: [
                  if (sermon.keywords.isNotEmpty) ...[
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: sermon.keywords.take(3).map((keyword) => Chip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ),
                  ],
                  if (sermon.duration != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(sermon.duration!),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bouton de lecture
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openSermonReader(sermon),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lire la prédication',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSermonReader(Sermon sermon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonReaderPage(sermon: sermon),
      ),
    );
  }

  void _toggleFavorite(Sermon sermon) {
    setState(() {
      final index = _sermons.indexWhere((s) => s.id == sermon.id);
      if (index != -1) {
        _sermons[index] = sermon.copyWith(isFavorite: !sermon.isFavorite);
        _applyFilters();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sermon.isFavorite 
              ? 'Retiré des favoris' 
              : 'Ajouté aux favoris'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action, Sermon sermon) {
    switch (action) {
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Partage: ${sermon.title}')),
        );
        break;
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement à venir')),
        );
        break;
      case 'notes':
        _showAddNoteDialog(sermon);
        break;
    }
  }

  void _showAddNoteDialog(Sermon sermon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Prédication: ${sermon.title}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Votre note personnelle...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note sauvegardée')),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

/// Page de lecture d'une prédication complète
class SermonReaderPage extends StatefulWidget {
  final Sermon sermon;

  const SermonReaderPage({Key? key, required this.sermon}) : super(key: key);

  @override
  State<SermonReaderPage> createState() => _SermonReaderPageState();
}

class _SermonReaderPageState extends State<SermonReaderPage> {
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 16.0;
  Color _backgroundColor = Colors.white;
  String _fontFamily = 'Georgia';
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.sermon.title,
          style: GoogleFonts.crimsonText(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showReadingOptions,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchInText,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bookmark', child: Text('Marque-page')),
              const PopupMenuItem(value: 'highlight', child: Text('Surligner')),
              const PopupMenuItem(value: 'note', child: Text('Ajouter note')),
              const PopupMenuItem(value: 'share', child: Text('Partager')),
            ],
            onSelected: (value) {
              // TODO: Implémenter les actions
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la prédication
            _buildSermonHeader(),
            
            const SizedBox(height: 24),
            
            // Contenu de la prédication
            _buildSermonContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sermon.title,
            style: GoogleFonts.crimsonText(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.sermon.date,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (widget.sermon.location != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.sermon.location!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSermonContent() {
    // Contenu de démonstration
    return Text(
      '''Mes chers frères et sœurs, permettez-moi de vous dire ce soir que nous vivons dans l'heure la plus glorieuse que l'Église ait jamais connue. Nous vivons dans l'âge de Laodicée, le dernier âge de l'église.

La Bible nous dit que "la foi qui a été transmise aux saints une fois pour toutes". Cette foi n'est pas quelque chose de nouveau, c'est la même foi qui était dans le cœur d'Abel quand il a offert à Dieu un sacrifice plus excellent que celui de Caïn.

Cette foi, mes amis, c'est Christ en vous, l'espérance de la gloire. C'est la révélation de qui est Jésus-Christ. Ce n'est pas une doctrine, ce n'est pas une organisation, c'est une Personne – la Personne du Seigneur Jésus-Christ.

Quand Jésus était sur terre, Il a dit à Pierre : "Qui dit-on que je suis, moi, le Fils de l'homme ?" Pierre a répondu : "Tu es le Christ, le Fils du Dieu vivant." Et Jésus lui a dit : "Tu es heureux, Simon Bar-Jona, car ce ne sont pas la chair et le sang qui te l'ont révélé, mais c'est mon Père qui est dans les cieux."

Voyez-vous, mes amis, la foi, c'est une révélation. C'est quelque chose que Dieu révèle à votre cœur. Vous ne pouvez pas l'apprendre dans une école, vous ne pouvez pas l'apprendre dans un séminaire. C'est Dieu qui doit vous le révéler.

Et c'est sur cette révélation que Jésus a dit : "Je bâtirai mon Église, et les portes du séjour des morts ne prévaudront point contre elle."

L'Église véritable n'est pas une organisation, mes amis. L'Église véritable, c'est le Corps mystique de Christ, composé de tous ceux qui sont nés de nouveau par l'Esprit de Dieu.

Nous sommes dans les derniers jours. Les signes sont partout autour de nous. Israël est de retour dans sa patrie. Les nations sont dans la détresse. Les hommes sont égoïstes, et tout ce que la Bible a prédit pour les derniers jours s'accomplit sous nos yeux.

Mais gloire à Dieu ! Au milieu de toute cette confusion, Dieu appelle Son peuple hors de Babylone. Il appelle Son Épouse pour les noces de l'Agneau.

Êtes-vous prêts, mes amis ? Avez-vous cette foi qui était une fois donnée aux saints ? Avez-vous cette révélation de qui est Jésus-Christ ?

Si vous ne l'avez pas, inclinez vos têtes en ce moment même et demandez à Dieu de vous révéler Son Fils. Car il n'y a de salut en aucun autre nom sous le ciel que celui de Jésus-Christ.

Prions ensemble...''',
      style: GoogleFonts.getFont(
        _fontFamily,
        fontSize: _fontSize,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }

  void _showReadingOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options de lecture',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Taille de police
            Row(
              children: [
                const Text('Taille: '),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
                Text('${_fontSize.round()}'),
              ],
            ),
            
            // Couleur de fond
            const Text('Arrière-plan:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(Colors.white, 'Blanc'),
                _buildColorOption(Colors.grey[100]!, 'Gris'),
                _buildColorOption(AppTheme.backgroundColor, 'Sépia'),
                _buildColorOption(Colors.grey[900]!, 'Sombre'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, String label) {
    return GestureDetector(
      onTap: () => setState(() => _backgroundColor = color),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: _backgroundColor == color 
                    ? AppTheme.primaryColor 
                    : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showSearchInText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher dans le texte'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Mot ou phrase à rechercher...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la recherche
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}
