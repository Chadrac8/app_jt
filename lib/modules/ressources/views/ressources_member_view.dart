import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/resource_item.dart';
import '../services/ressources_service.dart';
import '../../../models/app_config_model.dart';

class RessourcesMemberView extends StatefulWidget {
  final Function(String)? onNavigate;
  final ModuleConfig? moduleConfig;
  
  const RessourcesMemberView({
    Key? key, 
    this.onNavigate,
    this.moduleConfig,
  }) : super(key: key);

  @override
  State<RessourcesMemberView> createState() => _RessourcesMemberViewState();
}

class _RessourcesMemberViewState extends State<RessourcesMemberView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    RessourcesService.initializeDefaultResources();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Image de couverture si configurée
          if (widget.moduleConfig?.showCoverImage == true && 
              widget.moduleConfig?.coverImageUrl != null)
            Container(
              width: double.infinity,
              height: widget.moduleConfig?.coverImageHeight ?? 200.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.moduleConfig!.coverImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

          // Contenu principal
          Expanded(
            child: StreamBuilder<List<ResourceItem>>(
              stream: RessourcesService.getActiveResourcesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur lors du chargement',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final resources = snapshot.data ?? [];

                if (resources.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune ressource disponible',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: resources.length,
                      itemBuilder: (context, index) {
                        final resource = resources[index];
                        return _buildResourceCard(resource, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem resource, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onResourceTap(resource),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image de couverture ou icône
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: resource.coverImageUrl != null
                          ? null
                          : const Color(0xFF1565C0).withOpacity(0.1),
                    ),
                    child: resource.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              resource.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultIcon(resource.iconName);
                              },
                            ),
                          )
                        : _buildDefaultIcon(resource.iconName),
                  ),
                ),
                // Contenu textuel
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            resource.description,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(String iconName) {
    IconData icon;
    switch (iconName) {
      case 'menu_book':
        icon = Icons.menu_book;
        break;
      case 'campaign':
        icon = Icons.campaign;
        break;
      case 'library_music':
        icon = Icons.library_music;
        break;
      case 'church':
        icon = Icons.church;
        break;
      default:
        icon = Icons.library_books;
    }

    return Center(
      child: Icon(
        icon,
        size: 64,
        color: const Color(0xFF1565C0),
      ),
    );
  }

  void _onResourceTap(ResourceItem resource) {
    if (!resource.hasRedirect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette ressource n\'a pas de redirection configurée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (resource.isExternalRedirect) {
      // TODO: Ouvrir URL externe
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirection vers: ${resource.redirectUrl}'),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );
    } else if (resource.redirectRoute != null) {
      // Navigation vers une route interne
      String targetRoute = resource.redirectRoute!;
      
      // Convertir les routes /member/ en routes normales
      if (targetRoute.startsWith('/member/')) {
        targetRoute = targetRoute.substring('/member/'.length);
      }
      
      if (widget.onNavigate != null) {
        widget.onNavigate!(targetRoute);
      } else {
        // Fallback si pas de callback
        Navigator.pushNamed(context, resource.redirectRoute!);
      }
    }
  }
}
