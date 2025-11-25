import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/sermons_provider.dart';
import 'providers/search_provider.dart';
import 'providers/notes_highlights_provider.dart';
import 'views/sermons_tab_view.dart';
import 'views/search_tab_view.dart';
import 'views/notes_highlights_tab_view.dart';

/// Page principale du module Le Message avec 3 onglets
class MessageHomePage extends StatefulWidget {
  const MessageHomePage({super.key});

  @override
  State<MessageHomePage> createState() => _MessageHomePageState();
}

class _MessageHomePageState extends State<MessageHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final sermonsProvider = context.read<SermonsProvider>();
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    await Future.wait([
      sermonsProvider.loadSermons(forceRefresh: true), // Force refresh pour mettre à jour avec le nouveau champ translator
      notesProvider.loadAll(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermons William Branham'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.library_books),
              text: 'Sermons',
            ),
            Tab(
              icon: Icon(Icons.search),
              text: 'Recherche',
            ),
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Notes',
            ),
          ],
        ),
        actions: [
          // Bouton pour ajouter un sermon
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSermon(),
            tooltip: 'Ajouter un sermon',
          ),
          // Indicateur de synchronisation
          Consumer<NotesHighlightsProvider>(
            builder: (context, notesProvider, _) {
              if (notesProvider.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              
              if (!notesProvider.isCloudAvailable) {
                return IconButton(
                  icon: const Icon(Icons.cloud_off, color: Colors.grey),
                  onPressed: () => _showSyncInfo(context),
                  tooltip: 'Non connecté',
                );
              }
              
              if (notesProvider.lastSyncTime != null) {
                final timeSinceSync = DateTime.now().difference(notesProvider.lastSyncTime!);
                final color = timeSinceSync.inMinutes > 60 ? Colors.orange : Colors.green;
                
                return IconButton(
                  icon: Icon(Icons.cloud_done, color: color),
                  onPressed: () => _showSyncInfo(context),
                  tooltip: 'Dernière sync: ${_formatSyncTime(timeSinceSync)}',
                );
              }
              
              return IconButton(
                icon: const Icon(Icons.cloud_queue),
                onPressed: () => _showSyncInfo(context),
                tooltip: 'Jamais synchronisé',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync_now',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Synchroniser maintenant'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync_stats',
                child: Row(
                  children: [
                    Icon(Icons.cloud_circle),
                    SizedBox(width: 8),
                    Text('Statistiques cloud'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Exporter mes données'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Importer des données'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Vider le cache'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SermonsTabView(isAdmin: true),
          SearchTabView(),
          NotesHighlightsTabView(),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final sermonsProvider = context.read<SermonsProvider>();
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    await Future.wait([
      sermonsProvider.loadSermons(forceRefresh: true),
      notesProvider.loadAll(forceRefresh: true),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données actualisées')),
      );
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'sync_now':
        await _syncNow();
        break;
      case 'sync_stats':
        await _showSyncStats();
        break;
      case 'export':
        await _exportData();
        break;
      case 'import':
        await _importData();
        break;
      case 'clear_cache':
        await _clearCache();
        break;
    }
  }
  
  /// Navigation vers la page d'ajout de sermon
  Future<void> _navigateToAddSermon() async {
    final result = await Navigator.pushNamed(context, '/search/add-sermon');
    
    if (result == true && mounted) {
      // Recharger les sermons après ajout
      final sermonsProvider = context.read<SermonsProvider>();
      await sermonsProvider.loadSermons(forceRefresh: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste des sermons actualisée'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Formate le temps depuis la dernière synchronisation
  String _formatSyncTime(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'à l\'instant';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inDays}j';
    }
  }
  
  /// Affiche les informations de synchronisation
  void _showSyncInfo(BuildContext context) {
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud),
            SizedBox(width: 8),
            Text('Synchronisation Cloud'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notesProvider.isCloudAvailable) ...[
              const Text(
                '✅ Connecté au cloud',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (notesProvider.lastSyncTime != null) ...[
                Text('Dernière synchronisation:'),
                Text(
                  _formatDateTime(notesProvider.lastSyncTime!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else ...[
                const Text('Jamais synchronisé'),
              ],
              const SizedBox(height: 16),
              Text(
                'Synchronisation automatique: ${notesProvider.autoSyncEnabled ? "Activée" : "Désactivée"}',
              ),
            ] else ...[
              const Text(
                '❌ Non connecté',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Connectez-vous pour synchroniser vos données entre appareils.'),
            ],
            if (notesProvider.syncError != null) ...[
              const SizedBox(height: 16),
              Text(
                'Erreur: ${notesProvider.syncError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          if (notesProvider.isCloudAvailable) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _syncNow();
              },
              child: const Text('Synchroniser'),
            ),
            TextButton(
              onPressed: () {
                notesProvider.setAutoSync(!notesProvider.autoSyncEnabled);
                Navigator.pop(context);
              },
              child: Text(notesProvider.autoSyncEnabled ? 'Désactiver auto-sync' : 'Activer auto-sync'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  /// Formate une date/heure
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? "s" : ""}';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? "s" : ""}';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? "s" : ""}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Synchronise maintenant
  Future<void> _syncNow() async {
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    if (!notesProvider.isCloudAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Non connecté. Connectez-vous pour synchroniser.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      await notesProvider.syncBidirectional();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Synchronisation terminée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Affiche les statistiques de synchronisation
  Future<void> _showSyncStats() async {
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    if (!notesProvider.isCloudAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Non connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Afficher un dialog de chargement
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des statistiques...'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    try {
      final stats = await notesProvider.getSyncStats();
      
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_circle),
                SizedBox(width: 8),
                Text('Statistiques Cloud'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Notes dans le cloud', '${stats['notesCount'] ?? 0}'),
                _buildStatRow('Surlignements dans le cloud', '${stats['highlightsCount'] ?? 0}'),
                const Divider(height: 24),
                _buildStatRow('Notes locales', '${notesProvider.allNotes.length}'),
                _buildStatRow('Surlignements locaux', '${notesProvider.allHighlights.length}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Afficher un dialog de progression
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Export en cours...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Collecter toutes les données
      final notesProvider = context.read<NotesHighlightsProvider>();
      final sermonsProvider = context.read<SermonsProvider>();
      final searchProvider = context.read<SearchProvider>();

      final notesJsonString = await notesProvider.exportData();
      final notesData = jsonDecode(notesJsonString) as Map<String, dynamic>;
      
      // Récupérer les favoris
      final favorites = sermonsProvider.allSermons
          .where((s) => s.isFavorite)
          .map((s) => s.id)
          .toList();

      // Récupérer l'historique de recherche
      final searchHistory = searchProvider.searchHistory;

      // Créer un objet JSON complet
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'favorites': favorites,
        'searchHistory': searchHistory,
        'notes': notesData['notes'] ?? [],
        'highlights': notesData['highlights'] ?? [],
      };

      // Convertir en JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Créer un fichier temporaire
      final directory = await getTemporaryDirectory();
      final fileName = 'wb_sermons_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Fermer le dialog de progression
      if (mounted) Navigator.pop(context);

      // Partager le fichier
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export Sermons William Branham',
        text: 'Mes notes, highlights et favoris des sermons de William Branham',
      );

      if (mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export réussi !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export annulé'),
            ),
          );
        }
      }

      // Nettoyer le fichier temporaire après un délai
      Future.delayed(const Duration(seconds: 10), () {
        if (file.existsSync()) {
          file.delete();
        }
      });
    } catch (e) {
      // Fermer le dialog si ouvert
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Sélectionner un fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // Utilisateur a annulé
        return;
      }

      final file = File(result.files.single.path!);
      
      // Afficher un dialog de progression
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Import en cours...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Lire le fichier
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Vérifier la version
      final version = data['version'] as String?;
      if (version != '1.0') {
        throw Exception('Version de fichier non supportée: $version');
      }

      // Demander confirmation
      if (mounted) Navigator.pop(context); // Fermer le dialog de progression
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer l\'import'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date d\'export: ${data['exportDate']}'),
              const SizedBox(height: 8),
              Text('Favoris: ${(data['favorites'] as List).length}'),
              Text('Historique: ${(data['searchHistory'] as List).length}'),
              Text('Notes: ${(data['notes'] as List).length}'),
              Text('Surlignements: ${(data['highlights'] as List).length}'),
              const SizedBox(height: 16),
              const Text(
                'Cela remplacera vos données actuelles.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Afficher à nouveau le dialog de progression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importation...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Importer les données
      final notesProvider = context.read<NotesHighlightsProvider>();
      final sermonsProvider = context.read<SermonsProvider>();
      final searchProvider = context.read<SearchProvider>();

      // Importer notes et highlights
      await notesProvider.importData(jsonString);

      // Importer favoris
      final favorites = (data['favorites'] as List).cast<String>();
      for (final sermonId in favorites) {
        final sermon = sermonsProvider.allSermons.firstWhere(
          (s) => s.id == sermonId,
          orElse: () => sermonsProvider.allSermons.first,
        );
        if (!sermon.isFavorite) {
          await sermonsProvider.toggleFavorite(sermonId);
        }
      }

      // Importer historique de recherche (en remplaçant)
      searchProvider.clearHistory();
      final history = (data['searchHistory'] as List).cast<String>();
      for (final query in history.reversed) {
        await searchProvider.quickSearch(query);
      }

      // Fermer le dialog et afficher succès
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import réussi !'),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les données
        await _handleRefresh();
      }
    } catch (e) {
      // Fermer le dialog si ouvert
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider le cache ? '
          'Les sermons seront rechargés depuis le serveur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final sermonsProvider = context.read<SermonsProvider>();
      await sermonsProvider.clearCache();
      await sermonsProvider.loadSermons(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache vidé')),
        );
      }
    }
  }
}
