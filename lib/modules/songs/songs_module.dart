import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import '../../shared/widgets/custom_card.dart';
import 'views/member_songs_page.dart';
import 'views/songs_home_page.dart';
import 'services/songs_firebase_service.dart';
import '../../../theme.dart';

/// Module de gestion des chants
class SongsModule extends BaseModule {
  static const String moduleId = 'songs';

  SongsModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Cantiques',
          description: 'Gestion complète du recueil de chants avec recherche avancée, catégories, favoris et playlists',
          icon: 'library_music',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member],
          memberRoute: '/member/songs',
          adminRoute: '/admin/songs',
          customConfig: {
            'features': [
              'Recherche avancée',
              'Catégories et tags',
              'Favoris personnels',
              'Playlists',
              'Partitions et médias',
              'Statistiques d\'usage',
              'Système d\'approbation',
              'Interface responsive',
            ],
            'permissions': {
              'member': ['view', 'search', 'favorite', 'playlist'],
              'admin': ['create', 'edit', 'delete', 'approve', 'manage_categories'],
            },
          },
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/songs': (context) => const MemberSongsPage(),
    '/admin/songs': (context) => const SongsHomePage(),

  };

  @override
  Future<void> initialize() async {
    await super.initialize();
    print('✅ Module Songs initialisé avec succès');
    print('   - Modèles: SongModel, Setlist');
    print('   - Services: SongsFirebaseService');
    print('   - Vues: 4 vues complètes (Member, Admin, Detail, Form)');
    print('   - Fonctionnalités: Recherche, Catégories, Favoris, Statistiques');
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    print('Module Songs libéré');
  }

  Widget buildModuleCard(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/member/songs'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize18,
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Text(
                          config.description,
                          style: TextStyle(
                            color: AppTheme.grey600,
                            fontSize: AppTheme.fontSize14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Fonctionnalités principales
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildFeatureChip('Recherche avancée', Icons.search),
                  _buildFeatureChip('Catégories', Icons.category),
                  _buildFeatureChip('Favoris', Icons.favorite),
                  _buildFeatureChip('Playlists', Icons.playlist_play),
                ],
              ),
              
              const SizedBox(height: AppTheme.space12),
              
              // Statistiques (sera mis à jour dynamiquement)
              RepaintBoundary(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: SongsFirebaseService.getSongsStatistics(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data!;
                      return Row(
                      children: [
                        _buildStatChip('${stats['totalSongs'] ?? 0} chants', Icons.library_music),
                        const SizedBox(width: AppTheme.spaceSmall),
                        _buildStatChip('${stats['totalSetlists'] ?? 0} setlists', Icons.queue_music),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      _buildStatChip('Chargement...', Icons.hourglass_empty),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSize10,
              color: AppTheme.primaryColor,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.grey200,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.grey600),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.grey600,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir les statistiques du module
  Future<Map<String, dynamic>> getModuleStatistics() async {
    try {
      final stats = await SongsFirebaseService.getSongsStatistics();
      
      return {
        'total_songs': stats['totalSongs'] ?? 0,
        'total_setlists': stats['totalSetlists'] ?? 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Vérifier l'intégrité du module
  Future<bool> verifyModuleIntegrity() async {
    try {
      // Vérifier que le service fonctionne
      final stats = await SongsFirebaseService.getSongsStatistics();
      
      print('✅ Module Songs: Intégrité vérifiée - ${stats['totalSongs']} chants disponibles');
      return true;
    } catch (e) {
      print('❌ Module Songs: Erreur d\'intégrité - $e');
      return false;
    }
  }
}