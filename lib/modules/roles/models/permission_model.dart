import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une permission dans le système
class Permission {
  final String id;
  final String name;
  final String description;
  final String module;
  final String category;
  final PermissionLevel level;
  final List<String> dependencies;
  final bool isSystemPermission;
  final DateTime createdAt;
  final DateTime updatedAt;

  Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.module,
    required this.category,
    required this.level,
    this.dependencies = const [],
    this.isSystemPermission = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Permission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Permission(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      module: data['module'] ?? '',
      category: data['category'] ?? '',
      level: PermissionLevel.values.firstWhere(
        (level) => level.name == data['level'],
        orElse: () => PermissionLevel.read,
      ),
      dependencies: List<String>.from(data['dependencies'] ?? []),
      isSystemPermission: data['isSystemPermission'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'module': module,
      'category': category,
      'level': level.name,
      'dependencies': dependencies,
      'isSystemPermission': isSystemPermission,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Permission copyWith({
    String? id,
    String? name,
    String? description,
    String? module,
    String? category,
    PermissionLevel? level,
    List<String>? dependencies,
    bool? isSystemPermission,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Permission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      module: module ?? this.module,
      category: category ?? this.category,
      level: level ?? this.level,
      dependencies: dependencies ?? this.dependencies,
      isSystemPermission: isSystemPermission ?? this.isSystemPermission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Permission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Niveaux de permissions disponibles
enum PermissionLevel {
  read('Lecture', 'Peut consulter les données'),
  write('Écriture', 'Peut modifier les données'),
  create('Création', 'Peut créer de nouvelles données'),
  delete('Suppression', 'Peut supprimer les données'),
  admin('Administration', 'Accès administrateur complet');

  const PermissionLevel(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Modules de l'application avec leurs permissions
class AppModule {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> categories;
  final bool isActive;

  const AppModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.categories,
    this.isActive = true,
  });

  static const List<AppModule> allModules = [
    AppModule(
      id: 'dashboard',
      name: 'Tableau de bord',
      description: 'Vue d\'ensemble et statistiques',
      icon: 'dashboard',
      categories: ['Visualisation', 'Statistiques', 'Rapports'],
    ),
    AppModule(
      id: 'personnes',
      name: 'Gestion des personnes',
      description: 'Gestion des membres et contacts',
      icon: 'people',
      categories: ['Membres', 'Contacts', 'Familles', 'Profils'],
    ),
    AppModule(
      id: 'groupes',
      name: 'Gestion des groupes',
      description: 'Gestion des groupes et communautés',
      icon: 'group',
      categories: ['Groupes', 'Membres', 'Réunions', 'Événements'],
    ),
    AppModule(
      id: 'evenements',
      name: 'Gestion des événements',
      description: 'Planification et gestion d\'événements',
      icon: 'event',
      categories: ['Événements', 'Inscriptions', 'Logistique', 'Communication'],
    ),
    AppModule(
      id: 'services',
      name: 'Gestion des services',
      description: 'Organisation des services religieux',
      icon: 'church',
      categories: ['Services', 'Liturgie', 'Équipes', 'Planification'],
    ),
    AppModule(
      id: 'taches',
      name: 'Gestion des tâches',
      description: 'Suivi des tâches et projets',
      icon: 'task',
      categories: ['Tâches', 'Projets', 'Attribution', 'Suivi'],
    ),
    AppModule(
      id: 'blog',
      name: 'Blog et articles',
      description: 'Publication de contenu et articles',
      icon: 'article',
      categories: ['Articles', 'Publications', 'Commentaires', 'Médias'],
    ),
    AppModule(
      id: 'offrandes',
      name: 'Gestion des offrandes',
      description: 'Suivi des dons et offrandes',
      icon: 'monetization_on',
      categories: ['Offrandes', 'Dons', 'Finances', 'Rapports'],
    ),
    AppModule(
      id: 'chants',
      name: 'Gestion des chants',
      description: 'Bibliothèque de chants et louanges',
      icon: 'music_note',
      categories: ['Chants', 'Paroles', 'Accords', 'Playlists'],
    ),
    AppModule(
      id: 'bible',
      name: 'Module Bible',
      description: 'Lecture et étude biblique',
      icon: 'menu_book',
      categories: ['Lecture', 'Études', 'Commentaires', 'Recherche'],
    ),
    AppModule(
      id: 'formulaires',
      name: 'Gestion des formulaires',
      description: 'Création et gestion de formulaires',
      icon: 'description',
      categories: ['Formulaires', 'Réponses', 'Analyses', 'Templates'],
    ),
    AppModule(
      id: 'pages',
      name: 'Gestion des pages',
      description: 'Création et édition de pages',
      icon: 'web',
      categories: ['Pages', 'Contenu', 'Design', 'Publication'],
    ),
    AppModule(
      id: 'vie_eglise',
      name: 'Vie de l\'église',
      description: 'Actions et interactions communautaires',
      icon: 'favorite',
      categories: ['Actions', 'Communication', 'Témoignages', 'Prières'],
    ),
    AppModule(
      id: 'configuration',
      name: 'Configuration',
      description: 'Paramètres et configuration système',
      icon: 'settings',
      categories: ['Paramètres', 'Sécurité', 'Intégrations', 'Maintenance'],
    ),
    AppModule(
      id: 'roles',
      name: 'Rôles et permissions',
      description: 'Gestion des rôles et permissions',
      icon: 'admin_panel_settings',
      categories: ['Rôles', 'Permissions', 'Utilisateurs', 'Sécurité'],
    ),
  ];

  static AppModule? findById(String id) {
    try {
      return allModules.firstWhere((module) => module.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Modèle pour les rôles avec permissions détaillées
class Role {
  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final Map<String, List<String>> modulePermissions; // module_id -> [permission_ids]
  final bool isSystemRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final Map<String, dynamic>? metadata;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.modulePermissions,
    this.isSystemRole = false,
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.metadata,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Role.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Role(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#4CAF50',
      icon: data['icon'] ?? 'person',
      modulePermissions: Map<String, List<String>>.from(
        (data['modulePermissions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value ?? [])),
        ),
      ),
      isSystemRole: data['isSystemRole'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'modulePermissions': modulePermissions,
      'isSystemRole': isSystemRole,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'metadata': metadata,
    };
  }

  /// Obtient toutes les permissions du rôle
  List<String> get allPermissions {
    return modulePermissions.values.expand((permissions) => permissions).toList();
  }

  /// Vérifie si le rôle a une permission spécifique
  bool hasPermission(String permissionId) {
    return allPermissions.contains(permissionId);
  }

  /// Vérifie si le rôle a des permissions pour un module
  bool hasModuleAccess(String moduleId) {
    return modulePermissions.containsKey(moduleId) && 
           modulePermissions[moduleId]!.isNotEmpty;
  }

  /// Obtient les permissions pour un module spécifique
  List<String> getModulePermissions(String moduleId) {
    return modulePermissions[moduleId] ?? [];
  }

  Role copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    Map<String, List<String>>? modulePermissions,
    bool? isSystemRole,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    Map<String, dynamic>? metadata,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      modulePermissions: modulePermissions ?? this.modulePermissions,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Attribution d'un rôle à un utilisateur
class UserRole {
  final String id;
  final String userId;
  final String roleId;
  final DateTime assignedAt;
  final String assignedBy;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  UserRole({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.assignedAt,
    required this.assignedBy,
    this.expiresAt,
    this.isActive = true,
    this.metadata,
  });

  factory UserRole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserRole(
      id: doc.id,
      userId: data['userId'] ?? '',
      roleId: data['roleId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedBy: data['assignedBy'] ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'roleId': roleId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'assignedBy': assignedBy,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Vérifie si l'attribution est expirée
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Vérifie si l'attribution est valide
  bool get isValid {
    return isActive && !isExpired;
  }

  UserRole copyWith({
    String? id,
    String? userId,
    String? roleId,
    DateTime? assignedAt,
    String? assignedBy,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserRole(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
