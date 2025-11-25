import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_highlights_provider.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';
import '../widgets/note_card.dart';
import '../widgets/highlight_card.dart';
import '../widgets/note_form_dialog.dart';

/// Vue de l'onglet "Notes & Surlignements"
class NotesHighlightsTabView extends StatefulWidget {
  const NotesHighlightsTabView({super.key});

  @override
  State<NotesHighlightsTabView> createState() => _NotesHighlightsTabViewState();
}

class _NotesHighlightsTabViewState extends State<NotesHighlightsTabView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<NotesHighlightsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildSearchBar(provider),
            _buildTabBar(),
            Expanded(
              child: _buildTabBarView(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(NotesHighlightsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans mes notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showNoteDialog(provider),
            tooltip: 'Nouvelle note',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(
          icon: Icon(Icons.note),
          text: 'Notes',
        ),
        Tab(
          icon: Icon(Icons.highlight),
          text: 'Surlignements',
        ),
      ],
    );
  }

  Widget _buildTabBarView(NotesHighlightsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadAll(forceRefresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotesList(provider),
        _buildHighlightsList(provider),
      ],
    );
  }

  Widget _buildNotesList(NotesHighlightsProvider provider) {
    final notes = provider.notes;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? 'Aucune note pour le moment'
                  : 'Aucune note trouvée',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showNoteDialog(provider),
              icon: const Icon(Icons.add),
              label: const Text('Créer une note'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            onTap: () => _showNoteDialog(provider, note: note),
            onDelete: () => _deleteNote(provider, note),
          );
        },
      ),
    );
  }

  Widget _buildHighlightsList(NotesHighlightsProvider provider) {
    final highlights = provider.highlights;

    if (highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.highlight_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? 'Aucun surlignement pour le moment'
                  : 'Aucun surlignement trouvé',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ouvrez un sermon pour surligner du texte',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: highlights.length,
        itemBuilder: (context, index) {
          final highlight = highlights[index];
          return HighlightCard(
            highlight: highlight,
            onTap: () => _navigateToHighlight(highlight),
            onDelete: () => _deleteHighlight(provider, highlight),
          );
        },
      ),
    );
  }

  void _showNoteDialog(NotesHighlightsProvider provider, {SermonNote? note}) {
    showDialog(
      context: context,
      builder: (context) => NoteFormDialog(
        note: note,
        onSave: (newNote) async {
          await provider.saveNote(newNote);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  note == null ? 'Note créée' : 'Note mise à jour',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteNote(
    NotesHighlightsProvider provider,
    SermonNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${note.title}" ?'),
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

    if (confirmed == true) {
      await provider.deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note supprimée')),
        );
      }
    }
  }

  Future<void> _deleteHighlight(
    NotesHighlightsProvider provider,
    SermonHighlight highlight,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le surlignement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce surlignement ?'),
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

    if (confirmed == true) {
      await provider.deleteHighlight(highlight.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surlignement supprimé')),
        );
      }
    }
  }

  void _navigateToHighlight(SermonHighlight highlight) {
    Navigator.pushNamed(
      context,
      '/search/sermon',
      arguments: {
        'sermonId': highlight.sermonId,
        'highlightId': highlight.id,
        'pageNumber': highlight.pageNumber,
      },
    );
  }
}
