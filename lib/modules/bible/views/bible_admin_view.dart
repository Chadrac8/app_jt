import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import './bible_reading_view.dart';
import '../../../theme.dart';

class BibleAdminView extends StatefulWidget {
  const BibleAdminView({Key? key}) : super(key: key);

  @override
  State<BibleAdminView> createState() => _BibleAdminViewState();
}

class _BibleAdminViewState extends State<BibleAdminView>
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
          'Bible - Administration',
          style: GoogleFonts.inter(
            fontWeight: AppTheme.fontBold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'analytics':
                  _showAnalytics();
                  break;
                case 'settings':
                  _showGlobalSettings();
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistiques'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres globaux'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporter les données'),
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
          unselectedLabelColor: AppTheme.grey600,
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
          // Onglet Lecture - Vue exacte de Perfect 13
          const BibleReadingView(isAdminMode: true),
          
          // Onglet Plans de Lecture
          _buildReadingPlansTab(),
          
          // Onglet Études Bibliques
          _buildBibleStudiesTab(),
        ],
      ),
    );
  }

  Widget _buildReadingPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plans de Lecture',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Gérez les plans de lecture disponibles',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createNewPlan,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Statistiques rapides
          _buildQuickStats(),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Liste des plans (simulation)
          _buildPlansList(),
        ],
      ),
    );
  }

  Widget _buildBibleStudiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Études Bibliques',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Gérez les études bibliques disponibles',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createNewStudy,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle Étude'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Statistiques rapides
          _buildStudiesStats(),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Liste des études (simulation)
          _buildStudiesList(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Plans Actifs',
            '12',
            Icons.playlist_play,
            AppTheme.greenStandard,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Utilisateurs',
            '247',
            Icons.people,
            AppTheme.blueStandard,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Completions',
            '89%',
            Icons.check_circle,
            AppTheme.orangeStandard,
          ),
        ),
      ],
    );
  }

  Widget _buildStudiesStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Études Actives',
            '8',
            Icons.school,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Participants',
            '156',
            Icons.group,
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Progression',
            '76%',
            Icons.trending_up,
            AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize20,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    final plans = [
      {
        'title': 'Bible en 1 an',
        'description': 'Plan complet de lecture biblique',
        'participants': 125,
        'status': 'Actif',
        'category': 'Complet',
      },
      {
        'title': 'Nouveau Testament',
        'description': 'Lecture du NT en 3 mois',
        'participants': 89,
        'status': 'Actif',
        'category': 'NT',
      },
      {
        'title': 'Psaumes & Proverbes',
        'description': 'Méditation quotidienne',
        'participants': 156,
        'status': 'Actif',
        'category': 'Méditation',
      },
    ];

    return Column(
      children: plans.map((plan) => _buildPlanCard(plan)).toList(),
    );
  }

  Widget _buildStudiesList() {
    final studies = [
      {
        'title': 'Les Béatitudes',
        'description': 'Étude approfondie de Matthieu 5',
        'participants': 67,
        'status': 'Actif',
        'category': 'Enseignement',
      },
      {
        'title': 'Le Fruit de l\'Esprit',
        'description': 'Galates 5:22-23 en détail',
        'participants': 45,
        'status': 'Actif',
        'category': 'Vie chrétienne',
      },
      {
        'title': 'Les Paraboles',
        'description': 'Mystères du Royaume',
        'participants': 78,
        'status': 'En pause',
        'category': 'Paraboles',
      },
    ];

    return Column(
      children: studies.map((study) => _buildStudyCard(study)).toList(),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                        plan['title'],
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      Text(
                        plan['description'],
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePlanAction(value, plan),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Dupliquer'),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: Text('Statistiques'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                _buildInfoChip(Icons.people, '${plan['participants']} participants'),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildInfoChip(Icons.category, plan['category']),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildStatusChip(plan['status']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyCard(Map<String, dynamic> study) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                        study['title'],
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      Text(
                        study['description'],
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleStudyAction(value, study),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Dupliquer'),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: Text('Statistiques'),
                    ),
                    const PopupMenuItem(
                      value: 'pause',
                      child: Text('Mettre en pause'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                _buildInfoChip(Icons.group, '${study['participants']} participants'),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildInfoChip(Icons.school, study['category']),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildStatusChip(study['status']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.grey600),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'Actif' ? AppTheme.greenStandard : AppTheme.orangeStandard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize12,
          fontWeight: AppTheme.fontMedium,
          color: color,
        ),
      ),
    );
  }

  // Méthodes d'action
  void _createNewPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création d\'un nouveau plan (à implémenter)'),
      ),
    );
  }

  void _createNewStudy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création d\'une nouvelle étude (à implémenter)'),
      ),
    );
  }

  void _handlePlanAction(String action, Map<String, dynamic> plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action "$action" sur le plan "${plan['title']}"'),
      ),
    );
  }

  void _handleStudyAction(String action, Map<String, dynamic> study) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action "$action" sur l\'étude "${study['title']}"'),
      ),
    );
  }

  void _showAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage des statistiques (à implémenter)'),
      ),
    );
  }

  void _showGlobalSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres globaux (à implémenter)'),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des données (à implémenter)'),
      ),
    );
  }
}
