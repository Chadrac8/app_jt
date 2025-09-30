import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../models/pepite_or_model.dart';
import '../../../services/pepite_or_firebase_service.dart';
import '../pages/pepite_detail_page.dart';

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
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
      // Utiliser le stream pour obtenir les données en temps réel
      PepiteOrFirebaseService.obtenirPepitesOrPublieesStream().listen((pepites) {
        if (mounted) {
          setState(() {
            _pepites = pepites;
            _isLoading = false;
          });
          _fadeController.forward();
        }
      });
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
    return Container(
      color: AppTheme.backgroundColor,
      child: _isLoading
          ? _buildLoadingState()
          : CustomScrollView(
              slivers: [
                // Filtres de thèmes compacts
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableThemes.map((theme) {
                          final isSelected = _selectedTheme == theme;
                          final count = theme == 'Tous' 
                              ? _pepites.length 
                              : _pepites.where((p) => p.theme == theme).length;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCompactFilterChip(theme, count, isSelected),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Barre de recherche
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.white100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black100.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une pépite d\'or...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.grey500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.grey400,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppTheme.grey400,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
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

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Liste des pépites
                _filteredPepites.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final pepite = _filteredPepites[index];
                            return _buildPepiteCard(pepite, index);
                          },
                          childCount: _filteredPepites.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildCompactFilterChip(String theme, int count, bool isSelected) {
    Color getFilterColor() {
      switch (theme) {
        case 'Tous':
          return const Color(0xFF6366F1);
        case 'Foi':
          return const Color(0xFF10B981);
        case 'Espérance':
          return const Color(0xFFF59E0B);
        case 'Amour':
          return const Color(0xFFEF4444);
        default:
          return AppTheme.primaryColor;
      }
    }

    final color = getFilterColor();
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: isSelected ? color : AppTheme.grey500.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.black100.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              theme,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? AppTheme.fontSemiBold : AppTheme.fontMedium,
                color: isSelected ? AppTheme.white100 : AppTheme.grey700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.white100.withOpacity(0.2) 
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: AppTheme.fontSemiBold,
                    color: isSelected ? AppTheme.white100 : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPepiteCard(PepiteOrModel pepite, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _openPepiteDetail(pepite),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec thème et actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        pepite.theme,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _sharePepite(pepite),
                      icon: Icon(
                        Icons.share,
                        color: AppTheme.grey600,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                if (pepite.description.isNotEmpty) ...[
                  Text(
                    pepite.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.grey800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Citations
                ...pepite.citations.take(2).map((citation) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.grey700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '— ${citation.auteur}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                // Afficher le nombre de citations restantes
                if (pepite.citations.length > 2) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+${pepite.citations.length - 2} autre${pepite.citations.length - 2 > 1 ? 's' : ''} citation${pepite.citations.length - 2 > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                ],
                
                // Tags
                if (pepite.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: pepite.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.grey600,
                          fontWeight: AppTheme.fontMedium,
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
          const SizedBox(height: 16),
          Text(
            'Chargement des pépites d\'or...',
            style: GoogleFonts.inter(
              fontSize: 16,
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
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Aucun résultat trouvé'
                : 'Aucune pépite d\'or disponible',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Essayez un autre terme de recherche'
                : 'Les citations apparaîtront ici',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.grey500,
            ),
          ),
        ],
      ),
    );
  }

  void _openPepiteDetail(PepiteOrModel pepite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PepiteDetailPage(pepite: pepite),
      ),
    );
  }

  void _sharePepite(PepiteOrModel pepite) {
    final text = '${pepite.description}\n\n'
        '${pepite.citations.map((c) => '"${c.texte}" - ${c.auteur}').join('\n\n')}\n\n'
        '#PépitesOr #Spiritualité';
    
    // Copier dans le presse-papier
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pépite copiée dans le presse-papier'),
        backgroundColor: AppTheme.greenStandard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

}
