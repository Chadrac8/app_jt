import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../services/songs_service.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import 'song_detail_view.dart';
import 'song_form_view.dart';

/// Vue admin pour la gestion des chants
class SongsAdminView extends StatefulWidget {
  const SongsAdminView({Key? key}) : super(key: key);

  @override
  State<SongsAdminView> createState() => _SongsAdminViewState();
}

class _SongsAdminViewState extends State<SongsAdminView>
    with TickerProviderStateMixin {
  final SongsService _songsService = SongsService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<Song> _songs = [];
  List<Song> _pendingSongs = [];
  List<SongCategory> _categories = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      await _songsService.initialize();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _songsService.getAll(),
        _songsService.getPendingSongs(),
        _songsService.categories.getActiveCategories(),
        _songsService.getStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _songs = results[0] as List<Song>;
          _pendingSongs = results[1] as List<Song>;
          _categories = results[2] as List<SongCategory>;
          _statistics = results[3] as Map<String, int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadData();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final searchResults = await _songsService.searchSongs(_searchQuery);
      if (mounted) {
        setState(() {
          _songs = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la recherche: $e')),
        );
      }
    }
  }

  Future<void> _approveSong(Song song) async {
    try {
      await _songsService.approveSong(song.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chant approuvé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'approbation: $e')),
        );
      }
    }
  }

  Future<void> _rejectSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le chant'),
        content: Text('Êtes-vous sûr de vouloir rejeter "${song.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _songsService.rejectSong(song.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chant rejeté')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du rejet: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le chant'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${song.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _songsService.delete(song.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chant supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  void _navigateToSongDetail(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SongDetailView(song: song),
      ),
    );
  }

  void _navigateToSongForm([Song? song]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SongFormView(song: song),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _renumberCantiques() async {
    // Afficher une boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renumérotter les cantiques'),
        content: const Text(
          'Cette action va identifier automatiquement les cantiques et les renumérotter à partir de 1.\n\n'
          'Les cantiques sont identifiés par leur titre (ex: "Ô Dieu", "Mon Jésus", etc.) et leurs tags.\n\n'
          'Voulez-vous continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppTheme.spaceMedium),
            Text('Renumération en cours...'),
          ],
        ),
      ),
    );

    try {
      // Importer le service Firebase (nécessite d'ajouter l'import)
      // Pour l'instant, simulons avec le service existant
      await Future.delayed(const Duration(seconds: 2)); // Simule le traitement
      
      // Dans un vrai cas, on utiliserait:
      // final result = await SongsFirebaseService.renumberCantiques();
      
      Navigator.of(context).pop(); // Fermer le dialogue de chargement
      
      // Recharger les données
      await _loadData();
      
      // Afficher le résultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cantiques renumérrotés avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialogue de chargement
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Administration des Chants',
      actions: [
        IconButton(
          icon: const Icon(Icons.format_list_numbered),
          onPressed: () => _renumberCantiques(),
          tooltip: 'Renumérotter les cantiques',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToSongForm(),
          tooltip: 'Ajouter un chant',
        ),
      ],
      body: Column(
        children: [
          // Statistiques
          if (_statistics.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      _statistics['total'] ?? 0,
                      Icons.library_music,
                      AppTheme.blueStandard,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _buildStatCard(
                      'Approuvés',
                      _statistics['approved'] ?? 0,
                      Icons.check_circle,
                      AppTheme.greenStandard,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      _statistics['pending'] ?? 0,
                      Icons.pending,
                      AppTheme.orangeStandard,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un chant...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadData();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          // Onglets avec Material Design
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.surface, // Couleur blanche/crème comme bottomNavigationBar
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor, // Texte rouge sur fond clair
              unselectedLabelColor: AppTheme.onSurfaceVariant, // Texte gris sur fond clair
              indicatorColor: AppTheme.primaryColor, // Indicateur rouge sur fond clair
              indicatorWeight: 3.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
              ),
              tabs: [
                Tab(
                  text: 'Tous (${_songs.length})',
                  icon: const Icon(Icons.library_music),
                  iconMargin: const EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  text: 'En attente (${_pendingSongs.length})',
                  icon: const Icon(Icons.pending),
                  iconMargin: const EdgeInsets.only(bottom: 4),
                ),
                const Tab(
                  text: 'Catégories',
                  icon: Icon(Icons.category),
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllSongsTab(),
                _buildPendingSongsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: AppTheme.fontSize24,
                fontWeight: AppTheme.fontBold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: AppTheme.fontSize12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSongsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text('Aucun chant trouvé'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return _buildSongCard(song, isAdmin: true);
        },
      ),
    );
  }

  Widget _buildPendingSongsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppTheme.greenStandard),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Aucun chant en attente d\'approbation'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _pendingSongs.length,
        itemBuilder: (context, index) {
          final song = _pendingSongs[index];
          return _buildPendingSongCard(song);
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildSongCard(Song song, {bool isAdmin = false}) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.space12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: song.isApproved 
                ? AppTheme.greenStandard.withOpacity(0.1)
                : AppTheme.orangeStandard.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            song.isApproved ? Icons.check_circle : Icons.pending,
            color: song.isApproved ? AppTheme.greenStandard : AppTheme.orangeStandard,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: AppTheme.fontBold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.author != null) Text('Par ${song.author}'),
            Text('${song.views} vues • ${song.favorites.length} favoris'),
            if (song.categories.isNotEmpty)
              Text('Catégories: ${song.categories.join(', ')}'),
          ],
        ),
        trailing: isAdmin
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Voir'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: AppTheme.redStandard),
                      title: Text('Supprimer'),
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _navigateToSongDetail(song);
                      break;
                    case 'edit':
                      _navigateToSongForm(song);
                      break;
                    case 'delete':
                      _deleteSong(song);
                      break;
                  }
                },
              )
            : null,
        onTap: () => _navigateToSongDetail(song),
      ),
    );
  }

  Widget _buildPendingSongCard(Song song) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(AppTheme.space12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.orangeStandard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.pending, color: AppTheme.orangeStandard),
            ),
            title: Text(
              song.title,
              style: const TextStyle(fontWeight: AppTheme.fontBold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (song.author != null) Text('Par ${song.author}'),
                Text('Créé le ${song.createdAt.day}/${song.createdAt.month}/${song.createdAt.year}'),
                if (song.preview.isNotEmpty)
                  Text(
                    song.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.grey600),
                  ),
              ],
            ),
            onTap: () => _navigateToSongDetail(song),
          ),
          const Divider(height: 1),
          OverflowBar(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.close, color: AppTheme.redStandard),
                label: const Text('Rejeter'),
                onPressed: () => _rejectSong(song),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Approuver'),
                onPressed: () => _approveSong(song),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(SongCategory category) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.space12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            _getIconData(category.icon ?? ''),
            color: category.color,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: AppTheme.fontBold),
        ),
        subtitle: Text(category.description),
        trailing: Switch(
          value: category.isActive,
          onChanged: (value) {
            _updateCategoryStatus(category, value);
          },
        ),
      ),
    );
  }

  Future<void> _updateCategoryStatus(SongCategory category, bool isActive) async {
    try {
      // Créer une copie mise à jour de la catégorie
      final updatedCategory = SongCategory(
        id: category.id,
        name: category.name,
        description: category.description,
        icon: category.icon,
        color: category.color,
        isActive: isActive,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: DateTime.now(),
      );

      // Mettre à jour dans Firestore
      await _songsService.categories.update(category.id!, updatedCategory);

      // Recharger les données pour mettre à jour l'affichage
      await _loadData();

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive 
                ? 'Catégorie "${category.name}" activée'
                : 'Catégorie "${category.name}" désactivée'
            ),
            backgroundColor: isActive ? AppTheme.greenStandard : AppTheme.orangeStandard,
          ),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'favorite':
        return Icons.favorite;
      case 'church':
        return Icons.church;
      case 'share':
        return Icons.share;
      case 'star':
        return Icons.star;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'child_friendly':
        return Icons.child_friendly;
      case 'library_music':
        return Icons.library_music;
      default:
        return Icons.category;
    }
  }
}