import 'package:flutter/material.dart';
import '../models/blog_model.dart';
import '../../theme.dart';

class BlogPostMetadata extends StatelessWidget {
  final BlogPost post;

  const BlogPostMetadata({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Photo auteur
        CircleAvatar(
          radius: 20,
          backgroundImage: post.authorPhotoUrl != null
              ? NetworkImage(post.authorPhotoUrl!)
              : null,
          child: post.authorPhotoUrl == null
              ? Icon(Icons.person, color: AppTheme.grey600)
              : null,
        ),
        
        const SizedBox(width: AppTheme.space12),
        
        // Informations auteur et article
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _formatDate(post.publishedAt ?? post.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    '•',
                    style: TextStyle(color: AppTheme.grey600),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    '${post.readingTimeMinutes} min de lecture',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Badge featured
        if (post.isFeatured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.warningColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: AppTheme.warning),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  'EN VEDETTE',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: AppTheme.fontSize10,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}