import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme.dart';

class BibleHomeView extends StatefulWidget {
  const BibleHomeView({super.key});

  @override
  State<BibleHomeView> createState() => _BibleHomeViewState();
}

class _BibleHomeViewState extends State<BibleHomeView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<BibleModule> _modules = [
    BibleModule(
      title: 'Plans de lecture',
      subtitle: 'Programmes guidés pour explorer la Bible',
      icon: Icons.calendar_today_outlined,
      color: AppTheme.blueStandard,
      onTap: null, // Will be set in initState
    ),
    BibleModule(
      title: 'Passages thématiques',
      subtitle: 'Découvrez des versets organisés par thèmes',
      icon: Icons.topic_outlined,
      color: AppTheme.greenStandard,
      onTap: null,
    ),
    BibleModule(
      title: 'Articles bibliques',
      subtitle: 'Études approfondies et commentaires',
      icon: Icons.article_outlined,
      color: AppTheme.pinkStandard,
      onTap: null,
    ),
    BibleModule(
      title: 'Pépites d\'or',
      subtitle: 'Citations inspirantes du prophète W.M. Branham',
      icon: Icons.diamond_outlined,
      color: AppTheme.orangeStandard,
      onTap: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupCallbacks();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    _animationController.forward();
  }

  void _setupCallbacks() {
    _modules[0] = _modules[0].copyWith(onTap: _navigateToReadingPlans);
    _modules[1] = _modules[1].copyWith(onTap: _navigateToThematicPassages);
    _modules[2] = _modules[2].copyWith(onTap: _navigateToBibleArticles);
    _modules[3] = _modules[3].copyWith(onTap: _navigateToGoldenNuggets);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      color: colorScheme.surface,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: AppTheme.isApplePlatform 
                ? const BouncingScrollPhysics()
                : const ClampingScrollPhysics(),
            slivers: [
              // Greeting Header
              SliverToBoxAdapter(
                child: _buildGreetingHeader(colorScheme, textTheme),
              ),
              
              // Bible Modules Grid
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.adaptivePadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final animationValue = Curves.easeOutCubic.transform(
                            (_animationController.value - delay).clamp(0.0, 1.0),
                          );
                          
                          return Transform.translate(
                            offset: Offset(0, (1 - animationValue) * 50),
                            child: Opacity(
                              opacity: animationValue,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ProfessionalBibleModuleCard(
                                  module: _modules[index],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: _modules.length,
                  ),
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.adaptivePadding,
        AppTheme.isApplePlatform ? 8 : 16,
        AppTheme.adaptivePadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La Bible',
                      style: AppTheme.isApplePlatform
                          ? textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            )
                          : textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explorez la Parole de Dieu',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

  // Navigation methods
  void _navigateToReadingPlans() {
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
    
    _showBibleModuleBottomSheet(
      title: 'Plans de lecture',
      icon: Icons.calendar_today_outlined,
      color: AppTheme.blueStandard,
      items: [
        _BibleModuleItem(
          title: 'Plan chronologique',
          subtitle: 'Lire la Bible dans l\'ordre chronologique des événements',
          icon: Icons.timeline_outlined,
          onTap: () => _navigateToSpecificPlan('chronological'),
        ),
        _BibleModuleItem(
          title: 'Plan en 1 an',
          subtitle: 'Lire toute la Bible en 365 jours',
          icon: Icons.date_range_outlined,
          onTap: () => _navigateToSpecificPlan('yearly'),
        ),
        _BibleModuleItem(
          title: 'Nouveau Testament',
          subtitle: 'Se concentrer sur les écrits du Nouveau Testament',
          icon: Icons.star_outline,
          onTap: () => _navigateToSpecificPlan('nt'),
        ),
        _BibleModuleItem(
          title: 'Psaumes & Proverbes',
          subtitle: 'Méditer sur la sagesse et les louanges',
          icon: Icons.favorite_outline,
          onTap: () => _navigateToSpecificPlan('psalms'),
        ),
      ],
    );
  }

  void _navigateToThematicPassages() {
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
    
    _showBibleModuleBottomSheet(
      title: 'Passages thématiques',
      icon: Icons.topic_outlined,
      color: AppTheme.greenStandard,
      items: [
        _BibleModuleItem(
          title: 'Amour et Compassion',
          subtitle: 'Versets sur l\'amour divin et la compassion',
          icon: Icons.favorite_outline,
          onTap: () => _navigateToTheme('love'),
        ),
        _BibleModuleItem(
          title: 'Foi et Confiance',
          subtitle: 'Passages encourageant la foi en Dieu',
          icon: Icons.church_outlined,
          onTap: () => _navigateToTheme('faith'),
        ),
        _BibleModuleItem(
          title: 'Paix et Espoir',
          subtitle: 'Versets apportant paix et espérance',
          icon: Icons.nature_people_outlined,
          onTap: () => _navigateToTheme('peace'),
        ),
        _BibleModuleItem(
          title: 'Sagesse et Direction',
          subtitle: 'Guidance divine pour les décisions',
          icon: Icons.lightbulb_outline,
          onTap: () => _navigateToTheme('wisdom'),
        ),
        _BibleModuleItem(
          title: 'Pardon et Grâce',
          subtitle: 'La miséricorde et le pardon de Dieu',
          icon: Icons.healing_outlined,
          onTap: () => _navigateToTheme('forgiveness'),
        ),
      ],
    );
  }

  void _navigateToBibleArticles() {
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
    
    _showBibleModuleBottomSheet(
      title: 'Articles bibliques',
      icon: Icons.article_outlined,
      color: AppTheme.pinkStandard,
      items: [
        _BibleModuleItem(
          title: 'Études doctrinales',
          subtitle: 'Approfondissement des doctrines chrétiennes',
          icon: Icons.school_outlined,
          onTap: () => _navigateToArticles('doctrinal'),
        ),
        _BibleModuleItem(
          title: 'Commentaires bibliques',
          subtitle: 'Exégèse et interprétation des Écritures',
          icon: Icons.comment_outlined,
          onTap: () => _navigateToArticles('commentary'),
        ),
        _BibleModuleItem(
          title: 'Prophéties',
          subtitle: 'Étude des prophéties bibliques',
          icon: Icons.visibility_outlined,
          onTap: () => _navigateToArticles('prophecy'),
        ),
        _BibleModuleItem(
          title: 'Histoire biblique',
          subtitle: 'Contexte historique des Écritures',
          icon: Icons.history_outlined,
          onTap: () => _navigateToArticles('history'),
        ),
      ],
    );
  }

  void _navigateToGoldenNuggets() {
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
    
    _showBibleModuleBottomSheet(
      title: 'Pépites d\'or',
      icon: Icons.diamond_outlined,
      color: AppTheme.orangeStandard,
      items: [
        _BibleModuleItem(
          title: 'Citations inspirantes',
          subtitle: 'Paroles édifiantes du prophète',
          icon: Icons.format_quote_outlined,
          onTap: () => _navigateToNuggets('inspirational'),
        ),
        _BibleModuleItem(
          title: 'Enseignements',
          subtitle: 'Instruction spirituelle profonde',
          icon: Icons.menu_book_outlined,
          onTap: () => _navigateToNuggets('teachings'),
        ),
        _BibleModuleItem(
          title: 'Révélations',
          subtitle: 'Insights spirituels révélés',
          icon: Icons.wb_sunny_outlined,
          onTap: () => _navigateToNuggets('revelations'),
        ),
        _BibleModuleItem(
          title: 'Messages thématiques',
          subtitle: 'Messages organisés par sujets',
          icon: Icons.category_outlined,
          onTap: () => _navigateToNuggets('thematic'),
        ),
      ],
    );
  }

  void _showBibleModuleBottomSheet({
    required String title,
    required IconData icon,
    required Color color,
    required List<_BibleModuleItem> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBottomSheetItem(item, colorScheme, textTheme),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(
    _BibleModuleItem item,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final itemContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: AppTheme.isApplePlatform ? 0.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            AppTheme.isApplePlatform ? Icons.chevron_right : Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
            size: AppTheme.isApplePlatform ? 24 : 16,
          ),
        ],
      ),
    );
    
    return AppTheme.isApplePlatform
        ? GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              item.onTap();
            },
            child: itemContent,
          )
        : InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pop(context);
              item.onTap();
            },
            child: itemContent,
          );
  }

  // Navigation stubs
  void _navigateToSpecificPlan(String planType) {
    // Afficher les détails du plan de lecture
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Plan: $planType'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ce plan de lecture vous guidera à travers: $planType'),
              const SizedBox(height: 16),
              const Text('Caractéristiques:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Lecture quotidienne structurée'),
              const Text('• Progression thématique'),
              const Text('• Notes et réflexions'),
              const Text('• Suivi de progression'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Plan "$planType" activé')),
              );
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _navigateToTheme(String theme) {
    // Afficher les passages thématiques dans un dialogue
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.category, color: AppTheme.secondaryColor),
            const SizedBox(width: 8),
            Text('Thème: $theme'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildThemePassage('Genèse 1:1-5', 'La création'),
              _buildThemePassage('Jean 3:16', 'L\'amour de Dieu'),
              _buildThemePassage('Romains 8:28', 'La providence divine'),
              _buildThemePassage('Psaume 23', 'La protection'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemePassage(String reference, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark, color: AppTheme.secondaryColor, size: 20),
        title: Text(reference),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ouverture: $reference')),
          );
        },
      ),
    );
  }

  void _navigateToArticles(String category) {
    // Navigation vers les articles bibliques
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.article, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Articles: $category'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Découvrez des articles enrichissants sur: $category'),
              const SizedBox(height: 16),
              const Text('Articles disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildArticleItem('Introduction à $category'),
              _buildArticleItem('Étude approfondie'),
              _buildArticleItem('Application pratique'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildArticleItem(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, size: 20),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ouverture: $title')),
          );
        },
      ),
    );
  }

  void _navigateToNuggets(String category) {
    // Navigation vers les pépites d'or (vérités bibliques précieuses)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Pépites: $category'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildNuggetCard(
                'La foi qui déplace les montagnes',
                'Marc 11:23',
                'La foi authentique n’est pas basée sur nos sentiments mais sur la Parole de Dieu.',
              ),
              _buildNuggetCard(
                'L’amour parfait',
                '1 Jean 4:18',
                'L’amour parfait bannit la crainte, car la crainte implique un châtiment.',
              ),
              _buildNuggetCard(
                'La prière efficace',
                'Jacques 5:16',
                'La prière du juste a une grande efficacité quand elle est fervente.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNuggetCard(String title, String reference, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reference,
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalBibleModuleCard extends StatefulWidget {
  final BibleModule module;

  const _ProfessionalBibleModuleCard({
    required this.module,
  });

  @override
  State<_ProfessionalBibleModuleCard> createState() => _ProfessionalBibleModuleCardState();
}

class _ProfessionalBibleModuleCardState extends State<_ProfessionalBibleModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cardContent = AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isPressed ? 0.98 : _hoverAnimation.value,
        child: Container(
          padding: EdgeInsets.all(AppTheme.actionCardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
              width: AppTheme.actionCardBorderWidth,
            ),
            boxShadow: AppTheme.isApplePlatform
                ? [] // iOS: Clean flat design
                : [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.module.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  widget.module.icon,
                  color: widget.module.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module.title,
                      style: AppTheme.isApplePlatform
                          ? textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            )
                          : textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.module.subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.module.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  AppTheme.isApplePlatform ? Icons.chevron_right : Icons.arrow_forward_ios,
                  color: widget.module.color,
                  size: AppTheme.isApplePlatform ? 24 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AppTheme.isApplePlatform
        ? GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.module.onTap,
            child: cardContent,
          )
        : InkWell(
            borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
            splashColor: widget.module.color.withValues(alpha: AppTheme.interactionOpacity),
            highlightColor: widget.module.color.withValues(alpha: AppTheme.interactionOpacity * 0.5),
            onTap: widget.module.onTap,
            onHover: (hovering) {
              if (hovering) {
                _hoverController.forward();
              } else {
                _hoverController.reverse();
              }
            },
            child: cardContent,
          );
  }
}

// Data classes
class BibleModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const BibleModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  BibleModule copyWith({
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return BibleModule(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      onTap: onTap ?? this.onTap,
    );
  }
}

class _BibleModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _BibleModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}