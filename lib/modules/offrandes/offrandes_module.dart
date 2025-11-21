import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import '../../shared/widgets/custom_card.dart';
import 'views/offrandes_admin_view.dart';
import '../../../theme.dart';

/// Module de gestion des offrandes et dons
class OffrandesModule extends BaseModule {
  static const String moduleId = 'offrandes';

  OffrandesModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Offrandes',
          description: 'Gestion des offrandes, dîmes et dons de l\'église',
          icon: 'volunteer_activism',
          isEnabled: true,
          permissions: [ModulePermission.admin],
          adminRoute: '/admin/offrandes',
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/admin/offrandes': (context) => const OffrandesAdminView(),
    '/offrandes': (context) => const OffrandesAdminView(), // Alias pour compatibilité
  };

  @override
  Future<void> initialize() async {
    try {
      print('✅ Module Offrandes initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du module Offrandes: $e');
      rethrow;
    }
  }

  /// Construit une carte pour l'affichage du module dans le dashboard admin
  Widget buildModuleCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getQuickStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
        return CustomCard(
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/admin/offrandes'),
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
                          color: AppTheme.greenStandard.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          Icons.volunteer_activism,
                          color: AppTheme.greenStandard,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.name,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSize16,
                                fontWeight: AppTheme.fontBold,
                              ),
                            ),
                            Text(
                              config.description,
                              style: TextStyle(
                                fontSize: AppTheme.fontSize12,
                                color: AppTheme.grey600,
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
                  Row(
                    children: [
                      _buildQuickStat(
                        'Total mois',
                        stats['monthlyTotal']?.toString() ?? '€ 0',
                        AppTheme.greenStandard,
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      _buildQuickStat(
                        'Dons',
                        stats['donationsCount']?.toString() ?? '0',
                        AppTheme.blueStandard,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontBold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getQuickStats() async {
    try {
      // Get real statistics from Firestore
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();
      
      double total = 0;
      int count = snapshot.docs.length;
      
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'] as num? ?? 0;
        total += amount.toDouble();
      }
      
      final average = count > 0 ? total / count : 0;
      
      return {
        'monthlyTotal': '€ ${total.toStringAsFixed(2)}',
        'donationsCount': count,
        'averageDonation': '€ ${average.toStringAsFixed(2)}',
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'monthlyTotal': '€ 0',
        'donationsCount': 0,
        'averageDonation': '€ 0',
        'error': e.toString(),
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  List<Widget> getAdminMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: Icon(
          Icons.volunteer_activism,
          color: AppTheme.greenStandard,
        ),
        title: Text(config.name),
        subtitle: Text(config.description),
        onTap: () => Navigator.of(context).pushNamed('/admin/offrandes'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    ];
  }

  @override
  List<Widget> getMemberMenuItems(BuildContext context) {
    // Pas d'accès membre pour ce module
    return [];
  }
}