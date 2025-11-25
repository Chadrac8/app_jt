import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import 'providers/sermons_provider.dart';
import 'providers/search_provider.dart';
import 'providers/notes_highlights_provider.dart';
import 'views/sermons_tab_view.dart';
import 'views/search_tab_view.dart';
import 'views/notes_highlights_tab_view.dart';

/// Page membre du module Le Message - Sermons William Branham
/// Vue simplifiée pour les membres de l'assemblée
class MessageMemberPage extends StatefulWidget {
  const MessageMemberPage({super.key});

  @override
  State<MessageMemberPage> createState() => _MessageMemberPageState();
}

class _MessageMemberPageState extends State<MessageMemberPage>
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
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // TabBar intégrée - Style MD3 avec fond Surface (identique à Vie de l'église)
          Container(
            color: AppTheme.surface,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                // Les couleurs sont héritées du TabBarTheme (primaryColor pour actif, gris pour inactif)
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
                    text: 'Mes Notes',
                  ),
                ],
              ),
            ),
          ),
          // Divider subtil MD3
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.grey300.withOpacity(0.5),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SermonsTabView(),
                SearchTabView(),
                NotesHighlightsTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncInfo(BuildContext context) {
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud),
            SizedBox(width: 8),
            Text('Synchronisation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notesProvider.isCloudAvailable) ...[
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Connecté au cloud'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (notesProvider.lastSyncTime != null) ...[
                Text(
                  'Dernière synchronisation:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDateTime(notesProvider.lastSyncTime!),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Synchronisation automatique: ${notesProvider.autoSyncEnabled ? "Activée" : "Désactivée"}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Vos notes et surlignements sont automatiquement sauvegardés et synchronisés entre tous vos appareils.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          if (notesProvider.isCloudAvailable) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _forceSyncNow();
              },
              child: const Text('Synchroniser maintenant'),
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

  Future<void> _forceSyncNow() async {
    final notesProvider = context.read<NotesHighlightsProvider>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Synchronisation en cours...'),
          ],
        ),
      ),
    );

    try {
      await Future.wait([
        notesProvider.syncBidirectional(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Synchronisation réussie'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sync':
        _forceSyncNow();
        break;
      case 'help':
        _showHelp();
        break;
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8),
            Text('Aide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment utiliser le module Sermons:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              
              Text('📚 Onglet Sermons', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Parcourez tous les sermons disponibles\n• Filtrez par date, langue ou série\n• Ajoutez des sermons à vos favoris'),
              SizedBox(height: 12),
              
              Text('🔍 Onglet Recherche', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Recherchez dans les titres et contenus\n• Utilisez des filtres avancés\n• Trouvez rapidement un sermon spécifique'),
              SizedBox(height: 12),
              
              Text('📝 Onglet Mes Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Consultez vos notes personnelles\n• Relisez vos passages surlignés\n• Organisez vos annotations par tags'),
              SizedBox(height: 12),
              
              Text('💡 Astuces', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Sélectionnez du texte pour créer une note\n• Changez la couleur des surlignements\n• Utilisez la recherche dans le texte\n• Ajustez la taille de police pour le confort'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'À l\'instant';
    } else if (duration.inMinutes < 60) {
      return 'Il y a ${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      return 'Il y a ${duration.inHours}h';
    } else {
      return 'Il y a ${duration.inDays}j';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
