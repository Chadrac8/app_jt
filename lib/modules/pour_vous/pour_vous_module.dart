import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import 'views/pour_vous_member_view.dart';
import 'views/pour_vous_admin_view.dart';
import 'services/pour_vous_service.dart';

/// Module "Pour vous" - Actions personnalisées pour les membres
class PourVousModule extends BaseModule {
  static const String moduleId = 'pour_vous';
  
  PourVousModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Pour vous',
          description: 'Actions personnalisées et demandes des membres',
          icon: 'favorite',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member],
          memberRoute: '/member/pour-vous',
          adminRoute: '/admin/pour-vous',
          customConfig: {
            'features': [
              'Actions personnalisables',
              'Demandes de prière',
              'Demandes de baptême',
              'Rejoindre un groupe',
              'Prise de rendez-vous',
              'Questions au pasteur',
              'Propositions d\'idées',
              'Gestion des demandes',
              'Images de couverture',
              'Redirections configurables',
            ],
            'permissions': {
              'member': ['view_actions', 'submit_requests'],
              'admin': ['manage_actions', 'view_all_requests', 'handle_requests'],
            },
          },
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/pour-vous': (context) => const PourVousMemberView(),
    '/admin/pour-vous': (context) => const PourVousAdminView(),
  };

  @override
  Future<void> initialize() async {
    try {
      // Initialiser les actions par défaut si nécessaire
      await PourVousService.initializeDefaultActions();
      
      print('✅ Module Pour Vous initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du module Pour Vous: $e');
      rethrow;
    }
  }

  @override
  List<Widget> getMemberMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.favorite, color: Color(0xFF6F61EF)),
        title: const Text('Pour vous'),
        subtitle: const Text('Actions personnalisées'),
        onTap: () => Navigator.of(context).pushNamed('/member/pour-vous'),
      ),
    ];
  }

  @override
  List<Widget> getAdminMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.favorite, color: Color(0xFF6F61EF)),
        title: const Text('Pour vous'),
        subtitle: const Text('Gérer les actions et demandes'),
        onTap: () => Navigator.of(context).pushNamed('/admin/pour-vous'),
        trailing: FutureBuilder<Map<String, int>>(
          future: PourVousService.getRequestsStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            final pending = stats['pending'] ?? 0;
            
            if (pending > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    // Nettoyage si nécessaire
    print('Module Pour Vous nettoyé');
  }
}
