import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pepite_or_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../services/pepite_or_firebase_service.dart';
import 'pepite_form_dialog.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({Key? key}) : super(key: key);

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> {
  List<PepiteOrModel> _pepites = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPepites();
  }

  Future<void> _loadPepites() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les pépites - récupérer toutes les pépites (publiées et non publiées) pour l'admin
      final pepites = await PepiteOrFirebaseService.obtenirPepitesOrParPage(
        limite: 1000, // Limite élevée pour récupérer toutes les pépites
        seulementPubliees: false, // Récupérer toutes les pépites pour l'admin
      );
      
      setState(() {
        _pepites = pepites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec titre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pépites d\'Or',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Gérez vos pépites spirituelles',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    onPressed: _loadPepites,
                    tooltip: 'Actualiser',
                  ),
                ],
              ),
            ),
            
            // Contenu des pépites d'or
            Expanded(
              child: _buildPepitesTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPepitesTab() {
    final filteredPepites = _getFilteredPepites();
    
    return Column(
      children: [
        // Barre de recherche et statistiques
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une pépite d\'or...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Statistiques
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      '${_pepites.length}',
                      Icons.auto_awesome,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Publiées',
                      '${_pepites.where((p) => p.estPubliee).length}',
                      Icons.visibility,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      '${_pepites.where((p) => !p.estPubliee).length}',
                      Icons.edit,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Bouton d'ajout
        Container(
          margin: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPepiteDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Pépite d\'Or'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // Liste des pépites
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPepitesList(filteredPepites),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPepitesList(List<PepiteOrModel> pepites) {
    if (pepites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'Aucune pépite d\'or trouvée'
                  : 'Aucun résultat pour "$_searchQuery"',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par créer votre première pépite spirituelle',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: pepites.length,
      itemBuilder: (context, index) {
        return _buildPepiteCard(pepites[index]);
      },
    );
  }

  Widget _buildPepiteCard(PepiteOrModel pepite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPepiteDialog(pepite),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pepite.theme,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pepite.estPubliee ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pepite.estPubliee ? 'Publiée' : 'Brouillon',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showPepiteDialog(pepite);
                          break;
                        case 'toggle':
                          _togglePepitePublication(pepite);
                          break;
                        case 'delete':
                          _deletePepite(pepite.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              pepite.estPubliee ? Icons.unpublished : Icons.publish,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(pepite.estPubliee ? 'Dépublier' : 'Publier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
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
              const SizedBox(height: 8),
              Text(
                pepite.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    pepite.nomAuteur,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (pepite.tags.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.label, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      pepite.tags.take(2).join(', '),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
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

  List<PepiteOrModel> _getFilteredPepites() {
    if (_searchQuery.isEmpty) return _pepites;
    
    return _pepites.where((pepite) {
      return pepite.theme.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             pepite.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             pepite.nomAuteur.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             pepite.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  void _showPepiteDialog([PepiteOrModel? pepite]) {
    showDialog(
      context: context,
      builder: (context) => PepiteFormDialog(
        pepite: pepite,
      ),
    ).then((_) => _loadPepites()); // Recharger après fermeture du dialog
  }

  Future<void> _togglePepitePublication(PepiteOrModel pepite) async {
    try {
      final updatedPepite = pepite.copyWith(estPubliee: !pepite.estPubliee);
      await PepiteOrFirebaseService.modifierPepiteOr(updatedPepite);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pepite.estPubliee 
                  ? 'Pépite dépubliée avec succès' 
                  : 'Pépite publiée avec succès'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadPepites(); // Recharger les données
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la publication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePepite(String pepiteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette pépite d\'or ? '
          'Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PepiteOrFirebaseService.supprimerPepiteOr(pepiteId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pépite supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _loadPepites(); // Recharger les données
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
