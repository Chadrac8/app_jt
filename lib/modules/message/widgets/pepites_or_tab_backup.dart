import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme.dart';
import '../../../models/pepite_or_model.dart';
import '../../../services/pepite_or_firebase_service.dart';
import '../../../pages/admin/pepite_or_detail_page.dart';

/// Onglet "Pépites d'Or" - Citations spirituelles organisées par thème
class PepitesOrTab extends StatefulWidget {
  const PepitesOrTab({Key? key}) : super(key: key);

  @override
  State<PepitesOrTab> createState() => _PepitesOrTabState();
}

class _PepitesOrTabState extends State<PepitesOrTab> with TickerProviderStateMixin {
  List<PepiteOrModel> _pepites = [];
  String _selectedTheme = 'Tous';
  bool _isLoading = true;
  String _searchQuery = '';
  List<String> _favoriteIds = [];
  bool _isSearching = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      PepiteOrFirebaseService.obtenirPepitesOrPublieesStream().listen(
        (pepites) {
          if (mounted) {
            setState(() {
              _pepites = pepites;
              _isLoading = false;
            });
            _fadeController.forward();
          }
        },
        onError: (error) {
          setState(() => _isLoading = false);
          if (mounted) {
            _showErrorSnackBar('Erreur de chargement: $error');
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Erreur de chargement: $e');
      }
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

  List<String> _extraireThemes(List<PepiteOrModel> pepites) {
    final themesSet = <String>{};
    for (final pepite in pepites) {
      themesSet.add(pepite.theme);
    }
    final themes = themesSet.toList();
    themes.sort();
    return themes;
  }

  List<PepiteOrModel> get _filteredPepites {
    var filtered = _pepites;
    
    if (_selectedTheme != 'Tous') {
      filtered = filtered.where((p) => p.theme == _selectedTheme).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => 
        p.theme.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query) ||
        p.tags.any((tag) => tag.toLowerCase().contains(query)) ||
        p.citations.any((citation) => 
          citation.texte.toLowerCase().contains(query) ||
          citation.auteur.toLowerCase().contains(query)
        )
      ).toList();
    }
    
    return filtered;
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
                : _filteredPepites.isEmpty
                    ? _buildEmptyState()
                    : _buildPepitesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pépites d\'Or',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Citations spirituelles inspirantes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _pepites.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _loadData();
                        break;
                      case 'search':
                        setState(() => _isSearching = true);
                        break;
                      case 'filter':
                        _showThemeFilterDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Actualiser',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rechercher',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filtrer',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
                PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Filtrer par thème',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'count',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Statistiques',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher une pépite d\'or...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () => setState(() => _searchQuery = ''),
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                        )
                      : IconButton(
                          onPressed: () => setState(() => _isSearching = false),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
          if (_selectedTheme != 'Tous') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedTheme,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTheme = 'Tous'),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppTheme.primaryColor,
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
                      autofocus: true,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher dans les pépites d\'or...',
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
                                onPressed: () => setState(() => _searchQuery = ''),
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
                  onPressed: () => setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  }),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ] else if (_searchQuery.isNotEmpty || _selectedTheme != 'Tous') ...[
            // Affichage des filtres actifs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildActiveFiltersText(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _selectedTheme = 'Tous';
                    }),
                    icon: const Icon(Icons.clear, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(24, 24),
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
            'Chargement des pépites d\'or...',
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune pépite trouvée'
                  : _pepites.isEmpty 
                      ? 'Aucune pépite d\'or disponible'
                      : 'Aucune pépite pour ce thème',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essayez avec d\'autres mots-clés'
                  : _pepites.isEmpty
                      ? 'Les pépites d\'or sont des citations inspirantes\norganisées par thème spirituel'
                      : 'Sélectionnez "Tous" pour voir toutes les pépites',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_pepites.isEmpty) ...[
              ElevatedButton.icon(
                onPressed: _creerDonneesTest,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer des données d\'exemple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPepitesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredPepites.length,
          itemBuilder: (context, index) {
            final pepite = _filteredPepites[index];
            return _buildPepiteCard(pepite, index);
          },
        ),
      ),
    );
  }

  Widget _buildPepiteCard(PepiteOrModel pepite, int index) {
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
          onTap: () => _navigateToDetail(pepite),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pepite.theme,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _toggleFavorite(pepite.id),
                        icon: Icon(
                          _favoriteIds.contains(pepite.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favoriteIds.contains(pepite.id)
                              ? Colors.red
                              : Colors.grey[400],
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shareQuote(pepite),
                        icon: Icon(
                          Icons.share,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (pepite.description.isNotEmpty) ...[
                    Text(
                      pepite.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Citations
                  ...pepite.citations.map((citation) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${citation.texte}"',
                          style: GoogleFonts.crimsonText(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '— ${citation.auteur}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  // Tags
                  if (pepite.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: pepite.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(PepiteOrModel pepite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PepiteOrDetailPage(pepite: pepite),
      ),
    );
  }

  void _toggleFavorite(String pepiteId) {
    setState(() {
      if (_favoriteIds.contains(pepiteId)) {
        _favoriteIds.remove(pepiteId);
      } else {
        _favoriteIds.add(pepiteId);
      }
    });
    
    // Animation de feedback
    HapticFeedback.lightImpact();
  }

  void _shareQuote(PepiteOrModel pepite) {
    final citations = pepite.citations
        .map((c) => '"${c.texte}" — ${c.auteur}')
        .join('\n\n');
    
    final text = '''${pepite.description}

$citations

#PépitesOr #Spiritualité #${pepite.theme}''';
    
    Share.share(text);
  }

  Future<void> _creerDonneesTest() async {
    try {
      // Créer 3 pépites d'exemple
      final pepites = [
        PepiteOrModel(
          id: '',
          theme: 'Foi',
          description: 'La foi qui déplace les montagnes et transforme les cœurs',
          auteur: 'system',
          nomAuteur: 'Système',
          citations: [
            CitationModel(
              id: 'c1',
              texte: 'Car nous marchons par la foi et non par la vue.',
              auteur: 'Apôtre Paul',
              reference: '2 Corinthiens 5:7',
              ordre: 1,
            ),
          ],
          tags: ['foi', 'confiance', 'miracle', 'puissance'],
          estPubliee: true,
          dateCreation: DateTime.now(),
          datePublication: DateTime.now(),
        ),
      ];

      for (final pepite in pepites) {
        await PepiteOrFirebaseService.creerPepiteOr(pepite);
      }

      if (mounted) {
        _showErrorSnackBar('✅ Pépites d\'or créées avec succès !');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('❌ Erreur: $e');
      }
    }
  }

  Future<void> _showThemeFilterDialog() async {
    final themes = _extraireThemes(_pepites);
    final allThemes = ['Tous', ...themes];
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer par thème',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allThemes.length,
            itemBuilder: (context, index) {
              final theme = allThemes[index];
              return ListTile(
                title: Text(
                  theme,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: Radio<String>(
                  value: theme,
                  groupValue: _selectedTheme,
                  onChanged: (value) => Navigator.of(context).pop(value),
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () => Navigator.of(context).pop(theme),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    
    if (result != null && result != _selectedTheme) {
      setState(() => _selectedTheme = result);
    }
  }

  Future<void> _showPepitesCountDialog() async {
    final totalPepites = _pepites.length;
    final filteredPepites = _filteredPepites.length;
    final themes = _extraireThemes(_pepites);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Statistiques',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total des pépites', totalPepites.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Pépites affichées', filteredPepites.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Thèmes disponibles', themes.length.toString()),
            if (_selectedTheme != 'Tous') ...[
              const SizedBox(height: 12),
              _buildStatItem('Thème sélectionné', _selectedTheme),
            ],
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildStatItem('Recherche active', '"$_searchQuery"'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _buildActiveFiltersText() {
    final filters = <String>[];
    
    if (_searchQuery.isNotEmpty) {
      filters.add('Recherche: "$_searchQuery"');
    }
    
    if (_selectedTheme != 'Tous') {
      filters.add('Thème: $_selectedTheme');
    }
    
    return filters.join(' • ');
  }
}
