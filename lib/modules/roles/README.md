# Module Rôles et Permissions

Un système complet de gestion des rôles et permissions pour applications Flutter avec Firebase Firestore.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Utilisation](#utilisation)
5. [API Reference](#api-reference)
6. [Exemples](#exemples)
7. [Architecture](#architecture)

## Vue d'ensemble

Ce module fournit un système complet de contrôle d'accès basé sur les rôles (RBAC) pour votre application Flutter. Il permet de :

- ✅ Créer et gérer des rôles personnalisés
- ✅ Définir des permissions granulaires par module
- ✅ Assigner des rôles aux utilisateurs
- ✅ Vérifier les permissions en temps réel
- ✅ Interface utilisateur complète de gestion
- ✅ Export/Import de configuration
- ✅ Widgets de protection d'accès

### Fonctionnalités principales

- **Gestion des rôles** : Création, modification, suppression de rôles
- **Permissions granulaires** : 5 niveaux (Read, Write, Create, Delete, Admin)
- **15 modules prédéfinis** : Dashboard, Personnes, Cantiques, etc.
- **Interface intuitive** : Écrans de gestion avec recherche et filtres
- **Widgets de garde** : Protection automatique des composants
- **Temps réel** : Synchronisation Firebase en temps réel
- **Statistiques** : Tableaux de bord et rapports

## Installation

### 1. Ajout du module

Copiez le dossier `lib/modules/roles/` dans votre projet Flutter.

### 2. Dépendances requises

Ajoutez ces dépendances dans votre `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  intl: ^0.18.1
```

### 3. Installation des dépendances

```bash
flutter pub get
```

## Configuration

### 1. Configuration Firebase

Assurez-vous que Firebase est configuré dans votre projet :

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 2. Configuration du Provider

Ajoutez le `PermissionProvider` à votre arbre de widgets :

```dart
import 'package:provider/provider.dart';
import 'modules/roles/roles_module.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        // Autres providers...
      ],
      child: MaterialApp(
        // Configuration de l'app...
      ),
    );
  }
}
```

### 3. Initialisation du module

Initialisez le module au démarrage de l'application :

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeRolesModule();
  }

  Future<void> _initializeRolesModule() async {
    try {
      // Initialiser le module
      await RolesModule.initialize();
      
      // Initialiser le provider avec l'utilisateur courant
      final userId = getCurrentUserId(); // Votre méthode d'obtention de l'ID utilisateur
      Provider.of<PermissionProvider>(context, listen: false).initialize(userId);
    } catch (e) {
      print('Erreur initialisation module rôles: $e');
    }
  }
}
```

## Utilisation

### 1. Vérification de permissions

#### Méthode programmatique

```dart
// Vérifier une permission spécifique
bool canRead = await RolesModule.checkPermission(userId, 'dashboard_visualisation_read');

// Vérifier l'accès à un module
bool hasAccess = await RolesModule.checkModuleAccess(userId, 'personnes');

// Obtenir toutes les permissions d'un utilisateur
List<String> permissions = await RolesModule.getUserPermissions(userId);
```

#### Avec Provider

```dart
Consumer<PermissionProvider>(
  builder: (context, provider, child) {
    if (provider.hasPermission('dashboard_visualisation_read')) {
      return DashboardWidget();
    } else {
      return AccessDeniedWidget();
    }
  },
)
```

### 2. Widgets de protection

#### PermissionGuard

Protège un widget basé sur une permission spécifique :

```dart
PermissionGuard(
  permission: 'personnes_membres_write',
  userId: currentUserId,
  child: EditMemberButton(),
  fallback: Text('Accès refusé'),
)
```

#### ModuleGuard

Protège l'accès à un module entier :

```dart
ModuleGuard(
  moduleId: 'cantiques',
  userId: currentUserId,
  child: CantiquesScreen(),
  fallback: UnauthorizedScreen(),
)
```

### 3. Interface de gestion

Ouvrir l'écran de gestion des rôles :

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RolesManagementScreen(),
  ),
);
```

### 4. Création de rôles

```dart
final newRole = Role(
  id: '',
  name: 'Modérateur',
  description: 'Rôle de modération des contenus',
  color: Colors.blue,
  icon: Icons.shield,
  permissions: {
    'personnes_membres_read': PermissionLevel.read,
    'personnes_membres_write': PermissionLevel.write,
    'cantiques_bibliothèque_read': PermissionLevel.read,
  },
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await PermissionService().createRole(newRole);
```

### 5. Attribution de rôles

```dart
// Attribuer un rôle à un utilisateur
await PermissionService().assignRole(userId, roleId);

// Révoquer un rôle
await PermissionService().revokeRole(userId, roleId);

// Obtenir les rôles d'un utilisateur
List<UserRole> userRoles = await PermissionService().getUserRoles(userId);
```

## API Reference

### Classes principales

#### `RolesModule`

Classe utilitaire principale pour interagir avec le module :

```dart
class RolesModule {
  static String get moduleName => 'Rôles et Permissions';
  static String get moduleId => 'roles';
  static String get moduleVersion => '1.0.0';
  
  static Future<void> initialize()
  static Future<bool> checkPermission(String userId, String permission)
  static Future<bool> checkModuleAccess(String userId, String moduleId)
  static Future<List<String>> getUserPermissions(String userId)
}
```

#### `Permission`

Modèle représentant une permission :

```dart
class Permission {
  final String id;
  final String name;
  final String description;
  final String moduleId;
  final PermissionLevel level;
  
  // Constructeurs et méthodes...
}
```

#### `Role`

Modèle représentant un rôle :

```dart
class Role {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final Map<String, PermissionLevel> permissions;
  final bool isActive;
  
  // Constructeurs et méthodes...
}
```

#### `PermissionProvider`

Provider pour la gestion d'état :

```dart
class PermissionProvider extends ChangeNotifier {
  Future<void> initialize(String userId)
  bool hasPermission(String permission)
  bool hasModuleAccess(String moduleId)
  List<Role> get roles
  List<Permission> get permissions
  
  // Autres méthodes...
}
```

### Niveaux de permissions

```dart
enum PermissionLevel {
  read,    // Lecture seule
  write,   // Lecture + modification
  create,  // Lecture + modification + création
  delete,  // Lecture + modification + création + suppression
  admin,   // Accès administrateur complet
}
```

### Modules prédéfinis

Le système inclut 15 modules avec leurs permissions :

1. **Dashboard / Visualisation**
2. **Personnes / Membres**
3. **Cantiques / Bibliothèque**
4. **Médias / Fichiers**
5. **Pain Quotidien / Contenu**
6. **Événements / Planning**
7. **Prières / Mur**
8. **Notifications / Communication**
9. **Bénévolat / Activités**
10. **Dîmes / Finances**
11. **Formations / Éducation**
12. **Rapports / Statistiques**
13. **Communication / Messages**
14. **Configuration / Paramètres**
15. **Rôles / Sécurité**

## Exemples

### Exemple complet d'utilisation

Voir le fichier `examples/roles_module_example.dart` pour un exemple complet d'intégration.

### Création d'un rôle personnalisé

```dart
Future<void> createCustomRole() async {
  final role = Role(
    id: '',
    name: 'Responsable Médias',
    description: 'Gestion des contenus multimédias',
    color: Colors.purple,
    icon: Icons.perm_media,
    permissions: {
      'médias_fichiers_admin': PermissionLevel.admin,
      'cantiques_bibliothèque_write': PermissionLevel.write,
      'événements_planning_read': PermissionLevel.read,
    },
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  try {
    await PermissionService().createRole(role);
    print('Rôle créé avec succès');
  } catch (e) {
    print('Erreur création rôle: $e');
  }
}
```

### Protection d'une route

```dart
class ProtectedRoute extends StatelessWidget {
  final String requiredPermission;
  final Widget child;

  const ProtectedRoute({
    required this.requiredPermission,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, provider, _) {
        if (provider.hasPermission(requiredPermission)) {
          return child;
        } else {
          return Scaffold(
            appBar: AppBar(title: Text('Accès refusé')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Vous n\'avez pas les permissions nécessaires'),
                  Text('Permission requise: $requiredPermission'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
```

## Architecture

### Structure des fichiers

```
lib/modules/roles/
├── models/
│   └── permission_model.dart      # Modèles de données
├── services/
│   ├── permission_service.dart    # Logique métier et Firebase
│   └── permission_provider.dart   # Gestion d'état
├── views/
│   └── roles_management_screen.dart # Interface principale
├── widgets/
│   ├── role_card.dart            # Composant d'affichage de rôle
│   ├── create_role_dialog.dart   # Dialog de création de rôle
│   ├── role_details_dialog.dart  # Dialog de détails de rôle
│   └── permission_matrix_dialog.dart # Matrice des permissions
├── examples/
│   └── roles_module_example.dart # Exemple d'utilisation
└── roles_module.dart             # Point d'entrée principal
```

### Flux de données

1. **Initialisation** : `RolesModule.initialize()` configure les données par défaut
2. **Authentification** : L'utilisateur se connecte, on récupère son ID
3. **Chargement** : `PermissionProvider.initialize(userId)` charge les permissions
4. **Vérification** : Les widgets vérifient les permissions via le Provider
5. **Mise à jour** : Les changements sont synchronisés en temps réel via Firebase

### Sécurité

- **Validation côté serveur** : Toutes les opérations sont validées par Firebase Rules
- **Chiffrement** : Les données sensibles sont protégées par Firebase
- **Audit** : Toutes les modifications sont horodatées et tracées
- **Permissions granulaires** : Contrôle précis au niveau de chaque action

## Support et contribution

Pour des questions ou des améliorations, veuillez consulter la documentation Firebase et Flutter.

### Bonnes pratiques

1. **Toujours vérifier les permissions** avant d'afficher des composants sensibles
2. **Utiliser les widgets de garde** pour une protection automatique
3. **Tester les permissions** après chaque modification de rôle
4. **Documenter les rôles personnalisés** pour faciliter la maintenance
5. **Sauvegarder la configuration** avant les modifications importantes

---

**Version** : 1.0.0  
**Dernière mise à jour** : Janvier 2025  
**Compatibilité** : Flutter 3.0+, Firebase 10.0+
