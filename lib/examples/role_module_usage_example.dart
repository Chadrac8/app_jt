import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/roles/roles_module.dart';

/// Exemple d'utilisation du module de rôles et permissions
class RoleModuleExample extends StatelessWidget {
  const RoleModuleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: MaterialApp(
        title: 'Rôles et Permissions Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const RoleModuleMenuWidget(),
      ),
    );
  }
}

/// Exemple d'utilisation directe de l'écran d'assignation
class DirectAssignmentExample extends StatelessWidget {
  const DirectAssignmentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionProvider(),
      child: const RoleAssignmentScreen(),
    );
  }
}

/// Exemple d'intégration dans une application existante
class ExistingAppIntegration {
  /// Ajouter cette méthode dans votre main() pour initialiser le module
  static Future<void> initializeRoleModule() async {
    await RolesModule.initialize();
  }
  
  /// Méthode pour vérifier les permissions dans vos widgets
  static Future<bool> checkUserPermission(String userId, String permissionId) async {
    return await RolesModule.checkPermission(userId, permissionId);
  }
  
  /// Méthode pour vérifier l'accès aux modules
  static Future<bool> checkModuleAccess(String userId, String moduleId) async {
    return await RolesModule.checkModuleAccess(userId, moduleId);
  }
  
  /// Widget conditionnel basé sur les permissions
  static Widget buildPermissionBasedWidget({
    required String userId,
    required String permissionId,
    required Widget child,
    Widget? fallback,
  }) {
    return FutureBuilder<bool>(
      future: checkUserPermission(userId, permissionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Exemple d'usage dans un drawer ou menu principal
class MainMenuWithRoles extends StatelessWidget {
  final String currentUserId;
  
  const MainMenuWithRoles({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu Principal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          
          // Menu standard
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          
          // Menu conditionnel basé sur les permissions
          ExistingAppIntegration.buildPermissionBasedWidget(
            userId: currentUserId,
            permissionId: 'admin.role_management',
            child: ExpansionTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administration'),
              children: [
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Gestion des utilisateurs'),
                  onTap: () {
                    Navigator.pop(context);
                    // Naviguer vers la gestion des utilisateurs
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Rôles et Permissions'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => PermissionProvider(),
                          child: const RoleModuleMenuWidget(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            fallback: const SizedBox.shrink(),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
