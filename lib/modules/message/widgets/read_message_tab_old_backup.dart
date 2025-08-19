import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/sermon.dart';
import '../../../models/branham_message.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/branham_messages_service.dart';
import 'pdf_viewer_screen.dart';

class ReadMessageTab extends StatefulWidget {
  const ReadMessageTab({Key? key}) : super(key: key);

  @override
  State<ReadMessageTab> createState() => _ReadMessageTabState();
}

class _ReadMessageTabState extends State<ReadMessageTab>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  bool _isLoading = true;
  bool _isSearching = false;
  List<BranhamMessage> _messages = [];
  List<BranhamMessage> _filteredMessages = [];

  final List<Map<String, dynamic>> _filters = [
    {'key': 'Tous', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'key': '1950s', 'icon': Icons.calendar_month, 'color': Colors.green},
    {'key': '1960s', 'icon': Icons.calendar_month, 'color': Colors.orange},
    {'key': 'Favoris', 'icon': Icons.favorite, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSermons();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSermons() async {
    try {
      setState(() => _isLoading = true);
      
      final messages = await BranhamMessagesService.getAllMessages();
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    try {
      setState(() => _isLoading = true);
      
      final messages = await BranhamMessagesService.getAllMessages(forceRefresh: true);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      _applyFilters();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste des prédications mise à jour'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<BranhamMessage> filtered = List.from(_messages);

    // Appliquer le filtre par catégorie
    switch (_selectedFilter) {
      case '1950s':
        filtered = BranhamMessagesService.filterByDecade(filtered, '1950s');
        break;
      case '1960s':
        filtered = BranhamMessagesService.filterByDecade(filtered, '1960s');
        break;
      case 'Favoris':
        // TODO: Implémenter le système de favoris
        filtered = [];
        break;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = BranhamMessagesService.searchMessages(filtered, _searchQuery);
    }

    // Trier par date décroissante
    filtered.sort((a, b) => b.publishDate.compareTo(a.publishDate));

    setState(() => _filteredMessages = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          if (!_isLoading && _messages.isNotEmpty)
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
                    _refreshMessages();
                    break;
                  case 'search':
                    setState(() => _isSearching = true);
                    break;
                  case 'filter':
                    _showFilterDialog();
                    break;
                  case 'stats':
                    _showStatsDialog();
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
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rechercher',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                        Icons.filter_list,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Filtrer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
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
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _applyFilters();
                      },
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Rechercher dans les prédications...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _isSearching = false;
                            });
                            _applyFilters();
                          },
                          icon: const Icon(Icons.close),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_searchQuery.isNotEmpty || _selectedFilter != 'Tous') ...[
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
                      _selectedFilter = 'Tous';
                      _searchController.clear();
                      _applyFilters();
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

  Widget _buildContent() {
    if (_filteredMessages.isEmpty) {
      return _buildEmptyState();
    }
    return _buildSermonsList();
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
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.menu_book_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune prédication trouvée'
                  : _selectedFilter != 'Tous'
                      ? 'Aucune prédication pour ce filtre'
                      : 'Aucune prédication disponible',
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
                  ? 'Essayez avec d\'autres termes de recherche'
                  : _selectedFilter != 'Tous'
                      ? 'Changez de filtre ou réinitialisez la recherche'
                      : 'Les prédications apparaîtront ici une fois ajoutées',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'Tous';
                  _isSearching = false;
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
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
        ),
      ),
    );
  }

  Widget _buildSermonsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshMessages,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredMessages.length,
          itemBuilder: (context, index) {
            final message = _filteredMessages[index];
            return _buildMessageCard(message, index);
          },
        ),
      ),
    );
  }

  Widget _buildMessageCard(BranhamMessage message, int index) {
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
          onTap: () => _openPdfViewer(message),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryColor.withOpacity(0.02),
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.id,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.formattedDuration,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Titre de la prédication
                  Text(
                    message.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Informations de lieu et date
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.location,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        message.formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdfViewer(message),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            size: 18,
                          ),
                          label: const Text('Lire PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _shareMessage(message),
                        icon: const Icon(
                          Icons.share,
                          size: 18,
                        ),
                        label: const Text('Partager'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
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

  void _openPdfViewer(BranhamMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(message: message),
      ),
    );
  }

  void _shareMessage(BranhamMessage message) {
    Share.share(
      'Prédication: ${message.title}\n'
      'Date: ${message.formattedDate}\n'
      'Lieu: ${message.location}\n'
      'Durée: ${message.formattedDuration}\n'
      'Lien PDF: ${message.pdfUrl}',
      subject: 'Prédication - ${message.title}',
    );
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer les prédications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final filterKey = filter['key'] as String;
              
              return ListTile(
                title: Text(
                  filterKey,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: Icon(
                  filter['icon'] as IconData,
                  color: filter['color'] as Color,
                  size: 20,
                ),
                trailing: Radio<String>(
                  value: filterKey,
                  groupValue: _selectedFilter,
                  onChanged: (value) => Navigator.of(context).pop(value),
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () => Navigator.of(context).pop(filterKey),
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
    
    if (result != null && result != _selectedFilter) {
      setState(() => _selectedFilter = result);
      _applyFilters();
    }
  }

  Future<void> _showStatsDialog() async {
    final totalSermons = _sermons.length;
    final filteredSermons = _filteredSermons.length;
    final favoriteCount = _sermons.where((s) => s.isFavorite).length;
    final withNotesCount = _sermons.where((s) => s.notes?.isNotEmpty == true).length;
    final avgProgress = _sermons.isNotEmpty 
        ? _sermons.map((s) => s.readingProgress).reduce((a, b) => a + b) / _sermons.length
        : 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.menu_book,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Statistiques de lecture',
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
            _buildStatItem('Total des prédications', totalSermons.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Prédications affichées', filteredSermons.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Favoris', favoriteCount.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Avec notes', withNotesCount.toString()),
            const SizedBox(height: 12),
            _buildStatItem('Progression moyenne', '${(avgProgress * 100).round()}%'),
            if (_selectedFilter != 'Tous') ...[
              const SizedBox(height: 12),
              _buildStatItem('Filtre actuel', _selectedFilter),
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
    
    if (_selectedFilter != 'Tous') {
      filters.add('Filtre: $_selectedFilter');
    }
    
    return filters.join(' • ');
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
}
