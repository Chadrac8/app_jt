import 'package:flutter/material.dart';
import '../../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/prayer_model.dart';
import '../../../services/prayers_firebase_service.dart';
import '../../../pages/prayer_form_page.dart';
import '../../../pages/prayer_detail_page.dart';

/// Onglet "Prières" moderne du module Vie de l'église
/// Design inspiré des meilleures applications d'église
class PrayerWallTab extends StatefulWidget {
  const PrayerWallTab({Key? key}) : super(key: key);

  @override
  State<PrayerWallTab> createState() => _PrayerWallTabState();
}

class _PrayerWallTabState extends State<PrayerWallTab>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  PrayerType? _selectedType;
  bool _isLoading = true;
  List<PrayerModel> _prayers = [];
  List<PrayerModel> _filteredPrayers = [];
  
  late AnimationController _animationController;

  // Catégories de prières avec couleurs modernes Material Design 3
  final List<Map<String, dynamic>> _categories = [
    {
      'type': null,
      'label': 'Toutes',
      'icon': Icons.all_inclusive,
      'color': AppTheme.textSecondaryColor, // MD3 color token
      'gradient': [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
    },
    {
      'type': PrayerType.request,
      'label': 'Demandes',
      'icon': Icons.volunteer_activism,
      'color': AppTheme.primaryColor, // MD3 color token
      'gradient': [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
    },
    {
      'type': PrayerType.thanksgiving,
      'label': 'Actions de grâce',
      'icon': Icons.celebration,
      'color': AppTheme.secondaryColor, // MD3 color token
      'gradient': [AppTheme.secondaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.05)],
    },
    {
      'type': PrayerType.testimony,
      'label': 'Témoignages',
      'icon': Icons.auto_awesome,
      'color': AppTheme.tertiaryColor, // MD3 color token
      'gradient': [AppTheme.tertiaryColor.withOpacity(0.1), AppTheme.tertiaryColor.withOpacity(0.05)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPrayers();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPrayers() async {
    try {
      setState(() => _isLoading = true);
      
      // Écouter le stream des prières
      PrayersFirebaseService.getPrayersStream().listen((prayers) {
        if (mounted) {
          setState(() {
            _prayers = prayers.where((p) => p.isApproved && !p.isArchived).toList();
            _isLoading = false;
          });
          _applyFilters();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPrayers = _prayers.where((prayer) {
        // Filtre par type
        if (_selectedType != null && prayer.type != _selectedType) {
          return false;
        }
        
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final searchTerm = _searchQuery.toLowerCase();
          return prayer.title.toLowerCase().contains(searchTerm) ||
                 prayer.content.toLowerCase().contains(searchTerm) ||
                 prayer.authorName.toLowerCase().contains(searchTerm);
        }
        
        return true;
      }).toList();
      
      // Trier par date (plus récent en premier)
      _filteredPrayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onCategorySelected(PrayerType? type) {
    setState(() => _selectedType = type);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadPrayers,
        color: const Color(0xFF6B73FF),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Barre de recherche et catégories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  children: [
                    // Barre de recherche
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black100.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher dans les prières...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.textTertiaryColor,
                            fontSize: AppTheme.fontSize15),
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
                    const SizedBox(height: AppTheme.spaceMedium),

                    // Catégories horizontales (compactes)
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedType == category['type'];
                          
                          return Container(
                            margin: EdgeInsets.only(
                              right: index == _categories.length - 1 ? 0 : 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => _onCategorySelected(category['type']),
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
                                              color: AppTheme.black100.withValues(alpha: 0.05),
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
                                      const SizedBox(width: AppTheme.space6),
                                      Text(
                                        category['label'],
                                        style: GoogleFonts.inter(
                                          fontSize: AppTheme.fontSize12,
                                          fontWeight: AppTheme.fontSemiBold,
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

            // Liste des prières
            if (_isLoading)
              SliverToBoxAdapter(
                child: _buildLoadingState())
            else if (_filteredPrayers.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildModernPrayerCard(_filteredPrayers[index], index);
                    },
                    childCount: _filteredPrayers.length))),
          ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPrayer,
        backgroundColor: const Color(0xFF6B73FF),
        foregroundColor: AppTheme.surfaceColor,
        elevation: 8,
        icon: const Icon(Icons.add, size: 24),
        label: Text(
          'Nouvelle prière',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30))));
  }

  Widget _buildModernPrayerCard(PrayerModel prayer, int index) {
    final category = _categories.firstWhere(
      (c) => c['type'] == prayer.type,
      orElse: () => _categories[0]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child));
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black100.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4)),
            ]),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              onTap: () => _navigateToPrayerDetail(prayer),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec catégorie et date
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.isApplePlatform ? 12 : 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: category['gradient']),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 14,
                                  color: AppTheme.surfaceColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    category['label'],
                                    style: GoogleFonts.inter(
                                      fontSize: AppTheme.isApplePlatform ? 12 : 11,
                                      fontWeight: AppTheme.fontSemiBold,
                                      color: AppTheme.surfaceColor,
                                      height: 1.2,
                                      letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(prayer.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.isApplePlatform ? 12 : 11,
                            color: AppTheme.textTertiaryColor,
                            fontWeight: AppTheme.fontMedium,
                            height: 1.2,
                          )),
                      ]),
                    const SizedBox(height: AppTheme.space12),

                    // Titre
                    Text(
                      prayer.title,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.isApplePlatform ? 16 : 15,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.textPrimaryColor,
                        height: 1.3,
                        letterSpacing: AppTheme.isApplePlatform ? -0.2 : -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppTheme.space12),

                    // Contenu
                    Text(
                      prayer.content,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.isApplePlatform ? 14 : 13,
                        color: AppTheme.textTertiaryColor,
                        height: 1.5,
                        letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppTheme.spaceMedium),

                    // Footer avec auteur et actions
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.isApplePlatform ? AppTheme.spaceSmall : 6),
                          decoration: BoxDecoration(
                            color: category['color'].withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: category['color'])),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prayer.authorName,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.isApplePlatform ? 14 : 13,
                              fontWeight: AppTheme.fontSemiBold,
                              color: AppTheme.textTertiaryColor,
                              height: 1.2,
                              letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.isApplePlatform ? 12 : 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FE),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: AppTheme.errorColor),
                              const SizedBox(width: 4),
                              Text(
                                'Prier',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.isApplePlatform ? 12 : 11,
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: AppTheme.textTertiaryColor,
                                  height: 1.2,
                                  letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
                                )),
                            ])),
                      ]),
                  ])))))));
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: const CircularProgressIndicator(
              color: Color(0xFF6B73FF),
              strokeWidth: 3)),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Chargement des prières...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textTertiaryColor)),
        ]));
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.textTertiaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: Icon(
              Icons.volunteer_activism,
              size: 64,
              color: AppTheme.textTertiaryColor)),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Aucune prière trouvée',
            style: GoogleFonts.inter( // Material Design 3 typography
              fontSize: AppTheme.fontSize16, // titleMedium
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textSecondaryColor)), // MD3 color token
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Soyez le premier à partager une prière\nou modifiez vos filtres de recherche',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textTertiaryColor),
            textAlign: TextAlign.center),
        ]));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  void _navigateToAddPrayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrayerFormPage())).then((_) => _loadPrayers());
  }

  void _navigateToPrayerDetail(PrayerModel prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerDetailPage(prayer: prayer)));
  }
}
