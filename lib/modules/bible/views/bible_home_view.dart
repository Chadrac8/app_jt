import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../pain_quotidien/widgets/daily_bread_preview_widget.dart';

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
            Colors.grey[50]!,
            AppTheme.surfaceColor,
          ])),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Pain quotidien professionnel - pleine largeur
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 16),
              child: DailyBreadPreviewWidget())),
          
          // Liste des modules bibliques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre de section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Modules Bibliques',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor))),
                  
                  // Plans de lecture
                  _buildReadingPlanHomeWidget(),
                  const SizedBox(height: 16),
                  
                  // Passages thématiques
                  _buildBibleModuleCard(
                    title: 'Passages thématiques',
                    subtitle: 'Découvrez des versets organisés par thèmes',
                    icon: Icons.topic,
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      // Navigation vers les passages thématiques
                      _navigateToThematicPassages();
                    }),
                  const SizedBox(height: 16),
                  
                  // Articles bibliques
                  _buildBibleModuleCard(
                    title: 'Articles bibliques',
                    subtitle: 'Études approfondies et commentaires',
                    icon: Icons.article,
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      // Navigation vers les articles bibliques
                      _navigateToBibleArticles();
                    }),
                  const SizedBox(height: 16),
                  
                  // Pépites d'or (Citations de William Marrion Branham)
                  _buildBibleModuleCard(
                    title: 'Pépites d\'or',
                    subtitle: 'Condensé des citations du prophète William Marrion Branham',
                    icon: Icons.diamond,
                    color: const Color(0xFFD4AF37), // Couleur or
                    onTap: () {
                      // Navigation vers les pépites d'or
                      _navigateToGoldenNuggets();
                    }),
                  const SizedBox(height: 40),
                ]))),
        ]));
  }

  // Widget Plans de lecture - reproduction exacte de perfect 13
  Widget _buildReadingPlanHomeWidget() {
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
          onTap: () {
            // Navigation vers les plans de lecture
            _navigateToReadingPlans();
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
