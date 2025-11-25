import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon_bookmark.dart';
import '../providers/bookmarks_provider.dart';

/// Widget affichant une carte de signet avec miniature
class BookmarkCard extends StatelessWidget {
  final SermonBookmark bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
    this.onTap,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailBytes = _getThumbnailBytes();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature
            _buildThumbnail(thumbnailBytes, theme),
            
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      bookmark.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    if (bookmark.description != null && bookmark.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          bookmark.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Page et date
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bookmark.formattedPage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (bookmark.position != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bookmark.formattedPosition,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatDate(bookmark.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    
                    // Tags
                    if (bookmark.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: bookmark.tags.map((tag) {
                            return Chip(
                              label: Text(
                                tag,
                                style: theme.textTheme.bodySmall,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(Uint8List? bytes, ThemeData theme) {
    const double width = 80;
    const double height = 100;

    if (bytes != null && bytes.isNotEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(theme);
          },
        ),
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 80,
      height: 100,
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.image_not_supported,
        color: theme.colorScheme.onPrimaryContainer,
        size: 32,
      ),
    );
  }

  Uint8List? _getThumbnailBytes() {
    if (bookmark.thumbnailBase64 == null || bookmark.thumbnailBase64!.isEmpty) {
      return null;
    }
    
    try {
      return base64Decode(bookmark.thumbnailBase64!);
    } catch (e) {
      debugPrint('Erreur décodage miniature: $e');
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "Aujourd'hui";
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Bouton flottant pour créer un signet
class CreateBookmarkButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool mini;

  const CreateBookmarkButton({
    Key? key,
    required this.onPressed,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      mini: mini,
      tooltip: 'Ajouter un signet',
      child: const Icon(Icons.bookmark_add),
    );
  }
}

/// Liste de signets pour un sermon
class SermonBookmarksList extends StatelessWidget {
  final String sermonId;
  final Function(SermonBookmark) onBookmarkTap;

  const SermonBookmarksList({
    Key? key,
    required this.sermonId,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarksProvider>(
      builder: (context, bookmarksProvider, child) {
        final bookmarks = bookmarksProvider.getBookmarksForSermon(sermonId);

        if (bookmarksProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmarks_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun signet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des signets pour retrouver\nfacilement des passages importants',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return BookmarkCard(
              bookmark: bookmark,
              onTap: () => onBookmarkTap(bookmark),
              onEdit: () => _showEditDialog(context, bookmark),
              onDelete: () => _confirmDelete(context, bookmark),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, SermonBookmark bookmark) async {
    final titleController = TextEditingController(text: bookmark.title);
    final descController = TextEditingController(text: bookmark.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le signet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final provider = Provider.of<BookmarksProvider>(context, listen: false);
      final updated = bookmark.copyWith(
        title: titleController.text,
        description: descController.text.isEmpty ? null : descController.text,
        updatedAt: DateTime.now(),
      );
      await provider.updateBookmark(updated);
    }

    titleController.dispose();
    descController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, SermonBookmark bookmark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le signet'),
        content: Text('Voulez-vous vraiment supprimer "${bookmark.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final provider = Provider.of<BookmarksProvider>(context, listen: false);
      await provider.deleteBookmark(bookmark.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signet supprimé')),
        );
      }
    }
  }
}
