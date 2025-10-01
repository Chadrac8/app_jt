import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pepite_or_model.dart';
import '../../../../theme.dart';
import '../../../services/pepite_or_firebase_service.dart';
import 'pepite_form_dialog.dart';
import '../../../theme.dart';

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
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.grey500,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec titre
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.white100,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black100.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pépites d\'Or',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize24,
                            fontWeight: AppTheme.fontBold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Gérez vos pépites spirituelles',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          color: AppTheme.white100,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une pépite d\'or...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.grey500),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey500,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              
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
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: _buildStatCard(
                      'Publiées',
                      '${_pepites.where((p) => p.estPubliee).length}',
                      Icons.visibility,
                      AppTheme.greenStandard,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      '${_pepites.where((p) => !p.estPubliee).length}',
                      Icons.edit,
                      AppTheme.orangeStandard,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Bouton d'ajout
        Container(
          margin: const EdgeInsets.all(AppTheme.spaceMedium),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPepiteDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Pépite d\'Or'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.white100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
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
              color: AppTheme.grey400,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _searchQuery.isEmpty 
                  ? 'Aucune pépite d\'or trouvée'
                  : 'Aucun résultat pour "$_searchQuery"',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                color: AppTheme.grey600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Commencez par créer votre première pépite spirituelle',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.grey500,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () => _showPepiteDialog(pepite),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pepite.theme,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pepite.estPubliee ? AppTheme.greenStandard : AppTheme.orangeStandard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      pepite.estPubliee ? 'Publiée' : 'Brouillon',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize10,
                        color: AppTheme.white100,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
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
                            SizedBox(width: AppTheme.spaceSmall),
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
                            const SizedBox(width: AppTheme.spaceSmall),
                            Text(pepite.estPubliee ? 'Dépublier' : 'Publier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.redStandard),
                            SizedBox(width: AppTheme.spaceSmall),
                            Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                pepite.description,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  color: AppTheme.grey700,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppTheme.grey500),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    pepite.nomAuteur,
                    style: GoogleFonts.inter(fontSize: AppTheme.fontSize12, color: AppTheme.grey600),
                  ),
                  if (pepite.tags.isNotEmpty) ...[
                    const SizedBox(width: AppTheme.spaceMedium),
                    Icon(Icons.label, size: 14, color: AppTheme.grey500),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      pepite.tags.take(2).join(', '),
                      style: GoogleFonts.inter(fontSize: AppTheme.fontSize12, color: AppTheme.grey600),
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
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
      
      _loadPepites(); // Recharger les données
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la publication: $e'),
            backgroundColor: AppTheme.redStandard,
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.redStandard),
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
              backgroundColor: AppTheme.greenStandard,
            ),
          );
        }
        
        _loadPepites(); // Recharger les données
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppTheme.redStandard,
            ),
          );
        }
      }
    }
  }
}
