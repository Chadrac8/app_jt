import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../models/blog_category.dart';
import '../services/blog_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';
import '../../../../theme.dart';

/// Vue membre du module Blog
class BlogMemberView extends StatefulWidget {
  const BlogMemberView({Key? key}) : super(key: key);

  @override
  State<BlogMemberView> createState() => _BlogMemberViewState();
}

class _BlogMemberViewState extends State<BlogMemberView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlogService _blogService = BlogService();
  
  List<BlogPost> _recentPosts = [];
  List<BlogPost> _featuredPosts = [];
  List<BlogPost> _allPosts = [];
  List<BlogCategory> _categories = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _blogService.getRecentPosts(limit: 10),
        _blogService.getFeaturedPosts(limit: 5),
        _blogService.getPublishedPosts(),
        _blogService.getActiveCategories(),
      ]);

      if (mounted) {
        setState(() {
          _recentPosts = results[0] as List<BlogPost>;
          _featuredPosts = results[1] as List<BlogPost>;
          _allPosts = results[2] as List<BlogPost>;
          _categories = results[3] as List<BlogCategory>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: \$e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  List<BlogPost> get _filteredPosts {
    var posts = _allPosts;
    
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      posts = posts.where((post) => post.categories.contains(_selectedCategory)).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((post) => 
        post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Blog',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
      ],
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: AppTheme.grey500,
            tabs: const [
              Tab(text: 'Récents', icon: Icon(Icons.schedule)),
              Tab(text: 'À la une', icon: Icon(Icons.star)),
              Tab(text: 'Tous', icon: Icon(Icons.library_books)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList(_recentPosts),
                      _buildPostsList(_featuredPosts),
                      _buildPostsList(_filteredPosts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher des articles...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Filtre par catégorie
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Toutes'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) => _onCategoryChanged(null),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  ..._categories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name ?? 'Sans nom'),
                      selected: _selectedCategory == category.name,
                      onSelected: (selected) => _onCategoryChanged(
                        selected ? category.name : null,
                      ),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<BlogPost> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: AppTheme.grey500),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Aucun article trouvé', style: TextStyle(color: AppTheme.grey500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(BlogPost post) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToPost(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en vedette
            if (post.featuredImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  post.featuredImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppTheme.grey300,
                    child: Image.network(
                      "https://images.unsplash.com/photo-1579215176023-00341ea5ea67?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTk0Mzl8&ixlib=rb-4.1.0&q=80&w=1080",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.article, size: 64),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En vedette
                  if (post.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Text(
                        'À LA UNE',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize10,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.white100,
                        ),
                      ),
                    ),
                  
                  if (post.isFeatured) const SizedBox(height: AppTheme.spaceSmall),
                  
                  // Titre
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontBold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppTheme.spaceSmall),
                  
                  // Extrait
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      color: AppTheme.grey600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppTheme.space12),
                  
                  // Métadonnées
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: post.authorPhotoUrl != null 
                            ? NetworkImage(post.authorPhotoUrl!) 
                            : null,
                        child: post.authorPhotoUrl == null 
                            ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A')
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSize12,
                                fontWeight: AppTheme.fontMedium,
                              ),
                            ),
                            Text(
                              _formatDate(post.publishedAt ?? post.createdAt),
                              style: TextStyle(
                                fontSize: AppTheme.fontSize11,
                                color: AppTheme.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.visibility, size: 14, color: AppTheme.grey600),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        post.views.toString(),
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.grey600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Icon(Icons.schedule, size: 14, color: AppTheme.grey600),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        '\${post.estimatedReadingTime} min',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceSmall),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: post.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#\$tag',
                          style: TextStyle(
                            fontSize: AppTheme.fontSize10,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPost(BlogPost post) {
    // Incrémenter les vues
    _blogService.incrementViews(post.id!);
    
    Navigator.of(context).pushNamed(
      '/blog/detail',
      arguments: post,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche avancée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Mots-clés',
                hintText: 'Rechercher dans le titre et le contenu',
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Catégorie'),
              initialValue: _selectedCategory,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Toutes les catégories'),
                ),
                ..._categories.map((cat) => DropdownMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )),
              ],
              onChanged: _onCategoryChanged,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.relativeDate;
  }
}