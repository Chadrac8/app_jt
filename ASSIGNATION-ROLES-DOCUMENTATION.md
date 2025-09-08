# Module d'Assignation des Rôles - Documentation Complète

## Vue d'ensemble

Le module d'assignation des rôles fournit une interface complète pour gérer l'attribution des rôles aux utilisateurs dans l'application Jubilé Tabernacle. Il comprend :

- **Interface utilisateur intuitive** avec onglets pour différentes approches d'assignation
- **Recherche et filtrage** des utilisateurs et rôles
- **Assignation en temps réel** avec Firebase Firestore
- **Révocation de rôles** avec confirmation
- **Visualisation des permissions** par utilisateur

## Structure du Module

```
lib/modules/roles/
├── models/
│   └── permission_model.dart      # Modèles de données (Role, Permission, UserRole)
├── services/
│   ├── permission_provider.dart   # Provider pour la gestion d'état
│   └── permission_service.dart    # Services Firebase
├── views/
│   └── role_assignment_screen.dart # Écran principal d'assignation
├── widgets/
│   ├── user_role_assignment_widget.dart  # Widget d'assignation par utilisateur
│   └── role_module_menu_widget.dart      # Menu de navigation du module
└── roles_module.dart              # Point d'entrée et exports
```

## Fonctionnalités Principales

### 1. Assignation par Utilisateur

**Localisation**: `UserRoleAssignmentWidget`

**Fonctionnalités** :
- Liste tous les utilisateurs avec recherche et filtrage
- Affiche les rôles actuellement assignés à chaque utilisateur
- Permet d'ajouter de nouveaux rôles via un dialog
- Révocation de rôles avec confirmation
- Indicateurs visuels pour les utilisateurs actifs/inactifs

**Utilisation** :
```dart
// Dans votre widget
const UserRoleAssignmentWidget()
```

### 2. Interface de Recherche et Filtrage

**Fonctionnalités** :
- **Recherche textuelle** : Par nom d'utilisateur ou email
- **Filtrage par rôle** : Afficher seulement les utilisateurs avec un rôle spécifique
- **Filtrage par statut** : Inclure/exclure les utilisateurs inactifs
- **Effacement rapide** : Bouton pour réinitialiser la recherche

### 3. Assignation de Rôles

**Processus d'assignation** :
1. Sélectionner un utilisateur
2. Cliquer sur "Ajouter" dans la section des rôles
3. Choisir un rôle dans la liste déroulante
4. Confirmer l'assignation

**Validation** :
- Empêche la double assignation du même rôle
- Vérifie que le rôle est actif
- Affiche seulement les rôles non déjà assignés

### 4. Révocation de Rôles

**Processus de révocation** :
1. Cliquer sur l'icône de suppression du chip de rôle
2. Confirmer la révocation dans le dialog
3. Le rôle est immédiatement retiré

## Structure de Base de Données

### Collection `user_roles`

```firestore
user_roles/
├── {documentId}/
│   ├── userId: string        # ID de l'utilisateur
│   ├── roleId: string        # ID du rôle
│   ├── assignedAt: timestamp # Date d'assignation
│   ├── assignedBy: string    # ID de qui a assigné
│   └── isActive: boolean     # Statut de l'assignation
```

### Collection `people` (utilisateurs)

```firestore
people/
├── {userId}/
│   ├── firstName: string
│   ├── lastName: string
│   ├── email: string
│   ├── photoUrl: string (optionnel)
│   └── isActive: boolean
```

### Collection `roles`

```firestore
roles/
├── {roleId}/
│   ├── name: string
│   ├── description: string
│   ├── color: string         # Code couleur hex ou nom
│   ├── icon: string          # Nom de l'icône Material
│   ├── modulePermissions: map
│   ├── isActive: boolean
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
```

## Intégration dans l'Application

### 1. Provider Setup

Dans votre `main.dart` ou widget parent :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PermissionProvider()),
    // ... autres providers
  ],
  child: MyApp(),
)
```

### 2. Navigation vers le Module

```dart
// Navigation directe vers l'assignation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RoleAssignmentScreen(),
  ),
);

