import 'package:flutter/material.dart';

/// Énumération des types de permissions
enum PermissionType {
  read('read', 'Lecture', Icons.visibility, 'Consulter les données'),
  write('write', 'Écriture', Icons.edit, 'Créer et modifier'),
  delete('delete', 'Suppression', Icons.delete, 'Supprimer des éléments'),
  manage('manage', 'Gestion', Icons.admin_panel_settings, 'Gestion avancée'),
  export('export', 'Export', Icons.download, 'Exporter les données'),
  statistics('statistics', 'Statistiques', Icons.analytics, 'Voir les statistiques');

  const PermissionType(this.key, this.label, this.icon, this.description);

  final String key;
  final String label;
  final IconData icon;
  final String description;
}

/// Modèle pour un module de l'application
class AppModule {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final List<PermissionType> availablePermissions;
  final String category;

  const AppModule({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.availablePermissions,
    required this.category,
  });

  /// Génère la clé de permission pour ce module et ce type
  String getPermissionKey(PermissionType type) {
    return '${key}_${type.key}';
  }

  /// Vérifie si ce module a une permission spécifique
  bool hasPermissionType(PermissionType type) {
    return availablePermissions.contains(type);
  }
}

/// Classe pour organiser les permissions par module
class ModulePermissionModel {
  final AppModule module;
  final Map<PermissionType, bool> permissions;

  ModulePermissionModel({
    required this.module,
    Map<PermissionType, bool>? permissions,
  }) : permissions = permissions ?? {};

  /// Met à jour une permission spécifique
  void setPermission(PermissionType type, bool value) {
    if (module.hasPermissionType(type)) {
      permissions[type] = value;
    }
  }

  /// Vérifie si une permission est accordée
  bool hasPermission(PermissionType type) {
    return permissions[type] ?? false;
  }

  /// Retourne toutes les permissions actives sous forme de clés
  List<String> getActivePermissionKeys() {
    final List<String> keys = [];
    for (final entry in permissions.entries) {
      if (entry.value == true) {
        keys.add(module.getPermissionKey(entry.key));
      }
    }
    return keys;
  }

  /// Copie avec des modifications
  ModulePermissionModel copyWith({
    AppModule? module,
    Map<PermissionType, bool>? permissions,
  }) {
    return ModulePermissionModel(
      module: module ?? this.module,
      permissions: permissions ?? Map.from(this.permissions),
    );
  }
}

/// Définition de tous les modules disponibles
class AppModules {
  static const List<AppModule> all = [
    // Module Personnes
    AppModule(
      key: 'personnes',
      name: 'Personnes',
      description: 'Gestion des membres et fidèles',
      icon: Icons.people,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.export,
        PermissionType.statistics,
      ],
      category: 'Gestion des données',
    ),

