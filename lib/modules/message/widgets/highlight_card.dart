import 'package:flutter/material.dart';
import '../models/sermon_highlight.dart';
import 'package:intl/intl.dart';

/// Card pour afficher un surlignement
class HighlightCard extends StatelessWidget {
  final SermonHighlight highlight;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const HighlightCard({
    super.key,
    required this.highlight,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight.color != null
        ? Color(int.parse(highlight.color!.replaceFirst('#', '0xff')))
        : Colors.yellow[200]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          highlight.text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                if (highlight.pageNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.bookmark, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Page ${highlight.pageNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Créé ${_formatDate(highlight.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'aujourd\'hui';
    } else if (diff.inDays == 1) {
      return 'hier';
    } else if (diff.inDays < 7) {
      return 'il y a ${diff.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