// Ou navigation vers le menu du module
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RoleModuleMenuWidget(),
  ),
);
```

### 3. Vérification des Permissions

```dart
// Vérifier si un utilisateur a une permission
Future<bool> checkPermission(String userId, String permissionId) async {
  return await RolesModule.checkPermission(userId, permissionId);
}

// Utilisation dans un widget
ExistingAppIntegration.buildPermissionBasedWidget(
  userId: currentUserId,
  permissionId: 'admin.role_management',
  child: AdminButton(),
  fallback: Text('Accès non autorisé'),
)
```

## Fonctionnalités Techniques

### 1. Parsing de Couleurs et Icônes

Le système convertit automatiquement les strings stockées en Firestore en objets Flutter :

```dart
// Couleurs supportées
Color _parseColor(String colorString) {
  // Supporte les codes hex (#FF0000) et noms (blue, red, green, etc.)
}

// Icônes supportées  
IconData _parseIcon(String iconString) {
  // Supporte les noms d'icônes Material (admin_panel_settings, person, etc.)
}
```

### 2. Streams en Temps Réel

Toutes les données sont synchronisées en temps réel grâce aux streams Firestore :

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('user_roles')
      .where('userId', isEqualTo: userId)
      .snapshots(),
  builder: (context, snapshot) {
    // Interface mise à jour automatiquement
  },
)
```

### 3. Gestion d'État avec Provider

Le `PermissionProvider` gère l'état global des rôles :

```dart
// Charger les rôles
context.read<PermissionProvider>().loadRoles();

// Écouter les changements
Consumer<PermissionProvider>(
  builder: (context, provider, child) {
    final roles = provider.roles;
    // Utiliser les rôles
  },
)
```

## Sécurité et Validation

### 1. Règles Firestore

Assurez-vous d'avoir des règles de sécurité appropriées :

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /user_roles/{document} {
      // Seuls les administrateurs peuvent modifier les assignations
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/user_roles/$(request.auth.uid)).data.roleId in ['admin', 'super_admin'];
    }
  }
}
```

### 2. Validation Côté Client

- Vérification que l'utilisateur connecté a les permissions d'assignation
- Validation que les rôles existent et sont actifs
- Prévention de la double assignation

## Personnalisation

### 1. Thème et Apparence

```dart
// Personnaliser les couleurs des cartes utilisateur
Card(
  child: Theme(
    data: Theme.of(context).copyWith(
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.blue[50],
      ),
    ),
    child: ExpansionTile(...),
  ),
)
```

### 2. Ajout de Filtres Personnalisés

Vous pouvez étendre le système de filtrage en modifiant `_buildSearchAndFilters()` :

```dart
// Ajouter un filtre par département
DropdownButtonFormField<String>(
  decoration: InputDecoration(labelText: 'Département'),
  items: departments.map((dept) => DropdownMenuItem(
    value: dept.id,
    child: Text(dept.name),
  )).toList(),
  onChanged: (value) => setState(() => _selectedDepartment = value),
)
```

## Dépannage

### Problèmes Courants

1. **Rôles non affichés** : Vérifiez que `PermissionProvider.loadRoles()` est appelé
2. **Erreurs de parsing** : Vérifiez le format des couleurs et icônes dans Firestore
3. **Permissions refusées** : Vérifiez les règles Firestore et l'authentification

### Logs de Debug

```dart
// Activer les logs dans le provider
class PermissionProvider extends ChangeNotifier {
  void loadRoles() async {
    print('Loading roles...');
    // ... logique de chargement
    print('Loaded ${roles.length} roles');
  }
}
```

## Roadmap et Améliorations Futures

### Phase 2 (À venir)
- **Assignation par rôle** : Interface pour voir tous les utilisateurs d'un rôle
- **Assignation en masse** : Sélectionner plusieurs utilisateurs
- **Historique des assignations** : Audit trail des changements
- **Import/Export** : Gestion en lot via fichiers
- **Notifications** : Alertes lors des changements de rôles

### Phase 3 (Long terme)
- **Rôles temporaires** : Assignation avec date d'expiration
- **Délégation de permissions** : Sous-administrateurs
- **Intégration LDAP/AD** : Synchronisation avec Active Directory
- **API REST** : Gestion programmatique des rôles

Ce module fournit une base solide pour la gestion des rôles et permissions, avec une architecture extensible pour les futurs besoins de l'application Jubilé Tabernacle.
