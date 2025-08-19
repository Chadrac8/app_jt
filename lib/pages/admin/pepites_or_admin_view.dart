import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pepite_or_model.dart';
import '../../services/pepite_or_firebase_service.dart';
import '../../shared/widgets/custom_card.dart';
import '../../theme.dart';
import 'pepite_or_form_page.dart';
import 'pepite_or_detail_page.dart';

class PepitesOrAdminView extends StatefulWidget {
  const PepitesOrAdminView({super.key});

  @override
  State<PepitesOrAdminView> createState() => _PepitesOrAdminViewState();
}

class _PepitesOrAdminViewState extends State<PepitesOrAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isLoading = true;
  Map<String, dynamic> _statistiques = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerStatistiques();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerStatistiques() async {
    try {
      final stats = await PepiteOrFirebaseService.obtenirStatistiques();
      setState(() {
        _statistiques = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pépites d\'Or - Administration',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Toutes'),
            Tab(icon: Icon(Icons.published_with_changes), text: 'Publiées'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _afficherRecherche,
            tooltip: 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _actualiser,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToutesPepitesTab(),
          _buildPepitesPublieesTab(),
          _buildStatistiquesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterPepiteOr,
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Pépite'),
      ),
    );
  }

  Widget _buildToutesPepitesTab() {
    return StreamBuilder<List<PepiteOrModel>>(
      stream: PepiteOrFirebaseService.obtenirToutesPepitesOrStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pepites = snapshot.data ?? [];
        final pepitesFiltrees = _filtrerPepites(pepites);

        if (pepitesFiltrees.isEmpty) {
          return _buildEmptyState(
            'Aucune pépite d\'or trouvée',
            'Commencez par créer votre première pépite d\'or',
            Icons.auto_awesome,
          );
        }

        return RefreshIndicator(
          onRefresh: _actualiser,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pepitesFiltrees.length,
            itemBuilder: (context, index) {
              return _buildPepiteCard(pepitesFiltrees[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPepitesPublieesTab() {
    return StreamBuilder<List<PepiteOrModel>>(
      stream: PepiteOrFirebaseService.obtenirPepitesOrPublieesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final pepites = snapshot.data ?? [];
        final pepitesFiltrees = _filtrerPepites(pepites);

        if (pepitesFiltrees.isEmpty) {
          return _buildEmptyState(
            'Aucune pépite publiée',
            'Publiez vos pépites pour qu\'elles soient visibles aux membres',
            Icons.published_with_changes,
          );
        }

        return RefreshIndicator(
          onRefresh: _actualiser,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pepitesFiltrees.length,
            itemBuilder: (context, index) {
              return _buildPepiteCard(pepitesFiltrees[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatistiquesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu général',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Total Pépites',
                _statistiques['totalPepites']?.toString() ?? '0',
                Icons.auto_awesome,
                Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Publiées',
                _statistiques['pepitesPubliees']?.toString() ?? '0',
                Icons.published_with_changes,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Brouillons',
                _statistiques['pepitesBrouillons']?.toString() ?? '0',
                Icons.edit_note,
                Colors.orange,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Total Vues',
                _statistiques['totalVues']?.toString() ?? '0',
                Icons.visibility,
                Colors.purple,
              )),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Performance',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Moyenne de vues par pépite',
            (_statistiques['moyenneVuesParPepite']?.toStringAsFixed(1) ?? '0.0'),
            Icons.trending_up,
            Colors.teal,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPepiteCard(PepiteOrModel pepite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _voirDetail(pepite),
        borderRadius: BorderRadius.circular(12),
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
                          pepite.theme,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B4513),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pepite.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pepite.estPubliee ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pepite.estPubliee ? 'Publiée' : 'Brouillon',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _gererActionPepite(value, pepite),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'voir',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('Voir détail'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'modifier',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: pepite.estPubliee ? 'depublier' : 'publier',
                            child: Row(
                              children: [
                                Icon(
                                  pepite.estPubliee 
                                      ? Icons.unpublished 
                                      : Icons.publish,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(pepite.estPubliee ? 'Dépublier' : 'Publier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'supprimer',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pepite.premiereCitation.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        width: 3,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pepite.premiereCitation,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (pepite.premierAuteur.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '— ${pepite.premierAuteur}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    pepite.nomAuteur,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${pepite.dureeDeeLectureMinutes} min',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (pepite.estPubliee) ...[
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${pepite.nbVues}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.share, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${pepite.nbPartages}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String titre,
    String valeur,
    IconData icone,
    Color couleur, {
    bool isFullWidth = false,
  }) {
    return CustomCard(
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: couleur, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valeur,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: couleur,
                        ),
                      ),
                      Text(
                        titre,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String titre, String description, IconData icone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            titre,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _ajouterPepiteOr,
            icon: const Icon(Icons.add),
            label: const Text('Créer une pépite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<PepiteOrModel> _filtrerPepites(List<PepiteOrModel> pepites) {
    if (_searchQuery.isEmpty) return pepites;

    final query = _searchQuery.toLowerCase();
    return pepites.where((pepite) {
      return pepite.theme.toLowerCase().contains(query) ||
             pepite.description.toLowerCase().contains(query) ||
             pepite.nomAuteur.toLowerCase().contains(query) ||
             pepite.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _actualiser() async {
    await _chargerStatistiques();
  }

  void _afficherRecherche() {
    showSearch(
      context: context,
      delegate: PepiteOrSearchDelegate(
        onSearchChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
      ),
    );
  }

  void _ajouterPepiteOr() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PepiteOrFormPage(),
      ),
    );
  }

  void _voirDetail(PepiteOrModel pepite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PepiteOrDetailPage(pepite: pepite),
      ),
    );
  }

  void _gererActionPepite(String action, PepiteOrModel pepite) async {
    switch (action) {
      case 'voir':
        _voirDetail(pepite);
        break;
      case 'modifier':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PepiteOrFormPage(pepite: pepite),
          ),
        );
        break;
      case 'publier':
      case 'depublier':
        await _publierPepite(pepite, action == 'publier');
        break;
      case 'supprimer':
        await _confirmerSuppression(pepite);
        break;
    }
  }

  Future<void> _publierPepite(PepiteOrModel pepite, bool publier) async {
    try {
      await PepiteOrFirebaseService.publierPepiteOr(pepite.id, publier);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publier ? 'Pépite publiée avec succès' : 'Pépite dépubliée',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmerSuppression(PepiteOrModel pepite) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la pépite "${pepite.theme}" ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        await PepiteOrFirebaseService.supprimerPepiteOr(pepite.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pépite supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class PepiteOrSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearchChanged;

  PepiteOrSearchDelegate({required this.onSearchChanged});

  @override
  String get searchFieldLabel => 'Rechercher des pépites...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
          onSearchChanged('');
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearchChanged(query);
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
