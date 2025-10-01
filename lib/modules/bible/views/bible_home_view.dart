import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';

class BibleHomeView extends StatefulWidget {
  const BibleHomeView({super.key});

  @override
  State<BibleHomeView> createState() => _BibleHomeViewState();
}

class _BibleHomeViewState extends State<BibleHomeView> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Liste des modules bibliques directement sans en-tête
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spaceMedium, AppTheme.spaceLarge, AppTheme.spaceMedium, 0),
              child: Column(
                children: [
                  // Plans de lecture
                  _buildReadingPlanHomeWidget(),
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Passages thématiques
                  _buildBibleModuleCard(
                    title: 'Passages thématiques',
                    subtitle: 'Découvrez des versets organisés par thèmes',
                    icon: Icons.topic,
                    color: AppTheme.primaryColor,
                    onTap: _navigateToThematicPassages,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Articles bibliques
                  _buildBibleModuleCard(
                    title: 'Articles bibliques',
                    subtitle: 'Études approfondies et commentaires',
                    icon: Icons.article,
                    color: AppTheme.infoColor,
                    onTap: _navigateToBibleArticles,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Pépites d'or (Citations de William Marrion Branham)
                  _buildBibleModuleCard(
                    title: 'Pépites d\'or',
                    subtitle: 'Condensé des citations du prophète William Marrion Branham',
                    icon: Icons.diamond,
                    color: AppTheme.warningColor,
                    onTap: _navigateToGoldenNuggets,
                  ),
                  
                  // Espacement final optimisé
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ]));
  }

  // Widget Plans de lecture - Material Design 3
  Widget _buildReadingPlanHomeWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 1,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        onTap: () {
          // Navigation vers les plans de lecture
          _navigateToReadingPlans();
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plans de lecture',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: AppTheme.fontBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Programmes guidés pour explorer la Bible',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour construire une carte de module biblique - Material Design 3
  Widget _buildBibleModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = _getContainerColor(colorScheme, icon);
    final iconColor = _getIconColor(colorScheme, icon);
    final outlinedIcon = _getOutlinedIcon(icon);
    
    return Card(
      elevation: 1,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  outlinedIcon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: AppTheme.fontBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
                  color: containerColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: iconColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour Material Design 3
  Color _getContainerColor(ColorScheme colorScheme, IconData icon) {
    switch (icon) {
      case Icons.topic:
        return colorScheme.primaryContainer;
      case Icons.article:
        return colorScheme.secondaryContainer;
      case Icons.diamond:
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.surfaceVariant;
    }
  }
  
  Color _getIconColor(ColorScheme colorScheme, IconData icon) {
    switch (icon) {
      case Icons.topic:
        return colorScheme.onPrimaryContainer;
      case Icons.article:
        return colorScheme.onSecondaryContainer;
      case Icons.diamond:
        return colorScheme.onTertiaryContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
  
  IconData _getOutlinedIcon(IconData icon) {
    switch (icon) {
      case Icons.topic:
        return Icons.topic_outlined;
      case Icons.article:
        return Icons.article_outlined;
      case Icons.diamond:
        return Icons.diamond_outlined;
      default:
        return icon;
    }
  }

  // Méthodes de navigation - Material Design 3
  void _navigateToReadingPlans() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Plans de lecture',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisissez un plan de lecture pour structurer votre étude biblique',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              _buildReadingPlanOption(
                'Plan chronologique',
                'Lire la Bible dans l\'ordre chronologique des événements',
                Icons.timeline_rounded,
                colorScheme.primaryContainer,
                colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildReadingPlanOption(
                'Plan en 1 an',
                'Lire toute la Bible en 365 jours',
                Icons.date_range_rounded,
                colorScheme.secondaryContainer,
                colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildReadingPlanOption(
                'Nouveau Testament',
                'Se concentrer sur les écrits du Nouveau Testament',
                Icons.star_rounded,
                colorScheme.tertiaryContainer,
                colorScheme.onTertiaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildReadingPlanOption(
                'Psaumes & Proverbes',
                'Méditer sur la sagesse et les louanges',
                Icons.favorite_rounded,
                colorScheme.errorContainer,
                colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToThematicPassages() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.topic_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Passages thématiques',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explorer la Bible par thèmes spirituels',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              _buildThematicOption(
                'Amour et Compassion',
                'Versets sur l\'amour divin et la compassion',
                Icons.favorite_rounded,
                const Color(0xFFE57373),
                Colors.white,
              ),
              const SizedBox(height: 8),
              
              _buildThematicOption(
                'Foi et Confiance',
                'Passages encourageant la foi en Dieu',
                Icons.church_rounded,
                const Color(0xFF64B5F6),
                Colors.white,
              ),
              const SizedBox(height: 8),
              
              _buildThematicOption(
                'Paix et Espoir',
                'Versets apportant paix et espérance',
                Icons.nature_people_rounded,
                const Color(0xFF81C784),
                Colors.white,
              ),
              const SizedBox(height: 8),
              
              _buildThematicOption(
                'Sagesse et Direction',
                'Guidance divine pour les décisions',
                Icons.lightbulb_rounded,
                const Color(0xFFFFB74D),
                Colors.white,
              ),
              const SizedBox(height: 8),
              
              _buildThematicOption(
                'Pardon et Grâce',
                'La miséricorde et le pardon de Dieu',
                Icons.healing_rounded,
                const Color(0xFFBA68C8),
                Colors.white,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBibleArticles() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.article_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Articles bibliques',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Études approfondies et commentaires bibliques',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              _buildArticleOption(
                'Personnages bibliques',
                'Études biographiques des figures de la Bible',
                Icons.person_rounded,
                colorScheme.primaryContainer,
                colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildArticleOption(
                'Paraboles de Jésus',
                'Analyse et signification des paraboles',
                Icons.menu_book_rounded,
                colorScheme.secondaryContainer,
                colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildArticleOption(
                'Prophéties accomplies',
                'Les prophéties et leur accomplissement',
                Icons.schedule_rounded,
                colorScheme.tertiaryContainer,
                colorScheme.onTertiaryContainer,
              ),
              const SizedBox(height: 8),
              
              _buildArticleOption(
                'Contexte historique',
                'Background historique et culturel',
                Icons.history_edu_rounded,
                colorScheme.errorContainer,
                colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToGoldenNuggets() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.diamond_rounded,
              color: const Color(0xFFFFD700), // Couleur or
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Pépites d\'or',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Versets précieux pour l\'inspiration quotidienne',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              _buildGoldenNuggetCard(
                '"Car je connais les projets que j\'ai formés sur vous, dit l\'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l\'espérance."',
                'Jérémie 29:11',
                Icons.star_rounded,
              ),
              const SizedBox(height: 12),
              
              _buildGoldenNuggetCard(
                '"Je puis tout par celui qui me fortifie."',
                'Philippiens 4:13',
                Icons.fitness_center_rounded,
              ),
              const SizedBox(height: 12),
              
              _buildGoldenNuggetCard(
                '"L\'Éternel est mon berger: je ne manquerai de rien."',
                'Psaume 23:1',
                Icons.spa_rounded,
              ),
              const SizedBox(height: 12),
              
              _buildGoldenNuggetCard(
                '"Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle."',
                'Jean 3:16',
                Icons.favorite_rounded,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Méthodes de construction des widgets
  Widget _buildReadingPlanOption(String title, String description, IconData icon, Color bgColor, Color textColor) {
    return Card(
      elevation: 1,
      color: bgColor,
      child: ListTile(
        leading: Icon(icon, color: textColor, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: AppTheme.fontSemiBold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 16),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title sélectionné'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildThematicOption(String title, String description, IconData icon, Color bgColor, Color textColor) {
    return Card(
      elevation: 1,
      color: bgColor,
      child: ListTile(
        leading: Icon(icon, color: textColor, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: AppTheme.fontSemiBold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 16),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thème "$title" sélectionné'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildArticleOption(String title, String description, IconData icon, Color bgColor, Color textColor) {
    return Card(
      elevation: 1,
      color: bgColor,
      child: ListTile(
        leading: Icon(icon, color: textColor, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: AppTheme.fontSemiBold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 16),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Article "$title" sélectionné'),
              backgroundColor: AppTheme.infoColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGoldenNuggetCard(String verse, String reference, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFFFD700), // Couleur or
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reference,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Verset copié pour partage'),
                        backgroundColor: AppTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              verse,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
