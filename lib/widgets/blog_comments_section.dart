import 'package:flutter/material.dart';
import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';

class BlogCommentsSection extends StatefulWidget {
  final String postId;

  const BlogCommentsSection({
    super.key,
    required this.postId,
  });

  @override
  State<BlogCommentsSection> createState() => _BlogCommentsSectionState();
}

class _BlogCommentsSectionState extends State<BlogCommentsSection> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  BlogComment? _replyingTo;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formulaire d'ajout de commentaire
        _buildCommentForm(),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Liste des commentaires
        StreamBuilder<List<BlogComment>>(
          stream: BlogFirebaseService.getCommentsStream(widget.postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXLarge),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: AppTheme.grey50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.grey600),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text(
                        'Erreur lors du chargement des commentaires',
                        style: TextStyle(color: AppTheme.grey700),
                      ),
                    ),
                  ],
                ),
              );
            }

            final comments = snapshot.data ?? [];
            final topLevelComments = comments
                .where((comment) => comment.parentCommentId == null)
                .toList();

            if (topLevelComments.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: topLevelComments.map((comment) {
                final replies = comments
                    .where((c) => c.parentCommentId == comment.id)
                    .toList();
                
                return _buildCommentThread(comment, replies);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.grey200!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur de réponse
          if (_replyingTo != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      'Réponse à ${_replyingTo!.authorName}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: AppTheme.fontMedium,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _replyingTo = null),
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space12),
          ],
          
          // Champ de commentaire
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Ajouter un commentaire...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppTheme.space12),
            ),
            maxLines: 3,
            minLines: 2,
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_replyingTo != null)
                TextButton(
                  onPressed: () => setState(() => _replyingTo = null),
                  child: const Text('Annuler'),
                ),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_replyingTo != null ? 'Répondre' : 'Commenter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXLarge),
      child: Column(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucun commentaire',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Soyez le premier à commenter cet article!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentThread(BlogComment comment, List<BlogComment> replies) {
    return Column(
      children: [
        _buildCommentCard(comment, isReply: false),
        
        // Réponses
        if (replies.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceSmall),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: replies.map((reply) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCommentCard(reply, isReply: true),
              )).toList(),
            ),
          ),
        ],
        
        const SizedBox(height: AppTheme.spaceMedium),
      ],
    );
  }

  Widget _buildCommentCard(BlogComment comment, {required bool isReply}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: isReply ? AppTheme.grey50 : AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isReply ? AppTheme.grey200! : AppTheme.grey300!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du commentaire
          Row(
            children: [
              // Photo de profil
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.authorPhotoUrl != null
                    ? NetworkImage(comment.authorPhotoUrl!)
                    : null,
                child: comment.authorPhotoUrl == null
                    ? Icon(Icons.person, size: 16, color: AppTheme.grey600)
                    : null,
              ),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Nom et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                        if (comment.isAuthorReply) ...[
                          const SizedBox(width: AppTheme.spaceSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'AUTEUR',
                              style: TextStyle(
                                color: AppTheme.white100,
                                fontSize: AppTheme.fontSize10,
                                fontWeight: AppTheme.fontBold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatCommentDate(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menu actions
              PopupMenuButton<String>(
                onSelected: (action) => _handleCommentAction(action, comment),
                itemBuilder: (context) => [
                  if (!isReply)
                    const PopupMenuItem(
                      value: 'reply',
                      child: ListTile(
                        leading: Icon(Icons.reply),
                        title: Text('Répondre'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Signaler'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: AppTheme.grey600,
                  size: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Contenu du commentaire
          Text(
            comment.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Actions du commentaire
          Row(
            children: [
              // Like
              TextButton.icon(
                onPressed: () => _likeComment(comment),
                icon: Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: AppTheme.grey600,
                ),
                label: Text(
                  comment.likes > 0 ? comment.likes.toString() : 'J\'aime',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.grey600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              
              if (!isReply) ...[
                const SizedBox(width: AppTheme.spaceSmall),
                
                // Répondre
                TextButton.icon(
                  onPressed: () => _replyToComment(comment),
                  icon: Icon(
                    Icons.reply,
                    size: 16,
                    color: AppTheme.grey600,
                  ),
                  label: Text(
                    'Répondre',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.grey600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour commenter');
      }

      final comment = BlogComment(
        id: '',
        postId: widget.postId,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Utilisateur',
        authorPhotoUrl: currentUser.photoURL,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: _replyingTo?.id,
        isAuthorReply: false, // TODO: Vérifier si l'utilisateur est l'auteur de l'article
      );

      await BlogFirebaseService.addComment(comment);
      
      _commentController.clear();
      setState(() => _replyingTo = null);
      
      // Faire défiler vers le bas pour voir le nouveau commentaire
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire ajouté')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _replyToComment(BlogComment comment) {
    setState(() => _replyingTo = comment);
    
    // Faire défiler vers le formulaire
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleCommentAction(String action, BlogComment comment) {
    switch (action) {
      case 'reply':
        _replyToComment(comment);
        break;
      case 'report':
        _reportComment(comment);
        break;
    }
  }

  Future<void> _likeComment(BlogComment comment) async {
    // TODO: Implémenter le système de likes pour les commentaires
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à venir')),
    );
  }

  void _reportComment(BlogComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler ce commentaire'),
        content: const Text(
          'Voulez-vous signaler ce commentaire comme inapproprié ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Commentaire signalé')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.redStandard),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}