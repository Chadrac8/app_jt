import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme.dart';
import '../../../models/branham_message.dart';
import '../services/admin_branham_messages_service.dart';
import 'admin_branham_messages_screen.dart';
import 'pdf_viewer_screen.dart';
import '../../../theme.dart';

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
    {'key': 'Tous', 'icon': Icons.all_inclusive, 'color': AppTheme.grey500},
    {'key': '1950s', 'icon': Icons.calendar_month, 'color': AppTheme.greenStandard},
    {'key': '1960s', 'icon': Icons.calendar_month, 'color': AppTheme.orangeStandard},
    {'key': 'Favoris', 'icon': Icons.favorite, 'color': AppTheme.redStandard},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMessages();
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
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final messages = await AdminBranhamMessagesService.getAllMessages();
      
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      await _applyFilters();
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final messages = await AdminBranhamMessagesService.getAllMessages();
      
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      await _applyFilters();
      
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _applyFilters() async {
    List<BranhamMessage> filtered = List.from(_messages);

    // Appliquer le filtre par catégorie
    switch (_selectedFilter) {
      case '1950s':
        filtered = await AdminBranhamMessagesService.filterByDecade('1950s');
        break;
      case '1960s':
        filtered = await AdminBranhamMessagesService.filterByDecade('1960s');
        break;
      case 'Favoris':
        // TODO: Implémenter le système de favoris
        filtered = [];
        break;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = await AdminBranhamMessagesService.searchMessages(_searchQuery);
    }

    // Trier par date décroissante
    filtered.sort((a, b) => b.publishDate.compareTo(a.publishDate));

    if (!mounted) return;
    setState(() => _filteredMessages = filtered);
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    if (!mounted) return;
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredMessages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
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
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  Icons.library_books,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lire le Message',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.grey800,
                      ),
                    ),
                    Text(
                      'Prédications de William Branham',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _messages.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                        if (mounted) setState(() => _isSearching = true);
                        break;
                      case 'filter':
                        _showFilterDialog();
                        break;
                      case 'admin':
                        _navigateToAdmin();
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
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Actualiser',
                            style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
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
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Rechercher',
                            style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
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
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Filtrer',
                            style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Administration',
                            style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.grey500.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher une prédication...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.grey500,
                    fontSize: AppTheme.fontSize14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.grey500,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.grey500,
                            size: 20,
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            if (mounted) setState(() => _isSearching = false);
                          },
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.grey500,
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
          if (_selectedFilter != 'Tous') ...[
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filters.firstWhere((f) => f['key'] == _selectedFilter)['icon'],
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Text(
                    _selectedFilter,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space6),
                  GestureDetector(
                    onTap: () {
                      if (mounted) setState(() => _selectedFilter = 'Tous');
                      _applyFilters();
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            'Chargement des prédications...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.book_outlined,
                size: 48,
                color: AppTheme.grey400,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tous'
                  ? 'Aucun résultat trouvé'
                  : 'Aucune prédication disponible',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.grey700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tous'
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Les prédications seront chargées automatiquement',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'Tous') ...[
              const SizedBox(height: AppTheme.spaceLarge),
              ElevatedButton.icon(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _selectedFilter = 'Tous';
                      _searchQuery = '';
                      _searchController.clear();
                      _isSearching = false;
                    });
                  }
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Effacer les filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshMessages,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          side: BorderSide(
            color: AppTheme.grey500.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          onTap: () => _openPdfViewer(message),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.white100,
                  AppTheme.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space20),
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          message.id,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontSemiBold,
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
                          color: AppTheme.orangeStandard.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppTheme.grey700,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Text(
                              message.formattedDuration,
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize11,
                                fontWeight: AppTheme.fontMedium,
                                color: AppTheme.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),

                  // Titre de la prédication
                  Text(
                    message.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.grey800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space12),

                  // Informations de lieu et date
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.grey600,
                      ),
                      const SizedBox(width: AppTheme.space6),
                      Expanded(
                        child: Text(
                          message.location,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.grey600,
                      ),
                      const SizedBox(width: AppTheme.space6),
                      Text(
                        message.formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),

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
                            foregroundColor: AppTheme.white100,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
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
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
          'Filtrer par',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            fontSize: AppTheme.fontSize18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              return RadioListTile<String>(
                value: filter['key'],
                groupValue: _selectedFilter,
                onChanged: (value) => Navigator.pop(context, value),
                title: Row(
                  children: [
                    Icon(
                      filter['icon'],
                      color: filter['color'],
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Text(
                      filter['key'],
                      style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
                    ),
                  ],
                ),
                activeColor: AppTheme.primaryColor,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (result != null && result != _selectedFilter) {
      if (mounted) setState(() => _selectedFilter = result);
      _applyFilters();
    }
  }

  void _navigateToAdmin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminBranhamMessagesScreen(),
      ),
    );
    
    // Rafraîchir la liste après le retour de l'administration
    if (result == true) {
      _loadMessages();
    }
  }
}
