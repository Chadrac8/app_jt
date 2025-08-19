import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/admin_branham_sermon_model.dart';
import '../models/youtube_playlist_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/youtube_playlist_service.dart';
import '../widgets/sermon_form_dialog.dart';
import '../widgets/youtube_playlist_form_dialog.dart';
import '../widgets/admin_branham_messages_screen.dart';

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

  // Variables pour les playlists YouTube
  List<YouTubePlaylist> _playlists = [];
  bool _isLoadingPlaylists = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSermons();
    _loadPlaylists();
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
      _applySorting();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  void _filterSermons() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredSermons = List.from(_sermons);
      } else {
        _filteredSermons = _sermons.where((sermon) {
          return sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 sermon.date.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 sermon.location.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      _filteredSermons.sort((a, b) {
        int result;
        switch (_sortBy) {
          case 'title':
            result = a.title.compareTo(b.title);
            break;
          case 'displayOrder':
            result = a.displayOrder.compareTo(b.displayOrder);
            break;
          case 'date':
          default:
            result = a.date.compareTo(b.date);
            break;
        }
        return _sortAscending ? result : -result;
      });
    });
  }

  void _showSermonDialog([AdminBranhamSermon? sermon]) {
    showDialog(
      context: context,
      builder: (context) => SermonFormDialog(
        sermon: sermon,
        onSaved: (savedSermon) {
          _loadSermons(); // Recharger la liste
        },
      ),
    );
  }

  void _deleteSermon(AdminBranhamSermon sermon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la prédication'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${sermon.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await AdminBranhamSermonService.deleteSermon(sermon.id);
              if (success) {
                _showSuccessSnackBar('Prédication supprimée');
                _loadSermons();
              } else {
                _showErrorSnackBar('Erreur lors de la suppression');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleSermonStatus(AdminBranhamSermon sermon) async {
    final success = await AdminBranhamSermonService.toggleSermonStatus(
      sermon.id, 
      !sermon.isActive
    );
    if (success) {
      _showSuccessSnackBar(
        sermon.isActive ? 'Prédication désactivée' : 'Prédication activée'
      );
      _loadSermons();
    } else {
      _showErrorSnackBar('Erreur lors de la mise à jour');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
            Tab(text: 'Statistiques'),
            Tab(text: 'Playlists YouTube'),
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
          _buildStatisticsTab(),
          _buildPlaylistsTab(),
        ],
      ),
    );
  }

  Widget _buildSermonsListTab() {
    return Column(
      children: [
        // Barre de recherche et filtres
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre, date ou lieu...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterSermons();
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Trier par date')),
                  DropdownMenuItem(value: 'title', child: Text('Trier par titre')),
                  DropdownMenuItem(value: 'displayOrder', child: Text('Trier par ordre')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _sortBy = value;
                    _applySorting();
                  }
                },
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  _sortAscending = !_sortAscending;
                  _applySorting();
                },
              ),
            ],
          ),
        ),
        // Liste des prédications
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSermons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.audio_file,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'Aucune prédication trouvée'
                                : 'Aucun résultat pour "$_searchQuery"',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showSermonDialog(),
                            child: const Text('Ajouter une prédication'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSermons.length,
                      itemBuilder: (context, index) {
                        final sermon = _filteredSermons[index];
                        return _buildSermonCard(sermon);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSermonCard(AdminBranhamSermon sermon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sermon.isActive ? AppTheme.primaryColor : Colors.grey,
          child: Icon(
            sermon.isActive ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
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
                _deleteSermon(sermon);
                break;
            }
          },
        ),
        onTap: () => _showSermonDialog(sermon),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final totalSermons = _sermons.length;
    final activeSermons = _sermons.where((s) => s.isActive).length;
    final inactiveSermons = totalSermons - activeSermons;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des Prédications',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total',
                  value: totalSermons.toString(),
                  icon: Icons.audio_file,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Actives',
                  value: activeSermons.toString(),
                  icon: Icons.play_arrow,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Inactives',
                  value: inactiveSermons.toString(),
                  icon: Icons.pause,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_sermons.isNotEmpty) ...[
            Text(
              'Dernières modifications',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._sermons
                .where((s) => s.updatedAt != null)
                .take(5)
                .map((sermon) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(sermon.title),
                      subtitle: Text(
                        'Modifié le ${_formatDate(sermon.updatedAt!)}',
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Méthodes pour la gestion des playlists YouTube

  Future<void> _loadPlaylists() async {
    setState(() => _isLoadingPlaylists = true);
    
    try {
      final playlists = await YouTubePlaylistService.getAllPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      setState(() => _isLoadingPlaylists = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des playlists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPlaylistDialog([YouTubePlaylist? playlist]) {
    showDialog(
      context: context,
      builder: (context) => YouTubePlaylistFormDialog(
        playlist: playlist,
        onSave: _savePlaylist,
      ),
    );
  }

  Future<void> _savePlaylist(YouTubePlaylist playlist) async {
    try {
      if (playlist.id.isEmpty) {
        // Nouvelle playlist
        await YouTubePlaylistService.addPlaylist(playlist);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Modification de playlist existante
        await YouTubePlaylistService.updatePlaylist(playlist.id, playlist);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      _loadPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlaylist(YouTubePlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la playlist "${playlist.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await YouTubePlaylistService.deletePlaylist(playlist.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadPlaylists();
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

  Widget _buildPlaylistsTab() {
    if (_isLoadingPlaylists) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton d'ajout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playlists YouTube',
                style: GoogleFonts.openSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showPlaylistDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une playlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Liste des playlists
          Expanded(
            child: _playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune playlist configurée',
                          style: GoogleFonts.openSans(
                            fontSize: 18,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez une playlist YouTube pour commencer',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: playlist.isActive 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondaryColor,
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            playlist.title,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.playlistUrl,
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (playlist.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  playlist.description,
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: playlist.isActive 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      playlist.isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.openSans(
                                        fontSize: 10,
                                        color: playlist.isActive 
                                          ? Colors.green 
                                          : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modifiée le ${_formatDate(playlist.updatedAt)}',
                                    style: GoogleFonts.openSans(
                                      fontSize: 10,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showPlaylistDialog(playlist);
                                  break;
                                case 'delete':
                                  _deletePlaylist(playlist);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Modifier'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text('Supprimer', 
                                    style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
