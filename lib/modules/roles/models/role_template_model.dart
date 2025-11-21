import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme.dart';

/// Modèle pour les templates de rôles pré-configurés
class RoleTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> permissionIds;
  final Map<String, dynamic> configuration;
  final String iconName;
  final String colorCode;
  final bool isSystemTemplate;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isActive;
  final Map<String, String> localizations;
  
  const RoleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.permissionIds,
    required this.configuration,
    required this.iconName,
    required this.colorCode,
    this.isSystemTemplate = false,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.isActive = true,
    this.localizations = const {},
  });

  factory RoleTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RoleTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      permissionIds: List<String>.from(data['permissionIds'] ?? []),
      configuration: Map<String, dynamic>.from(data['configuration'] ?? {}),
      iconName: data['iconName'] ?? 'admin_panel_settings',
      colorCode: data['colorCode'] ?? '#2196F3',
      isSystemTemplate: data['isSystemTemplate'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      isActive: data['isActive'] ?? true,
      localizations: Map<String, String>.from(data['localizations'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'permissionIds': permissionIds,
      'configuration': configuration,
      'iconName': iconName,
      'colorCode': colorCode,
      'isSystemTemplate': isSystemTemplate,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'localizations': localizations,
    };
  }

  RoleTemplate copyWith({
    String? name,
    String? description,
    String? category,
    List<String>? permissionIds,
    Map<String, dynamic>? configuration,
    String? iconName,
    String? colorCode,
    bool? isSystemTemplate,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isActive,
    Map<String, String>? localizations,
  }) {
    return RoleTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      permissionIds: permissionIds ?? this.permissionIds,
      configuration: configuration ?? this.configuration,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
      localizations: localizations ?? this.localizations,
    );
  }

  /// Templates système prédéfinis
  static List<RoleTemplate> get systemTemplates => [
    // Template Super Administrateur
    RoleTemplate(
      id: 'template_super_admin',
      name: 'Super Administrateur',
      description: 'Accès complet à toutes les fonctionnalités du système',
      category: 'administration',
      permissionIds: [
        'system.full_access',
        'users.manage',
        'roles.manage',
        'content.manage',
        'settings.manage',
        'audit.view',
      ],
      configuration: {
        'maxUsers': -1, // Illimité
        'restrictedModules': <String>[],
        'requireApproval': false,
        'autoExpiry': false,
      },
      iconName: 'admin_panel_settings',
      colorCode: '#D32F2F',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      localizations: {
        'name_en': 'Super Administrator',
        'description_en': 'Full access to all system features',
        'name_es': 'Súper Administrador',
        'description_es': 'Acceso completo a todas las características del sistema',
      },
    ),

    // Template Administrateur
    RoleTemplate(
      id: 'template_admin',
      name: 'Administrateur',
      description: 'Gestion des utilisateurs et des contenus principaux',
      category: 'administration',
      permissionIds: [
        'users.manage',
        'content.manage',
        'events.manage',
        'announcements.manage',
        'reports.view',
      ],
      configuration: {
        'maxUsers': 50,
        'restrictedModules': ['settings', 'audit'],
        'requireApproval': true,
        'autoExpiry': false,
      },
      iconName: 'supervisor_account',
      colorCode: '#1976D2',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      localizations: {
        'name_en': 'Administrator',
        'description_en': 'User and main content management',
      },
    ),

    // Template Modérateur
    RoleTemplate(
      id: 'template_moderator',
      name: 'Modérateur',
      description: 'Modération des contenus et gestion des événements',
      category: 'moderation',
      permissionIds: [
        'content.moderate',
        'events.manage',
        'comments.moderate',
        'reports.create',
      ],
      configuration: {
        'maxUsers': 100,
        'restrictedModules': ['users', 'settings'],
        'requireApproval': true,
        'autoExpiry': false,
      },
      iconName: 'verified_user',
      colorCode: '#388E3C',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Éditeur
    RoleTemplate(
      id: 'template_editor',
      name: 'Éditeur',
      description: 'Création et édition de contenus',
      category: 'content',
      permissionIds: [
        'content.create',
        'content.edit',
        'events.create',
        'announcements.create',
      ],
      configuration: {
        'maxUsers': 200,
        'restrictedModules': ['users', 'settings', 'audit'],
        'requireApproval': true,
        'autoExpiry': false,
      },
      iconName: 'edit',
      colorCode: '#F57C00',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Pasteur
    RoleTemplate(
      id: 'template_pastor',
      name: 'Pasteur',
      description: 'Accès spécialisé pour les pasteurs et responsables spirituels',
      category: 'ministry',
      permissionIds: [
        'sermons.manage',
        'prayers.manage',
        'pastoral_care.access',
        'events.manage',
        'members.view',
        'reports.view',
      ],
      configuration: {
        'maxUsers': 20,
        'restrictedModules': ['settings', 'audit', 'finances'],
        'requireApproval': true,
        'autoExpiry': false,
        'specialAccess': ['pastoral_dashboard', 'member_care'],
      },
      iconName: 'church',
      colorCode: '#7B1FA2',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Responsable Finances
    RoleTemplate(
      id: 'template_treasurer',
      name: 'Responsable Finances',
      description: 'Gestion des finances et des dons',
      category: 'finance',
      permissionIds: [
        'finances.manage',
        'donations.manage',
        'transactions.view',
        'financial_reports.create',
        'budget.manage',
      ],
      configuration: {
        'maxUsers': 10,
        'restrictedModules': ['users', 'content'],
        'requireApproval': true,
        'autoExpiry': false,
        'auditRequired': true,
      },
      iconName: 'account_balance',
      colorCode: '#689F38',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Responsable Événements
    RoleTemplate(
      id: 'template_event_manager',
      name: 'Responsable Événements',
      description: 'Organisation et gestion des événements',
      category: 'events',
      permissionIds: [
        'events.manage',
        'calendar.manage',
        'venues.manage',
        'registrations.manage',
        'event_reports.view',
      ],
      configuration: {
        'maxUsers': 30,
        'restrictedModules': ['finances', 'settings'],
        'requireApproval': false,
        'autoExpiry': false,
      },
      iconName: 'event',
      colorCode: '#FF5722',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Membre
    RoleTemplate(
      id: 'template_member',
      name: 'Membre',
      description: 'Accès de base pour les membres de la communauté',
      category: 'member',
      permissionIds: [
        'content.view',
        'events.view',
        'profile.edit',
        'donations.personal',
        'prayers.submit',
      ],
      configuration: {
        'maxUsers': -1, // Illimité
        'restrictedModules': [],
        'requireApproval': false,
        'autoExpiry': false,
      },
      iconName: 'person',
      colorCode: '#607D8B',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),

    // Template Visiteur
    RoleTemplate(
      id: 'template_visitor',
      name: 'Visiteur',
      description: 'Accès limité pour les visiteurs',
      category: 'public',
      permissionIds: [
        'content.view_public',
        'events.view_public',
        'contact.submit',
      ],
      configuration: {
        'maxUsers': -1,
        'restrictedModules': ['profile', 'members'],
        'requireApproval': false,
        'autoExpiry': true,
        'expiryDays': 30,
      },
      iconName: 'visibility',
      colorCode: '#9E9E9E',
      isSystemTemplate: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
  ];

  /// Catégories de templates
  static List<String> get categories => [
    'administration',
    'moderation',
    'content',
    'ministry',
    'finance',
    'events',
    'member',
    'public',
  ];

  /// Obtenir le nom localisé
  String getLocalizedName(String locale) {
    return localizations['name_$locale'] ?? name;
  }

  /// Obtenir la description localisée
  String getLocalizedDescription(String locale) {
    return localizations['description_$locale'] ?? description;
  }

  /// Vérifier si le template est modifiable
  bool get isEditable => !isSystemTemplate;

  /// Obtenir l'icône Flutter
  IconData get iconData {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'verified_user': return Icons.verified_user;
      case 'edit': return Icons.edit;
      case 'church': return Icons.church;
      case 'account_balance': return Icons.account_balance;
      case 'event': return Icons.event;
      case 'person': return Icons.person;
      case 'visibility': return Icons.visibility;
      default: return Icons.admin_panel_settings;
    }
  }

  /// Obtenir la couleur Flutter
  Color get color {
    try {
      final hexColor = colorCode.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.infoColor;
    }
  }

  /// Valider la configuration du template
  bool isConfigurationValid() {
    // Vérifications de base
    if (name.isEmpty || description.isEmpty) return false;
    if (permissionIds.isEmpty) return false;
    if (category.isEmpty) return false;
    
    // Vérifications de configuration
    final maxUsers = configuration['maxUsers'] as int?;
    if (maxUsers != null && maxUsers < -1) return false;
    
    final restrictedModules = configuration['restrictedModules'] as List<String>?;
    if (restrictedModules != null && restrictedModules.contains('')) return false;
    
    return true;
  }

  /// Générer un hash pour la comparaison
  String generateHash() {
    final components = [
      name,
      description,
      category,
      permissionIds.join(','),
      configuration.toString(),
      iconName,
      colorCode,
    ];
    
    return components.join('|').hashCode.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoleTemplate) return false;
    
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoleTemplate(id: $id, name: $name, category: $category, permissions: ${permissionIds.length})';
  }
}

/// Extension pour faciliter la création de rôles à partir de templates
extension RoleTemplateExtension on RoleTemplate {
  /// Créer un rôle à partir du template
  Map<String, dynamic> toRoleData({
    String? customName,
    String? customDescription,
    Map<String, dynamic>? additionalConfig,
  }) {
    return {
      'name': customName ?? name,
      'description': customDescription ?? description,
      'permissions': permissionIds,
      'icon': iconName,
      'color': colorCode,
      'isActive': true,
      'isSystem': false,
      'configuration': {
        ...configuration,
        if (additionalConfig != null) ...additionalConfig,
      },
      'templateId': id,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Vérifier la compatibilité avec un autre template
  bool isCompatibleWith(RoleTemplate other) {
    // Même catégorie
    if (category != other.category) return false;
    
    // Au moins 50% de permissions communes
    final commonPermissions = permissionIds
        .where((perm) => other.permissionIds.contains(perm))
        .length;
    
    final totalPermissions = (permissionIds.length + other.permissionIds.length) / 2;
    final compatibilityRatio = commonPermissions / totalPermissions;
    
    return compatibilityRatio >= 0.5;
  }
  
  /// Fusionner avec un autre template
  RoleTemplate mergeWith(RoleTemplate other, {
    required String newId,
    required String newName,
    String? newDescription,
  }) {
    final mergedPermissions = <String>{
      ...permissionIds,
      ...other.permissionIds,
    }.toList();
    
    final mergedConfig = <String, dynamic>{
      ...configuration,
      ...other.configuration,
    };
    
    return RoleTemplate(
      id: newId,
      name: newName,
      description: newDescription ?? '$description + ${other.description}',
      category: category, // Garde la catégorie principale
      permissionIds: mergedPermissions,
      configuration: mergedConfig,
      iconName: iconName, // Garde l'icône principale
      colorCode: colorCode, // Garde la couleur principale
      createdAt: DateTime.now(),
      createdBy: 'template_merge',
      localizations: {
        ...localizations,
        ...other.localizations,
      },
    );
  }
}

/// Énumération pour les catégories de templates
enum TemplateCategory {
  administration('administration', 'Administration', Icons.admin_panel_settings),
  moderation('moderation', 'Modération', Icons.verified_user),
  content('content', 'Contenu', Icons.edit),
  ministry('ministry', 'Ministère', Icons.church),
  finance('finance', 'Finance', Icons.account_balance),
  events('events', 'Événements', Icons.event),
  member('member', 'Membres', Icons.people),
  public('public', 'Public', Icons.visibility);

  const TemplateCategory(this.id, this.displayName, this.icon);
  
  final String id;
  final String displayName;
  final IconData icon;
  
  static TemplateCategory fromId(String id) {
    return TemplateCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => TemplateCategory.member,
    );
  }
}