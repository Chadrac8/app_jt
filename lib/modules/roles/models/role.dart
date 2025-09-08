import 'package:cloud_firestore/cloud_firestore.dart';
import 'permission.dart';

class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Nouveaux champs pour améliorer l'UI
  final String color;
  final String icon;
  final String? createdBy;
  final String? lastModifiedBy;

  Role({
    required this.id,
    required this.name,
    required this.description,
    this.permissions = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.color = '#4CAF50',
    this.icon = 'person',
    this.createdBy,
    this.lastModifiedBy,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      color: map['color'] ?? '#4CAF50',
      icon: map['icon'] ?? 'person',
      createdBy: map['createdBy'],
      lastModifiedBy: map['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'color': color,
      'icon': icon,
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  factory Role.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Role.fromMap({...data, 'id': doc.id});
  }

  Role copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? icon,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  bool hasPermission(String permissionId) {
    return permissions.contains(permissionId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Role(id: $id, name: $name, permissions: ${permissions.length})';
  }

  // Rôles prédéfinis
  static Role get admin => Role(
    id: 'admin',
    name: 'Administrateur',
    description: 'Accès complet à toutes les fonctionnalités',
    permissions: [
      'users.read',
      'users.write',
      'users.delete',
      'roles.read',
      'roles.write',
      'roles.delete',
      'content.read',
      'content.write',
      'content.delete',
      'settings.read',
      'settings.write',
    ],
  );

  static Role get moderator => Role(
    id: 'moderator',
    name: 'Modérateur',
    description: 'Gestion du contenu et des utilisateurs',
    permissions: [
      'users.read',
      'users.write',
      'content.read',
      'content.write',
      'content.delete',
    ],
  );

  static Role get contributor => Role(
    id: 'contributor',
    name: 'Contributeur',
    description: 'Création et modification de contenu',
    permissions: [
      'content.read',
      'content.write',
    ],
  );

  static Role get viewer => Role(
    id: 'viewer',
    name: 'Lecteur',
    description: 'Accès en lecture seule',
    permissions: [
      'content.read',
    ],
  );

  static List<Role> get predefinedRoles => [
    admin,
    moderator,
    contributor,
    viewer,
  ];
}
