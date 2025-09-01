import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/setlist_card_perfect13.dart';
import '../../../pages/setlist_detail_page.dart';

/// Onglet Setlists - Style Perfect 13
class SetlistsTabPerfect13 extends StatefulWidget {
  const SetlistsTabPerfect13({super.key});

  @override
  State<SetlistsTabPerfect13> createState() => _SetlistsTabPerfect13State();
}

class _SetlistsTabPerfect13State extends State<SetlistsTabPerfect13> {
  String _searchQuery = '';
  String? _selectedSetlistFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche et filtres pour setlists
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)),
            ]),
          child: Column(
            children: [
              // Recherche de setlists
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une setlist...',
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                }),
              
              const SizedBox(height: 12),
              
              // Filtres rapides
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tous', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cette semaine', 'week'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ce mois', 'month'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Favoris', 'favorites'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Récents', 'recent'),
                  ])),
            ])),
        
        // Liste des setlists
        Expanded(
          child: StreamBuilder<List<SetlistModel>>(
            stream: SongsFirebaseService.getSetlists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Impossible de charger les setlists',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer')),
                    ]));
              }

              final allSetlists = snapshot.data ?? [];
              final filteredSetlists = _filterSetlists(allSetlists);

              if (filteredSetlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        allSetlists.isEmpty ? 'Aucune setlist disponible' : 'Aucun résultat',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text(
                        allSetlists.isEmpty 
                          ? 'Les setlists créées apparaîtront ici'
                          : 'Essayez de modifier votre recherche',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredSetlists.length,
                  itemBuilder: (context, index) {
                    final setlist = filteredSetlists[index];
                    return SetlistCardPerfect13(
                      setlist: setlist,
                      onTap: () => _showSetlistDetails(setlist),
                      onMusicianMode: () => _startMusicianMode(setlist),
                      onConductorMode: () => _startConductorMode(setlist),
                    );
                  }));
            })),
      ]);
  }

  Widget _buildFilterChip(String label, String? filterType) {
    final isSelected = _selectedSetlistFilter == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSetlistFilter = selected ? filterType : null;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected 
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal));
  }

  Widget _buildEnhancedSetlistCard(SetlistModel setlist) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSetlistDetails(setlist),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et actions
                Row(
                  children: [
                    // Icône moderne
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                        ]),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20)),
                    
                    const SizedBox(width: 12),
                    
                    // Titre et infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setlist.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          if (setlist.serviceType != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              setlist.serviceType!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500)),
                          ],
                        ])),
                    
                    // Actions rapides
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                      onSelected: (value) => _handleSetlistAction(value, setlist),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('Voir les détails'),
                            contentPadding: EdgeInsets.zero)),
                        PopupMenuItem(
                          value: 'play',
                          child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Jouer la setlist'),
                            contentPadding: EdgeInsets.zero)),
                        PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Partager'),
                            contentPadding: EdgeInsets.zero)),
                        PopupMenuItem(
                          value: 'copy',
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Dupliquer'),
                            contentPadding: EdgeInsets.zero)),
                      ]),
                  ]),
                
                const SizedBox(height: 12),
                
                // Description si présente
                if (setlist.description.isNotEmpty) ...[
                  Text(
                    setlist.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                ],
                
                // Informations détaillées
                Row(
                  children: [
                    // Badge de date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(setlist.serviceDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ])),
                    
                    const SizedBox(width: 8),
                    
                    // Badge nombre de chants
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            '${setlist.songIds.length} chant${setlist.songIds.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onTertiaryContainer)),
                        ])),
                    
                    const Spacer(),
                    
                    // Indicateur de progression si applicable
                    _buildSetlistProgress(setlist),
                  ]),
              ])))));
  }

  Widget _buildSetlistProgress(SetlistModel setlist) {
    // Simuler un statut de progression basé sur la date
    final now = DateTime.now();
    final diff = setlist.serviceDate.difference(now).inDays;
    
    if (diff > 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Planifiée',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700)));
    } else if (diff >= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Bientôt',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.warningColor)));
    } else if (diff >= -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Actuelle',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.successColor)));
    }
    return const SizedBox.shrink();
  }

  List<SetlistModel> _filterSetlists(List<SetlistModel> setlists) {
    var filtered = setlists;

    // Filtrer par recherche textuelle
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((setlist) =>
          setlist.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          setlist.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (setlist.serviceType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Filtrer par période
    if (_selectedSetlistFilter != null) {
      final now = DateTime.now();
      switch (_selectedSetlistFilter) {
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(weekStart) &&
              setlist.serviceDate.isBefore(weekEnd)
          ).toList();
          break;
        case 'month':
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 0);
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(monthStart) &&
              setlist.serviceDate.isBefore(monthEnd)
          ).toList();
          break;
        case 'recent':
          final lastWeek = now.subtract(const Duration(days: 7));
          filtered = filtered.where((setlist) =>
              setlist.serviceDate.isAfter(lastWeek)
          ).toList();
          break;
        case 'favorites':
          // Pour l'instant, on peut simuler avec les setlists les plus récentes
          // Plus tard, on pourrait ajouter un système de favoris
          filtered = filtered.take(5).toList();
          break;
      }
    }

    // Trier par date de service (plus récent en premier)
    filtered.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    return filtered;
  }

  void _handleSetlistAction(String action, SetlistModel setlist) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetlistDetailPage(setlist: setlist)));
        break;
      case 'play':
        _playSetlist(setlist);
        break;
      case 'share':
        _shareSetlist(setlist);
        break;
      case 'copy':
        _duplicateSetlist(setlist);
        break;
    }
  }

  void _playSetlist(SetlistModel setlist) async {
    if (setlist.songIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette setlist ne contient aucun chant'),
          backgroundColor: AppTheme.warningColor));
      return;
    }

    try {
      final songs = await SongsFirebaseService.getSetlistSongs(setlist.songIds);
      if (songs.isNotEmpty && mounted) {
        // Pour l'instant, naviguer vers les détails de la setlist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetlistDetailPage(setlist: setlist)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }

  void _shareSetlist(SetlistModel setlist) {
    // Implémenter le partage de setlist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible')));
  }

  void _duplicateSetlist(SetlistModel setlist) {
    // Implémenter la duplication de setlist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de duplication bientôt disponible')));
  }

  void _startMusicianMode(SetlistModel setlist) {
    // Implémenter le mode musicien
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode musicien bientôt disponible')));
  }

  void _startConductorMode(SetlistModel setlist) {
    // Implémenter le mode conducteur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode conducteur bientôt disponible')));
  }

  void _showSetlistDetails(SetlistModel setlist) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistDetailPage(setlist: setlist)));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
