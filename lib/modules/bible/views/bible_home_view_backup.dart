import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/theme/app_theme.dart';

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
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: _buildDailyBreadPreviewWidget())),
          
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

  // Widget Pain quotidien - reproduction exacte de perfect 13
  Widget _buildDailyBreadPreviewWidget() {
    final verseText = 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
    final verseReference = 'Jean 3:16';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Colors.orange.withOpacity(0.05)!,
          ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4)),
        ]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                    ]),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: AppTheme.surfaceColor,
                    size: 22,
                  )),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pain quotidien',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800])),
                      Text(
                        _getCurrentDate(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.amber[600],
                          fontWeight: FontWeight.w500)),
                    ])),
                IconButton(
                  onPressed: () => _shareDailyBread(verseText, verseReference),
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: Colors.amber[700])),
              ]),
            
            const SizedBox(height: 16),
            
            // Quote container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Colors.amber[300],
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    verseText,
                    style: GoogleFonts.crimsonText(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        verseReference,
                        style: GoogleFonts.inter(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )))),
                ])),
          ])));
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
      SnackBar(
        content: Text('Plans de lecture (prochainement)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _navigateToThematicPassages() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Passages thématiques (prochainement)'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _navigateToBibleArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Articles bibliques (prochainement)'),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _navigateToGoldenNuggets() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pépites d\'or (prochainement)'),
        backgroundColor: Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  // Méthodes utilitaires - reproduction exacte de perfect 13
  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _shareDailyBread(String verseText, String verseReference) {
    final text = '"$verseText"\n\n$verseReference\n\nPain quotidien - Jubilé du Tabernacle';
    Share.share(
      text,
      subject: 'Pain quotidien');
  }
}

  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Découvrons ensemble',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getCurrentDate(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreadWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny,
                color: AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pain quotidien',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _shareDailyBread,
                icon: const Icon(Icons.share),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'En cours de développement - DailyBreadPreviewWidget',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildBibleModuleCard(
          title: 'Plans de lecture',
          subtitle: 'Programmes structurés',
          icon: Icons.calendar_today,
          color: Colors.blue,
          onTap: _navigateToReadingPlans,
        ),
        _buildBibleModuleCard(
          title: 'Passages thématiques',
          subtitle: 'Par sujets',
          icon: Icons.category,
          color: Colors.green,
          onTap: _navigateToThematicPassages,
        ),
        _buildBibleModuleCard(
          title: 'Articles Bible',
          subtitle: 'Études approfondies',
          icon: Icons.article,
          color: Colors.orange,
          onTap: _navigateToBibleArticles,
        ),
        _buildBibleModuleCard(
          title: 'Pépites d\u0027or',
          subtitle: 'Trésors cachés',
          icon: Icons.diamond,
          color: Colors.amber,
          onTap: _navigateToGoldenNuggets,
        ),
      ],
    );
  }

  Widget _buildBibleModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReadingPlans() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plans de lecture - En cours de développement')),
    );
  }

  void _navigateToThematicPassages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passages thématiques - En cours de développement')),
    );
  }

  void _navigateToBibleArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Articles Bible - En cours de développement')),
    );
  }

  void _navigateToGoldenNuggets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pépites d\u0027or - En cours de développement')),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour !';
    if (hour < 17) return 'Bon après-midi !';
    return 'Bonsoir !';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _shareDailyBread() {
    final text = 'Pain quotidien - Tabernacle de la Foi\n\nbranham.org';
    Share.share(
      text,
      subject: 'Pain quotidien',
    );
  }
}
