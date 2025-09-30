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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.grey50!,
            AppTheme.surfaceColor,
          ])),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // En-tête avec padding top approprié
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête principal avec hiérarchie visuelle
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: AppTheme.white100,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'La Bible',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: AppTheme.fontBold,
                                  color: AppTheme.textPrimaryColor,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                'Explorez la Parole de Dieu',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Titre de section amélioré
                  Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modules Bibliques',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: AppTheme.fontBold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Découvrez tous nos outils d\'étude biblique',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Liste des modules bibliques avec espacement optimisé
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Plans de lecture
                  _buildReadingPlanHomeWidget(),
                  const SizedBox(height: 20),
                  
                  // Passages thématiques
                  _buildBibleModuleCard(
                    title: 'Passages thématiques',
                    subtitle: 'Découvrez des versets organisés par thèmes',
                    icon: Icons.topic,
                    color: AppTheme.primaryColor,
                    onTap: () {
                      // Navigation vers les passages thématiques
                      _navigateToThematicPassages();
                    }),
                  const SizedBox(height: 20),
                  
                  // Articles bibliques
                  _buildBibleModuleCard(
                    title: 'Articles bibliques',
                    subtitle: 'Études approfondies et commentaires',
                    icon: Icons.article,
                    color: AppTheme.infoColor,
                    onTap: () {
                      // Navigation vers les articles bibliques
                      _navigateToBibleArticles();
                    }),
                  const SizedBox(height: 20),
                  
                  // Pépites d'or (Citations de William Marrion Branham)
                  _buildBibleModuleCard(
                    title: 'Pépites d\'or',
                    subtitle: 'Condensé des citations du prophète William Marrion Branham',
                    icon: Icons.diamond,
                    color: AppTheme.warningColor,
                    onTap: () {
                      // Navigation vers les pépites d'or
                      _navigateToGoldenNuggets();
                    }),
                  
                  // Espacement final optimisé
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ]));
  }

  // Widget Plans de lecture - reproduction exacte de perfect 13
  Widget _buildReadingPlanHomeWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4)),
        ]),
      child: Material(
        color: Colors.transparent,
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
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successColor,
                        AppTheme.successColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.white100,
                    size: 28)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plans de lecture',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.textPrimaryColor)),
                      const SizedBox(height: 6),
                      Text(
                        'Programmes guidés pour explorer la Bible',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondaryColor,
                          height: 1.4)),
                    ])),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.successColor,
                    size: 18),
                ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4)),
        ]),
      child: Material(
        color: Colors.transparent,
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
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.white100,
                    size: 28)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.textPrimaryColor)),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondaryColor,
                          height: 1.4)),
                    ])),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 18),
                ),
              ])))));
  }

  // Méthodes de navigation - reproduction exacte de perfect 13
  void _navigateToReadingPlans() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Plans de lecture (prochainement)'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToThematicPassages() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Passages thématiques (prochainement)'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToBibleArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Articles bibliques (prochainement)'),
        backgroundColor: AppTheme.infoColor,
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToGoldenNuggets() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pépites d\'or (prochainement)'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating));
  }

}
