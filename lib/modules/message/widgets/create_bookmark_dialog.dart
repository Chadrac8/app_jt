import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sermon_bookmark.dart';

/// Dialogue pour créer ou éditer un signet
class CreateBookmarkDialog extends StatefulWidget {
  final String sermonId;
  final int pageNumber;
  final int? position;
  final Uint8List? thumbnailBytes;
  final SermonBookmark? existingBookmark;

  const CreateBookmarkDialog({
    Key? key,
    required this.sermonId,
    required this.pageNumber,
    this.position,
    this.thumbnailBytes,
    this.existingBookmark,
  }) : super(key: key);

  @override
  State<CreateBookmarkDialog> createState() => _CreateBookmarkDialogState();
}

class _CreateBookmarkDialogState extends State<CreateBookmarkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingBookmark?.title ?? 'Page ${widget.pageNumber}',
    );
    _descriptionController = TextEditingController(
      text: widget.existingBookmark?.description,
    );
    if (widget.existingBookmark != null) {
      _tags.addAll(widget.existingBookmark!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.existingBookmark == null 
          ? 'Nouveau signet' 
          : 'Modifier le signet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aperçu miniature
            if (widget.thumbnailBytes != null)
              Center(
                child: Container(
                  width: 120,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      widget.thumbnailBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            // Info page
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${widget.pageNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.position != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(widget.position!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Titre
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
                hintText: 'Ex: Passage important',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ajoutez une note...',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Tags
            Text(
              'Tags',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                )),
                ActionChip(
                  label: const Icon(Icons.add, size: 18),
                  onPressed: _showAddTagDialog,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveBookmark,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _showAddTagDialog() async {
    _tagController.clear();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un tag'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            labelText: 'Tag',
            border: OutlineInputBorder(),
            hintText: 'Ex: Important',
          ),
          maxLength: 30,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty) {
                Navigator.pop(context, tag);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && !_tags.contains(result)) {
      setState(() {
        _tags.add(result);
      });
    }
  }

  void _saveBookmark() {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre est obligatoire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    
    // Encode miniature en base64
    String? thumbnailBase64;
    if (widget.thumbnailBytes != null) {
      try {
        thumbnailBase64 = base64Encode(widget.thumbnailBytes!);
      } catch (e) {
        debugPrint('Erreur encodage miniature: $e');
      }
    }

    final bookmark = SermonBookmark(
      id: widget.existingBookmark?.id ?? const Uuid().v4(),
      sermonId: widget.sermonId,
      title: title,
      description: description.isEmpty ? null : description,
      pageNumber: widget.pageNumber,
      position: widget.position,
      thumbnailBase64: thumbnailBase64 ?? widget.existingBookmark?.thumbnailBase64,
      tags: _tags,
      createdAt: widget.existingBookmark?.createdAt ?? DateTime.now(),
      updatedAt: widget.existingBookmark != null ? DateTime.now() : null,
    );

    Navigator.pop(context, bookmark);
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }
}

/// Affiche le dialogue de création de signet et retourne le résultat
Future<SermonBookmark?> showCreateBookmarkDialog({
  required BuildContext context,
  required String sermonId,
  required int pageNumber,
  int? position,
  Uint8List? thumbnailBytes,
  SermonBookmark? existingBookmark,
}) async {
  return await showDialog<SermonBookmark>(
    context: context,
    builder: (context) => CreateBookmarkDialog(
      sermonId: sermonId,
      pageNumber: pageNumber,
      position: position,
      thumbnailBytes: thumbnailBytes,
      existingBookmark: existingBookmark,
    ),
  );
}
