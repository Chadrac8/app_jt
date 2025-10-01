/**
 * GUIDE D'UTILISATION - SYSTÈME DE PERMISSIONS ADMIN
 * 
 * Ce guide explique comment utiliser le nouveau système de contrôle d'accès
 * pour le bouton administrateur et autres fonctionnalités admin.
 */

// ============================================================================
// 1. CONFIGURATION DES PERMISSIONS ADMIN
// ============================================================================

/**
 * Les permissions administrateur sont définies dans :
 * lib/modules/roles/config/admin_permissions_config.dart
 * 
 * Vous pouvez modifier cette configuration pour ajouter/supprimer des permissions
 * qui donnent accès à la vue admin.
 */

// Permissions Super Admin (accès complet)
const SUPER_ADMIN_PERMISSIONS = [
  'system_admin',
  'super_admin', 
  'full_admin_access'
];

// Permissions Admin spécifiques
const ADMIN_PERMISSIONS = [
  'admin_panel_access',
  'manage_roles',
  'manage_users',
  'manage_permissions',
  // ... autres permissions
];

// ============================================================================
// 2. UTILISATION DU BOUTON ADMIN
// ============================================================================

/**
 * Le bouton AdminViewToggleButton s'affiche automatiquement uniquement
 * pour les utilisateurs ayant les bonnes permissions.
 * 
 * Usage dans votre code :
 */

// Dans votre AppBar actions:
actions: [
  const AdminViewToggleButton(
    iconColor: Colors.white,
    backgroundColor: Colors.transparent,
  ),
  // autres boutons...
],

// ============================================================================
// 3. VÉRIFICATION MANUELLE DES PERMISSIONS
// ============================================================================

/**
 * Pour vérifier manuellement si un utilisateur a accès admin :
 */

// Dans un Widget avec accès au PermissionProvider :
Consumer<PermissionProvider>(
  builder: (context, permissionProvider, child) {
    return FutureBuilder<bool>(
      future: permissionProvider.hasAdminRole(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Text('Utilisateur Admin ✅');
        }
        return Text('Utilisateur Normal');
      },
    );
  },
);

// ============================================================================
// 4. VÉRIFICATION DE PERMISSIONS SPÉCIFIQUES
// ============================================================================

/**
 * Pour vérifier des permissions admin spécifiques :
 */

// Vérifier une permission particulière
final canManageUsers = await permissionProvider.hasPermission('manage_users');

// Vérifier l'accès à une fonctionnalité admin spécifique
final canAccessUserManagement = await permissionProvider.canAccessAdminFeature('user_management');

// ============================================================================
// 5. AJOUT DE NOUVELLES PERMISSIONS ADMIN
// ============================================================================

/**
 * Pour ajouter une nouvelle permission qui donne accès admin :
 * 
 * 1. Modifiez AdminPermissionsConfig.adminPermissions
 * 2. Ajoutez la permission à votre base de données Firebase
 * 3. Assignez la permission aux rôles appropriés
 */

// Exemple d'ajout dans admin_permissions_config.dart :
static const List<String> adminPermissions = [
  'admin_panel_access',
  'manage_roles', 
  'manage_users',
  'nouvelle_permission_admin', // <- Nouvelle permission
];

// ============================================================================
// 6. DEBUG ET TESTS
// ============================================================================

/**
 * Pour débugger les permissions, utilisez le widget de debug :
 */

// En mode développement uniquement :
if (kDebugMode) {
  AdminPermissionsDebugWidget(),
}

// ============================================================================
// 7. SÉCURITÉ IMPORTANTES
// ============================================================================

/**
 * IMPORTANT : Ce système contrôle uniquement l'affichage du bouton.
 * 
 * Pour une sécurité complète, vous DEVEZ aussi :
 * - Vérifier les permissions côté serveur/Firebase
 * - Valider les permissions dans vos routes admin
 * - Implémenter des règles de sécurité Firestore appropriées
 */

// Exemple de protection d'une route admin :
class AdminRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, child) {
        return FutureBuilder<bool>(
          future: permissionProvider.hasAdminRole(),
          builder: (context, snapshot) {
            if (snapshot.data != true) {
              return AccessDeniedPage(); // Page d'accès refusé
            }
            return AdminDashboard(); // Page admin
          },
        );
      },
    );
  }
}

// ============================================================================
// 8. TESTS UNITAIRES
// ============================================================================

/**
 * Exemple de test pour les permissions admin :
 */

/*
testWidgets('AdminViewToggleButton should not show for regular users', (tester) async {
  // Setup mock provider sans permissions admin
  final mockProvider = MockPermissionProvider();
  when(mockProvider.hasAdminRole()).thenAnswer((_) async => false);
  
  await tester.pumpWidget(
    ChangeNotifierProvider<PermissionProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [AdminViewToggleButton()],
          ),
        ),
      ),
    ),
  );
  
  // Vérifier que le bouton n'est pas affiché
  expect(find.byType(AdminViewToggleButton), findsNothing);
});
*/