    // Module Groupes
    AppModule(
      key: 'groupes',
      name: 'Groupes',
      description: 'Gestion des groupes et cellules',
      icon: Icons.group,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
        PermissionType.export,
      ],
      category: 'Gestion des données',
    ),

    // Module Événements
    AppModule(
      key: 'evenements',
      name: 'Événements',
      description: 'Organisation des événements',
      icon: Icons.event,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
        PermissionType.export,
      ],
      category: 'Planification',
    ),

    // Module Services
    AppModule(
      key: 'services',
      name: 'Services religieux',
      description: 'Planification des services religieux',
      icon: Icons.church,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Planification',
    ),

    // Module Bénévolat
    AppModule(
      key: 'benevolat',
      name: 'Bénévolat',
      description: 'Gestion du bénévolat',
      icon: Icons.volunteer_activism,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
        PermissionType.export,
      ],
      category: 'Gestion des données',
    ),

    // Module Tâches
    AppModule(
      key: 'taches',
      name: 'Tâches',
      description: 'Gestion des tâches et responsabilités',
      icon: Icons.task,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Planification',
    ),

    // Module Chants
    AppModule(
      key: 'chants',
      name: 'Chants et cantiques',
      description: 'Bibliothèque de chants',
      icon: Icons.music_note,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Contenu',
    ),

    // Module Bible
    AppModule(
      key: 'bible',
      name: 'Bible',
      description: 'Étude et enseignement biblique',
      icon: Icons.menu_book,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.manage,
      ],
      category: 'Contenu',
    ),

    // Module Pain quotidien
    AppModule(
      key: 'daily_bread',
      name: 'Pain quotidien',
      description: 'Méditations et pain quotidien',
      icon: Icons.today,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.manage,
      ],
      category: 'Contenu',
    ),

    // Module Offrandes
    AppModule(
      key: 'offrandes',
      name: 'Offrandes',
      description: 'Gestion des offrandes et dîmes',
      icon: Icons.monetization_on,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.export,
        PermissionType.statistics,
      ],
      category: 'Finance',
    ),

    // Module Blog
    AppModule(
      key: 'blog',
      name: 'Blog',
      description: 'Articles et actualités',
      icon: Icons.article,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Communication',
    ),

    // Module Vie d'église
    AppModule(
      key: 'vie_eglise',
      name: 'Vie d\'église',
      description: 'Informations sur la vie de l\'église',
      icon: Icons.home,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.manage,
      ],
      category: 'Communication',
    ),

    // Module Configuration
    AppModule(
      key: 'configuration',
      name: 'Configuration',
      description: 'Paramètres de l\'application',
      icon: Icons.settings,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.manage,
      ],
      category: 'Administration',
    ),

    // Module Rôles
    AppModule(
      key: 'roles',
      name: 'Rôles et permissions',
      description: 'Gestion des rôles et permissions',
      icon: Icons.admin_panel_settings,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Administration',
    ),

    // Module Rapports
    AppModule(
      key: 'reports',
      name: 'Rapports',
      description: 'Génération de rapports',
      icon: Icons.assessment,
      availablePermissions: [
        PermissionType.read,
        PermissionType.export,
        PermissionType.statistics,
      ],
      category: 'Administration',
    ),

    // Module Rendez-vous
    AppModule(
      key: 'rendezvous',
      name: 'Rendez-vous',
      description: 'Gestion des rendez-vous pastoraux',
      icon: Icons.calendar_today,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
      ],
      category: 'Planification',
    ),

    // Module Formulaires
    AppModule(
      key: 'formulaires',
      name: 'Formulaires',
      description: 'Création et gestion de formulaires',
      icon: Icons.description,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.delete,
        PermissionType.manage,
        PermissionType.export,
      ],
      category: 'Gestion des données',
    ),

    // Module Automation
    AppModule(
      key: 'automation',
      name: 'Automatisation',
      description: 'Automatisation des tâches',
      icon: Icons.smart_toy,
      availablePermissions: [
        PermissionType.read,
        PermissionType.write,
        PermissionType.manage,
      ],
      category: 'Administration',
    ),
  ];

  /// Récupère les modules par catégorie
  static Map<String, List<AppModule>> get byCategory {
    final Map<String, List<AppModule>> categories = {};
    for (final module in all) {
      categories.putIfAbsent(module.category, () => []);
      categories[module.category]!.add(module);
    }
    return categories;
  }

  /// Trouve un module par sa clé
  static AppModule? findByKey(String key) {
    try {
      return all.firstWhere((module) => module.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Convertit une liste de permissions en ModulePermissionModel
  static List<ModulePermissionModel> fromPermissionKeys(List<String> permissionKeys) {
    final Map<String, ModulePermissionModel> modulePermissions = {};
    
    for (final module in all) {
      modulePermissions[module.key] = ModulePermissionModel(module: module);
    }

    // Analyse les clés de permissions
    for (final key in permissionKeys) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final moduleKey = parts[0];
        final permissionKey = parts.sublist(1).join('_');
        
        final module = findByKey(moduleKey);
        if (module != null) {
          final permissionType = PermissionType.values
              .where((type) => type.key == permissionKey)
              .firstOrNull;
          
          if (permissionType != null) {
            modulePermissions[moduleKey]?.setPermission(permissionType, true);
          }
        }
      }
    }

    return modulePermissions.values.toList();
  }

  /// Convertit une liste de ModulePermissionModel en clés de permissions
  static List<String> toPermissionKeys(List<ModulePermissionModel> modulePermissions) {
    final List<String> keys = [];
    for (final modulePermission in modulePermissions) {
      keys.addAll(modulePermission.getActivePermissionKeys());
    }
    return keys;
  }
}
