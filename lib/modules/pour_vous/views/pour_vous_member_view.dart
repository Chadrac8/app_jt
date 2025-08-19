import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme.dart';
import '../../../shared/utils/navigation_service.dart';
import '../../../models/app_config_model.dart';
import '../../../services/app_config_firebase_service.dart';
import '../models/action_item.dart';
import '../services/pour_vous_service.dart';

class PourVousMemberView extends StatefulWidget {
  const PourVousMemberView({super.key});

  @override
  State<PourVousMemberView> createState() => _PourVousMemberViewState();
}

class _PourVousMemberViewState extends State<PourVousMemberView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

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
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: StreamBuilder<AppConfigModel>(
                stream: AppConfigFirebaseService.getAppConfigStream(),
                builder: (configContext, configSnapshot) {
                  final moduleConfig = configSnapshot.hasData
                      ? configSnapshot.data!.modules.firstWhere(
                          (module) => module.id == 'pour_vous',
                          orElse: () => ModuleConfig(
                            id: 'pour_vous',
                            name: 'Pour vous',
                            description: 'Module Pour vous',
                            iconName: 'favorite',
                            route: '/pour-vous',
                            category: 'core',
                            isEnabledForMembers: true,
                            isPrimaryInBottomNav: true,
                            order: 1,
                            isBuiltIn: true,
                            coverImageUrl: null,
                            showCoverImage: false,
                            coverImageHeight: 200.0,
                          ),
                        )
                      : null;

                  return StreamBuilder<List<ActionItem>>(
                    stream: PourVousService.getActiveActionsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur de chargement',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final actions = snapshot.data ?? [];

                      if (actions.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildContent(actions, moduleConfig);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune action disponible',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les actions seront bientôt disponibles.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ActionItem> actions, ModuleConfig? moduleConfig) {
    return CustomScrollView(
      slivers: [
        // Image de couverture si activée
        if (moduleConfig?.showCoverImage == true && 
            moduleConfig?.coverImageUrl != null && 
            moduleConfig!.coverImageUrl!.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              height: moduleConfig.coverImageHeight,
              child: CachedNetworkImage(
                imageUrl: moduleConfig.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.error)),
                ),
              ),
            ),
          ),
        _buildActionsGrid(actions),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildActionsGrid(List<ActionItem> actions) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final action = actions[index];
            return _buildActionCard(action, index);
          },
          childCount: actions.length,
        ),
      ),
    );
  }

  Widget _buildActionCard(ActionItem action, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _handleActionTap(action),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image de couverture ou icône
                    if (action.coverImageUrl != null && action.coverImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: action.coverImageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 100,
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => _buildIconHeader(action),
                        ),
                      )
                    else
                      _buildIconHeader(action),

                    // Contenu
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                action.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
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
      },
    );
  }

  Widget _buildIconHeader(ActionItem action) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getIconData(action.iconName),
          size: 40,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'prayer':
        return Icons.favorite_outline;
      case 'water_drop':
        return Icons.water_drop;
      case 'groups':
        return Icons.groups;
      case 'schedule':
        return Icons.schedule;
      case 'help':
        return Icons.help_outline;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'question_answer':
        return Icons.question_answer;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      default:
        return Icons.help_outline;
    }
  }

  void _handleActionTap(ActionItem action) {
    try {
      if (action.redirectRoute != null && action.redirectRoute!.isNotEmpty) {
        // Navigation vers une route interne
        NavigationService.navigateTo(action.redirectRoute!);
      } else if (action.redirectUrl != null && action.redirectUrl!.isNotEmpty) {
        // Ouvrir URL externe
        _showUrlDialog(action.redirectUrl!);
      } else {
        // Action par défaut - afficher les détails
        _showActionDetails(action);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de l\'action'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ouvrir le lien'),
        content: Text('Voulez-vous ouvrir ce lien ?\n\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'ouverture d'URL
            },
            child: Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  void _showActionDetails(ActionItem action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIconData(action.iconName),
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            action.title,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      action.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
