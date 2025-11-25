import 'package:flutter/material.dart';
import '../models/search_result.dart';

/// Card pour afficher un résultat de recherche
class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.sermonTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (result.pageNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'p.${result.pageNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                result.sermonDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildHighlightedText(context),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pertinence: ${(result.relevanceScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context) {
    final text = result.fullContext;
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 13),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Recherche insensible à la casse
    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final matches = <TextSpan>[];
    
    int lastIndex = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1 && matches.length < 10) {
      // Ajouter le texte avant le match
      if (index > lastIndex) {
        matches.add(TextSpan(
          text: text.substring(lastIndex, index),
        ));
      }
      
      // Ajouter le texte surligné
      matches.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: TextStyle(
          backgroundColor: Colors.yellow[200],
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = index + searchQuery.length;
      index = lowerText.indexOf(lowerQuery, lastIndex);
    }
    
    // Ajouter le reste du texte
    if (lastIndex < text.length) {
      matches.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
        children: matches,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
