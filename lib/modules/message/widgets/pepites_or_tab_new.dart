import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme.dart';
import '../../../models/pepite_or_model.dart';
import '../../../services/pepite_or_firebase_service.dart';
import '../../../pages/admin/pepite_or_detail_page.dart';
import '../../../theme.dart';

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
      final pepites = await PepiteOrFirebaseService.getAllPepites();
      setState(() {
        _pepites = pepites;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
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

  List<String> get _availableThemes {
    final themes = <String>{'Tous'};
    for (final pepite in _pepites) {
      themes.add(pepite.theme);
    }
    return themes.toList()..sort();
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
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
                  Icons.auto_awesome,
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
                      'Pépites d\'Or',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.grey800,
                      ),
                    ),
                    Text(
                      'Citations spirituelles inspirantes',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _pepites.isNotEmpty)
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
                onChanged: (value) => setState(() => _searchQuery = value),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher une pépite d\'or...',
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
                          onPressed: () => setState(() => _searchQuery = ''),
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.grey500,
                            size: 20,
                          ),
                        )
                      : IconButton(
                          onPressed: () => setState(() => _isSearching = false),
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
          if (_selectedTheme != 'Tous') ...[
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
                    Icons.category,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Text(
                    _selectedTheme,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement des pépites d\'or...',
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Aucun résultat trouvé'
                : 'Aucune pépite d\'or disponible',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Essayez un autre terme de recherche'
                : 'Les citations apparaîtront ici',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPepitesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _filteredPepites.length,
        itemBuilder: (context, index) {
          final pepite = _filteredPepites[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.white100,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              onTap: () => _openPepiteDetail(pepite),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          ),
                          child: Text(
                            pepite.theme,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontSemiBold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'share':
                                _sharePepite(pepite);
                                break;
                              case 'copy':
                                _copyPepite(pepite);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 18, color: AppTheme.primaryColor),
                                  const SizedBox(width: AppTheme.spaceSmall),
                                  const Text('Partager'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                                  const SizedBox(width: AppTheme.spaceSmall),
                                  const Text('Copier'),
                                ],
                              ),
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            color: AppTheme.grey400,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      pepite.description,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.grey800,
                        height: 1.4,
                      ),
                    ),
                    if (pepite.citations.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceMedium),
                      ...pepite.citations.take(2).map((citation) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(AppTheme.spaceMedium),
                          decoration: BoxDecoration(
                            color: AppTheme.grey50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: AppTheme.grey500.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${citation.texte}"',
                                style: GoogleFonts.crimsonText(
                                  fontSize: AppTheme.fontSize15,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.grey700,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceSmall),
                              Text(
                                '— ${citation.auteur}',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize13,
                                  fontWeight: AppTheme.fontMedium,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (pepite.citations.length > 2) ...[
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        '+${pepite.citations.length - 2} autre(s) citation(s)',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.grey500,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPepiteDetail(PepiteOrModel pepite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PepiteOrDetailPage(pepite: pepite),
      ),
    );
  }

  void _sharePepite(PepiteOrModel pepite) {
    final text = '${pepite.description}\n\n'
        '${pepite.citations.map((c) => '"${c.texte}" - ${c.auteur}').join('\n\n')}\n\n'
        '#PépitesOr #Spiritualité';
    
    Share.share(text, subject: 'Pépite d\'Or: ${pepite.theme}');
  }

  void _copyPepite(PepiteOrModel pepite) {
    final text = '${pepite.description}\n\n'
        '${pepite.citations.map((c) => '"${c.texte}" - ${c.auteur}').join('\n\n')}';
    
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pépite copiée dans le presse-papier'),
        backgroundColor: AppTheme.greenStandard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemeFilterDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer par thème',
          style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableThemes.length,
            itemBuilder: (context, index) {
              final theme = _availableThemes[index];
              return RadioListTile<String>(
                value: theme,
                groupValue: _selectedTheme,
                onChanged: (value) => Navigator.pop(context, value),
                title: Text(
                  theme,
                  style: GoogleFonts.inter(fontSize: AppTheme.fontSize14),
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

    if (result != null && result != _selectedTheme) {
      setState(() => _selectedTheme = result);
    }
  }
}
