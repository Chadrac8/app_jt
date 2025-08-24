import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import './bible_reading_view.dart';

class BibleMemberView extends StatefulWidget {
  const BibleMemberView({Key? key}) : super(key: key);

  @override
  State<BibleMemberView> createState() => _BibleMemberViewState();
}

class _BibleMemberViewState extends State<BibleMemberView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'La Bible',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'favorites':
                  _showFavorites();
                  break;
                case 'notes':
                  _showNotes();
                  break;
                case 'history':
                  _showHistory();
                  break;
                case 'settings':
                  _showPersonalSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'favorites',
                child: ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text('Mes favoris'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'notes',
                child: ListTile(
                  leading: Icon(Icons.note),
                  title: Text('Mes notes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Historique'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book),
              text: 'Lecture',
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Plans de Lecture',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: 'Études Bibliques',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Lecture - Vue exacte de Perfect 13 en mode membre
          const BibleReadingView(isAdminMode: false),
          
          // Onglet Plans de Lecture (vue membre)
          _buildMemberReadingPlansTab(),
          
          // Onglet Études Bibliques (vue membre)
          _buildMemberBibleStudiesTab(),
        ],
      ),
    );
  }

  Widget _buildMemberReadingPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec progression
          _buildProgressHeader(),
          
          const SizedBox(height: 24),
          
          // Plans disponibles
          _buildAvailablePlans(),
          
          const SizedBox(height: 24),
          
          // Mes plans actifs
          _buildMyActivePlans(),
        ],
      ),
    );
  }

  Widget _buildMemberBibleStudiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec progression
          _buildStudiesProgressHeader(),
          
          const SizedBox(height: 24),
          
          // Études disponibles
          _buildAvailableStudies(),
          
          const SizedBox(height: 24),
          
          // Mes études actives
          _buildMyActiveStudies(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes Plans de Lecture',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continuez votre parcours spirituel',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressStat('Plans suivis', '2'),
              const SizedBox(width: 24),
              _buildProgressStat('Jours de suite', '14'),
              const SizedBox(width: 24),
              _buildProgressStat('Progression', '68%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudiesProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes Études Bibliques',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approfondissez votre compréhension',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressStat('Études actives', '1'),
              const SizedBox(width: 24),
              _buildProgressStat('Terminées', '3'),
              const SizedBox(width: 24),
              _buildProgressStat('Points', '245'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans Disponibles',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlanCardMember(
          'Bible en 1 an',
          'Plan complet de lecture biblique',
          '365 jours',
          '125 participants',
          false,
        ),
        _buildPlanCardMember(
          'Nouveau Testament',
          'Lecture du NT en 3 mois',
          '90 jours',
          '89 participants',
          false,
        ),
        _buildPlanCardMember(
          'Psaumes & Proverbes',
          'Méditation quotidienne',
          '60 jours',
          '156 participants',
          false,
        ),
      ],
    );
  }

  Widget _buildMyActivePlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes Plans Actifs',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlanCardMember(
          'Bible en 1 an',
          'Plan complet de lecture biblique',
          'Jour 67 / 365',
          '68% complété',
          true,
        ),
        _buildPlanCardMember(
          'Psaumes & Proverbes',
          'Méditation quotidienne',
          'Jour 14 / 60',
          '23% complété',
          true,
        ),
      ],
    );
  }

  Widget _buildAvailableStudies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Études Disponibles',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildStudyCardMember(
          'Les Béatitudes',
          'Étude approfondie de Matthieu 5',
          '8 leçons',
          '67 participants',
          false,
        ),
        _buildStudyCardMember(
          'Le Fruit de l\'Esprit',
          'Galates 5:22-23 en détail',
          '9 leçons',
          '45 participants',
          false,
        ),
      ],
    );
  }

  Widget _buildMyActiveStudies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes Études Actives',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildStudyCardMember(
          'Les Béatitudes',
          'Étude approfondie de Matthieu 5',
          'Leçon 3 / 8',
          '37% complété',
          true,
        ),
      ],
    );
  }

  Widget _buildPlanCardMember(
    String title,
    String description,
    String duration,
    String info,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  ElevatedButton(
                    onPressed: () => _continuePlan(title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuer'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _joinPlan(title),
                    child: const Text('Rejoindre'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  info,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: title == 'Bible en 1 an' ? 0.68 : 0.23,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudyCardMember(
    String title,
    String description,
    String lessons,
    String info,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  ElevatedButton(
                    onPressed: () => _continueStudy(title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuer'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _joinStudy(title),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                    child: const Text('Rejoindre'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  lessons,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  info,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.37,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Méthodes d'action pour les membres
  void _continuePlan(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuer le plan "$planName"'),
      ),
    );
  }

  void _joinPlan(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejoindre le plan "$planName"'),
      ),
    );
  }

  void _continueStudy(String studyName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuer l\'étude "$studyName"'),
      ),
    );
  }

  void _joinStudy(String studyName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejoindre l\'étude "$studyName"'),
      ),
    );
  }

  void _showFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage des favoris (à implémenter)'),
      ),
    );
  }

  void _showNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage des notes (à implémenter)'),
      ),
    );
  }

  void _showHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage de l\'historique (à implémenter)'),
      ),
    );
  }

  void _showPersonalSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres personnels (à implémenter)'),
      ),
    );
  }
}
