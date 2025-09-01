import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/admin_branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../widgets/sermon_form_dialog.dart';
import '../widgets/admin_branham_messages_screen.dart';
import '../widgets/admin_tab.dart';

/// Vue admin pour gérer les prédications de William Marrion Branham
class MessageAdminView extends StatefulWidget {
  const MessageAdminView({Key? key}) : super(key: key);

  @override
  State<MessageAdminView> createState() => _MessageAdminViewState();
}

class _MessageAdminViewState extends State<MessageAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<AdminBranhamSermon> _sermons = [];
  List<AdminBranhamSermon> _filteredSermons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, title, displayOrder
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSermons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSermons() async {
    setState(() => _isLoading = true);
    
    try {
      final sermons = await AdminBranhamSermonService.getAllSermons();
      setState(() {
        _sermons = sermons;
        _filteredSermons = sermons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des prédications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSermons() {
    setState(() {
      _filteredSermons = _sermons.where((sermon) {
        return sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               sermon.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      
      // Tri
      _filteredSermons.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
          case 'displayOrder':
            comparison = a.displayOrder.compareTo(b.displayOrder);
            break;
          case 'date':
          default:
            comparison = a.date.compareTo(b.date);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _showSermonDialog([AdminBranhamSermon? sermon]) {
    showDialog(
      context: context,
      builder: (context) => SermonFormDialog(
        sermon: sermon,
        onSaved: (savedSermon) {
          Navigator.of(context).pop();
          _loadSermons();
        },
      ),
    );
  }

  Future<void> _toggleSermonStatus(AdminBranhamSermon sermon) async {
    try {
      await AdminBranhamSermonService.updateSermon(
        sermon.id,
        sermon.copyWith(isActive: !sermon.isActive),
      );
      _loadSermons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sermon.isActive 
                ? 'Prédication désactivée' 
                : 'Prédication activée'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSermon(String sermonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette prédication ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminBranhamSermonService.deleteSermon(sermonId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prédication supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadSermons();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Prédications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Lire'),
            Tab(text: 'Liste des Prédications'),
            Tab(text: 'Pépites d\'Or'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSermonDialog(),
            tooltip: 'Ajouter une prédication',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSermons,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminBranhamMessagesScreen(),
          _buildSermonsListTab(),
          AdminTab(), // Onglet pour la gestion des pépites d'or
        ],
      ),
    );
  }

  Widget _buildSermonsListTab() {
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre ou lieu...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterSermons();
                },
              ),
              const SizedBox(height: 12),
              
              // Filtres de tri
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Trier par',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'title', child: Text('Titre')),
                        DropdownMenuItem(value: 'displayOrder', child: Text('Ordre d\'affichage')),
                      ],
                      onChanged: (value) {
                        setState(() => _sortBy = value!);
                        _filterSermons();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                      _filterSermons();
                    },
                    tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des prédications
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSermons.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune prédication trouvée',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredSermons.length,
                      itemBuilder: (context, index) {
                        return _buildSermonCard(_filteredSermons[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSermonCard(AdminBranhamSermon sermon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sermon.isActive ? Colors.green : Colors.grey,
          child: Text(
            sermon.displayOrder.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          sermon.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${sermon.date} • ${sermon.location}'),
            if (sermon.duration != null)
              Text('Durée: ${_formatDuration(sermon.duration!)}'),
            Text(
              'Statut: ${sermon.isActive ? "Actif" : "Inactif"}',
              style: TextStyle(
                color: sermon.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(sermon.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(sermon.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showSermonDialog(sermon);
                break;
              case 'toggle':
                _toggleSermonStatus(sermon);
                break;
              case 'delete':
                _deleteSermon(sermon.id);
                break;
            }
          },
        ),
        onTap: () => _showSermonDialog(sermon),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}
