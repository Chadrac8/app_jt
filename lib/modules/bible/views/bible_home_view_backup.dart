import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../pain_quotidien/widgets/daily_bread_preview_widget.dart';

class BibleHomeView extends StatefulWidget {
  const BibleHomeView({super.key});

  @override
  State<BibleHomeView> createState() => _BibleHomeViewState();
}

class _BibleHomeViewState extends State<BibleHomeView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  
  late AnimationController _animationController;

  // Catégories de modules bibliques avec design moderne
  final List<Map<String, dynamic>> _categories = [
    {
      'id': null,
      'label': 'Tous',
      'icon': Icons.all_inclusive,
      'color': const Color(0xFF6B73FF),
      'gradient': [const Color(0xFF6B73FF), const Color(0xFF9DD5EA)],
    },
    {
      'id': 'reading',
      'label': 'Lecture',
      'icon': Icons.menu_book,
      'color': const Color(0xFF4ECDC4),
      'gradient': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    },
    {
      'id': 'study',
      'label': 'Étude',
      'icon': Icons.school,
      'color': const Color(0xFFFF6B6B),
      'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFFB8B8)],
    },
    {
      'id': 'resources',
      'label': 'Ressources',
      'icon': Icons.library_books,
      'color': const Color(0xFFFFD93D),
      'gradient': [const Color(0xFFFFD93D), const Color(0xFF6BCF7F)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategory = categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Logique de rafraîchissement
        },
        color: const Color(0xFF6B73FF),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header avec barre de recherche et catégories - Style "Prières et témoignages"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barre de recherche moderne
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher dans les modules bibliques...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.textTertiaryColor,
                            fontSize: 15),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.textTertiaryColor,
                            size: 22),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppTheme.textTertiaryColor,
                                    size: 20))
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16)))),
                    const SizedBox(height: 16),

                    // Catégories horizontales compactes - Style identique
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category['id'];
                          
                          return Container(
                            margin: EdgeInsets.only(
                              right: index == _categories.length - 1 ? 0 : 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => _onCategorySelected(category['id']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: category['gradient'])
                                        : null,
                                    color: isSelected ? null : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : AppTheme.textTertiaryColor.withValues(alpha: 0.2),
                                      width: 1),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: category['color'].withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4)),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2)),
                                          ]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category['icon'],
                                        color: isSelected
                                            ? AppTheme.surfaceColor
                                            : category['color'],
                                        size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        category['label'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.surfaceColor
                                              : AppTheme.textSecondaryColor),
                                        overflow: TextOverflow.ellipsis),
                                    ])))));
                        })),
                  ],
                ),
              ),
            ),

            // Pain quotidien avec nouveau style
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DailyBreadPreviewWidget(),
                    const SizedBox(height: 24),
                  ]))),
            
            // Modules bibliques avec cartes modernes
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Modules Bibliques',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 16),
                  
                  // Plans de lecture
                  _buildModernModuleCard(
                    title: 'Plans de lecture',
                    subtitle: 'Découvrez des programmes de lecture structurés',
                    icon: Icons.auto_stories,
                    gradient: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                    category: 'reading',
                    onTap: () => _navigateToReadingPlans()),
                  const SizedBox(height: 12),
                  
                  // Passages thématiques
                  _buildModernModuleCard(
                    title: 'Passages thématiques',
                    subtitle: 'Découvrez des versets organisés par thèmes',
                    icon: Icons.topic,
                    gradient: [const Color(0xFF6B73FF), const Color(0xFF9DD5EA)],
                    category: 'study',
                    onTap: () => _navigateToThematicPassages()),
                  const SizedBox(height: 12),
                  
                  // Articles bibliques
                  _buildModernModuleCard(
                    title: 'Articles bibliques',
                    subtitle: 'Études approfondies et commentaires',
                    icon: Icons.article,
                    gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                    category: 'resources',
                    onTap: () => _navigateToBibleArticles()),
                  const SizedBox(height: 12),
                  
                  // Pépites d'or
                  _buildModernModuleCard(
                    title: 'Pépites d\'or',
                    subtitle: 'Citations du prophète William Marrion Branham',
                    icon: Icons.diamond,
                    gradient: [const Color(0xFFD4AF37), const Color(0xFFFFE082)],
                    category: 'resources',
                    onTap: () => _navigateToGoldenNuggets()),
                  const SizedBox(height: 24),
                ])),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de module moderne avec style "Prières et témoignages"
  Widget _buildModernModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String category,
    required VoidCallback onTap,
  }) {
    // Filtrage par catégorie
    if (_selectedCategory != null && _selectedCategory != category) {
      return const SizedBox.shrink();
    }
    
    // Filtrage par recherche
    if (_searchQuery.isNotEmpty) {
      final searchTerm = _searchQuery.toLowerCase();
      if (!title.toLowerCase().contains(searchTerm) &&
          !subtitle.toLowerCase().contains(searchTerm)) {
        return const SizedBox.shrink();
      }
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icône avec gradient
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4)),
                            ]),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24)),
                        const SizedBox(width: 16),
                        
                        // Contenu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor)),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor)),
                            ])),
                        
                        // Flèche
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.textTertiaryColor,
                          size: 16),
                      ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Méthodes de navigation
  void _navigateToReadingPlans() {
    // Navigation vers les plans de lecture
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plans de lecture - Bientôt disponible'))
    );
  }

  void _navigateToThematicPassages() {
    // Navigation vers les passages thématiques  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passages thématiques - Bientôt disponible'))
    );
  }

  void _navigateToBibleArticles() {
    // Navigation vers les articles bibliques
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Articles bibliques - Bientôt disponible'))
    );
  }

  void _navigateToGoldenNuggets() {
    // Navigation vers les pépites d'or
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pépites d\'or - Bientôt disponible'))
    );
  }
}
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.green,
                    size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plans de lecture',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor)),
                      const SizedBox(height: 4),
                      Text(
                        'Programmes guidés pour explorer la Bible',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                          height: 1.3)),
                    ])),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondaryColor,
                  size: 18),
              ])))));
  }

  // Méthode pour construire une carte de module biblique - reproduction exacte de perfect 13
  Widget _buildBibleModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                          height: 1.3)),
                    ])),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondaryColor,
                  size: 18),
              ])))));
  }

  // Méthodes de navigation - reproduction exacte de perfect 13
  void _navigateToReadingPlans() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plans de lecture (prochainement)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToThematicPassages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passages thématiques (prochainement)'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToBibleArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Articles bibliques (prochainement)'),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToGoldenNuggets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pépites d\'or (prochainement)'),
        backgroundColor: Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating));
  }

}
