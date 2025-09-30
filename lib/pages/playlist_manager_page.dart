import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';

class PlaylistManagerPage extends StatefulWidget {
  PlaylistManagerPage({Key? key}) : super(key: key);

  @override
  State<PlaylistManagerPage> createState() => _PlaylistManagerPageState();
}

class _PlaylistManagerPageState extends State<PlaylistManagerPage> {
  List<SetlistModel> _playlists = [];
  List<SongModel> _allSongs = [];
  SetlistModel? _selectedPlaylist;
  List<SongModel> _playlistSongs = [];
  bool _isEditMode = false;
  bool _isCreating = false;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await SongsFirebaseService.getSetlists().first;
      final songs = await SongsFirebaseService.getAllSongs();
      setState(() {
        _playlists = playlists;
        _allSongs = songs;
        if (_playlists.isNotEmpty) {
          _selectPlaylist(_playlists.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement: $e';
      });
    }
  }

  void _selectPlaylist(SetlistModel playlist) async {
    setState(() {
      _selectedPlaylist = playlist;
      _isEditMode = false;
    });
    // Récupérer les chants à partir de leurs IDs dans la setlist
    final songIds = playlist.songIds;
    final songs = <SongModel>[];
    for (final songId in songIds) {
      final song = _allSongs.where((s) => s.id == songId).firstOrNull;
      if (song != null) {
        songs.add(song);
      }
    }
    setState(() {
      _playlistSongs = songs;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _addSongToPlaylist(SongModel song) {
    setState(() {
      _playlistSongs.add(song);
    });
  }

  void _removeSongFromPlaylist(SongModel song) {
    setState(() {
      _playlistSongs.removeWhere((s) => s.id == song.id);
    });
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _playlistSongs.removeAt(oldIndex);
      _playlistSongs.insert(newIndex, item);
    });
  }

  Future<void> _savePlaylist() async {
    if (_selectedPlaylist == null) return;

    try {
      final songIds = _playlistSongs.map((s) => s.id).toList();
      final updatedPlaylist = _selectedPlaylist!.copyWith(
        songIds: songIds,
        updatedAt: DateTime.now(),
      );

      await SongsFirebaseService.updateSetlist(_selectedPlaylist!.id, updatedPlaylist);

      setState(() {
        _isEditMode = false;
        _selectedPlaylist = updatedPlaylist;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist sauvegardée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  Future<void> _createPlaylist() async {
    setState(() => _isCreating = true);

    try {
      final newPlaylist = SetlistModel(
        id: '',
        name: 'Nouvelle Playlist',
        description: '',
        songIds: [],
        serviceDate: DateTime.now(),
        createdBy: AuthService.currentUser?.uid ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await SongsFirebaseService.createSetlist(newPlaylist);
      if (id != null) {
        final playlist = newPlaylist.copyWith(id: id);
        setState(() {
          _playlists.add(playlist);
          _selectedPlaylist = playlist;
          _playlistSongs = [];
          _isEditMode = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _duplicatePlaylist() async {
    if (_selectedPlaylist == null) return;

    try {
      final duplicatedPlaylist = _selectedPlaylist!.copyWith(
        id: '',
        name: '${_selectedPlaylist!.name} (copie)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await SongsFirebaseService.createSetlist(duplicatedPlaylist);
      if (id != null) {
        final playlist = duplicatedPlaylist.copyWith(id: id);
        setState(() {
          _playlists.add(playlist);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist dupliquée avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la duplication: $e')),
      );
    }
  }

  void _sharePlaylist() {
    if (_selectedPlaylist == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à venir')),
    );
  }

  Future<void> _deletePlaylist() async {
    if (_selectedPlaylist == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la playlist'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${_selectedPlaylist!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SongsFirebaseService.deleteSetlist(_selectedPlaylist!.id);
        setState(() {
          _playlists.removeWhere((p) => p.id == _selectedPlaylist!.id);
          _selectedPlaylist = _playlists.isNotEmpty ? _playlists.first : null;
          _playlistSongs = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist supprimée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _manageCollaborators() {
    // TODO: Open dialog to manage collaborators
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion des collaborateurs à venir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isCreating ? null : _createPlaylist,
            tooltip: 'Créer une playlist',
          ),
          if (_selectedPlaylist != null) ...[
            IconButton(
              icon: Icon(_isEditMode ? Icons.save : Icons.edit),
              onPressed: _isEditMode ? _savePlaylist : _toggleEditMode,
              tooltip: _isEditMode ? 'Enregistrer' : 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _duplicatePlaylist,
              tooltip: 'Dupliquer la playlist',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePlaylist,
              tooltip: 'Partager la playlist',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePlaylist,
              tooltip: 'Supprimer la playlist',
            ),
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: _manageCollaborators,
              tooltip: 'Collaborateurs',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Liste des playlists
                Container(
                  width: 260,
                  color: AppTheme.grey100,
                  child: ListView(
                    children: _playlists.map((playlist) {
                      return ListTile(
                        title: Text(playlist.name),
                        selected: _selectedPlaylist?.id == playlist.id,
                        onTap: () => _selectPlaylist(playlist),
                      );
                    }).toList(),
                  ),
                ),
                // Détail de la playlist sélectionnée
                Expanded(
                  child: _selectedPlaylist == null
                      ? const Center(child: Text('Sélectionnez une playlist'))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _selectedPlaylist!.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_error!, style: const TextStyle(color: AppTheme.redStandard)),
                              ),
                            Expanded(
                              child: ReorderableListView(
                                onReorder: _isEditMode ? _reorderSongs : (_, __) {},
                                buildDefaultDragHandles: _isEditMode,
                                children: [
                                  for (int i = 0; i < _playlistSongs.length; i++)
                                    ListTile(
                                      key: ValueKey(_playlistSongs[i].id),
                                      title: Text(_playlistSongs[i].title),
                                      trailing: _isEditMode
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle, color: AppTheme.redStandard),
                                              onPressed: () => _removeSongFromPlaylist(_playlistSongs[i]),
                                            )
                                          : null,
                                    ),
                                ],
                              ),
                            ),
                            if (_isEditMode)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ajouter un chant à la playlist'),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: _allSongs
                                          .where((s) => !_playlistSongs.any((ps) => ps.id == s.id))
                                          .map((song) => ActionChip(
                                                label: Text(song.title),
                                                onPressed: () => _addSongToPlaylist(song),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
