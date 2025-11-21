import 'package:cloud_firestore/cloud_firestore.dart';

/// Opérateurs de comparaison pour les critères de segment
enum SegmentOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  contains,
  notContains,
  arrayContains,
  arrayContainsAny,
  arrayNotContains,
  isNull,
  isNotNull,
  startsWith,
  endsWith;

  String get displayName {
    switch (this) {
      case SegmentOperator.equals:
        return 'Égal à';
      case SegmentOperator.notEquals:
        return 'Différent de';
      case SegmentOperator.greaterThan:
        return 'Supérieur à';
      case SegmentOperator.greaterThanOrEqual:
        return 'Supérieur ou égal à';
      case SegmentOperator.lessThan:
        return 'Inférieur à';
      case SegmentOperator.lessThanOrEqual:
        return 'Inférieur ou égal à';
      case SegmentOperator.contains:
        return 'Contient';
      case SegmentOperator.notContains:
        return 'Ne contient pas';
      case SegmentOperator.arrayContains:
        return 'Tableau contient';
      case SegmentOperator.arrayContainsAny:
        return 'Tableau contient un de';
      case SegmentOperator.arrayNotContains:
        return 'Tableau ne contient pas';
      case SegmentOperator.isNull:
        return 'Est vide';
      case SegmentOperator.isNotNull:
        return 'N\'est pas vide';
      case SegmentOperator.startsWith:
        return 'Commence par';
      case SegmentOperator.endsWith:
        return 'Se termine par';
    }
  }

  String get symbol {
    switch (this) {
      case SegmentOperator.equals:
        return '==';
      case SegmentOperator.notEquals:
        return '!=';
      case SegmentOperator.greaterThan:
        return '>';
      case SegmentOperator.greaterThanOrEqual:
        return '>=';
      case SegmentOperator.lessThan:
        return '<';
      case SegmentOperator.lessThanOrEqual:
        return '<=';
      case SegmentOperator.contains:
        return '⊃';
      case SegmentOperator.notContains:
        return '⊅';
      case SegmentOperator.arrayContains:
        return '∈';
      case SegmentOperator.arrayContainsAny:
        return '∈?';
      case SegmentOperator.arrayNotContains:
        return '∉';
      case SegmentOperator.isNull:
        return '∅';
      case SegmentOperator.isNotNull:
        return '≠∅';
      case SegmentOperator.startsWith:
        return '^';
      case SegmentOperator.endsWith:
        return '\$';
    }
  }
}

/// Critère de segmentation
class SegmentCriterion {
  final String field;
  final SegmentOperator operator;
  final dynamic value;
  final String? displayName;

  const SegmentCriterion({
    required this.field,
    required this.operator,
    required this.value,
    this.displayName,
  });

  factory SegmentCriterion.fromMap(Map<String, dynamic> map) {
    return SegmentCriterion(
      field: map['field'] ?? '',
      operator: SegmentOperator.values.firstWhere(
        (o) => o.toString() == map['operator'],
        orElse: () => SegmentOperator.equals,
      ),
      value: map['value'],
      displayName: map['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator.toString(),
      'value': value,
      'displayName': displayName,
    };
  }

  String get description {
    final fieldDisplay = displayName ?? field;
    final valueDisplay = value?.toString() ?? 'null';
    return '$fieldDisplay ${operator.symbol} $valueDisplay';
  }

  @override
  String toString() {
    return 'SegmentCriterion(field: $field, operator: $operator, value: $value)';
  }
}

/// Types de segment prédéfinis
enum PredefinedSegmentType {
  allUsers,
  activeUsers,
  adminUsers,
  inactiveUsers,
  newUsers,
  frequentUsers,
  ageGroup,
  roleBasedGroup,
  locationBasedGroup,
  custom;

  String get displayName {
    switch (this) {
      case PredefinedSegmentType.allUsers:
        return 'Tous les utilisateurs';
      case PredefinedSegmentType.activeUsers:
        return 'Utilisateurs actifs';
      case PredefinedSegmentType.adminUsers:
        return 'Administrateurs';
      case PredefinedSegmentType.inactiveUsers:
        return 'Utilisateurs inactifs';
      case PredefinedSegmentType.newUsers:
        return 'Nouveaux utilisateurs';
      case PredefinedSegmentType.frequentUsers:
        return 'Utilisateurs fréquents';
      case PredefinedSegmentType.ageGroup:
        return 'Groupe d\'âge';
      case PredefinedSegmentType.roleBasedGroup:
        return 'Groupe par rôle';
      case PredefinedSegmentType.locationBasedGroup:
        return 'Groupe par localisation';
      case PredefinedSegmentType.custom:
        return 'Segment personnalisé';
    }
  }
}

/// Modèle de segment d'utilisateurs
class UserSegmentModel {
  final String id;
  final String name;
  final String description;
  final List<SegmentCriterion> criteria;
  final PredefinedSegmentType type;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> tags;
  final int estimatedUserCount;
  final DateTime? lastCountUpdate;
  final Map<String, dynamic> metadata;

  const UserSegmentModel({
    required this.id,
    required this.name,
    this.description = '',
    this.criteria = const [],
    this.type = PredefinedSegmentType.custom,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.tags = const [],
    this.estimatedUserCount = 0,
    this.lastCountUpdate,
    this.metadata = const {},
  });

  /// Crée une instance depuis Firestore
  factory UserSegmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserSegmentModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      criteria: (data['criteria'] as List?)?.map((c) => 
        SegmentCriterion.fromMap(Map<String, dynamic>.from(c))
      ).toList() ?? [],
      type: PredefinedSegmentType.values.firstWhere(
        (t) => t.toString() == data['type'],
        orElse: () => PredefinedSegmentType.custom,
      ),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      estimatedUserCount: data['estimatedUserCount'] ?? 0,
      lastCountUpdate: (data['lastCountUpdate'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'criteria': criteria.map((c) => c.toMap()).toList(),
      'type': type.toString(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'tags': tags,
      'estimatedUserCount': estimatedUserCount,
      'lastCountUpdate': lastCountUpdate != null ? Timestamp.fromDate(lastCountUpdate!) : null,
      'metadata': metadata,
    };
  }

  /// Crée une copie avec des modifications
  UserSegmentModel copyWith({
    String? id,
    String? name,
    String? description,
    List<SegmentCriterion>? criteria,
    PredefinedSegmentType? type,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? tags,
    int? estimatedUserCount,
    DateTime? lastCountUpdate,
    Map<String, dynamic>? metadata,
  }) {
    return UserSegmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      estimatedUserCount: estimatedUserCount ?? this.estimatedUserCount,
      lastCountUpdate: lastCountUpdate ?? this.lastCountUpdate,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Obtient une description lisible des critères
  String get criteriaDescription {
    if (criteria.isEmpty) {
      return type.displayName;
    }
    return criteria.map((c) => c.description).join(' ET ');
  }

  /// Indique si le segment est prédéfini
  bool get isPredefined => type != PredefinedSegmentType.custom;

  /// Indique si le nombre d'utilisateurs est obsolète
  bool get isCountStale {
    if (lastCountUpdate == null) return true;
    return DateTime.now().difference(lastCountUpdate!).inHours > 24;
  }

  /// Factory methods pour les segments prédéfinis
  static UserSegmentModel allUsers({
    required String createdBy,
    required String createdByName,
  }) {
    return UserSegmentModel(
      id: 'all_users',
      name: 'Tous les utilisateurs',
      description: 'Segment incluant tous les utilisateurs enregistrés',
      type: PredefinedSegmentType.allUsers,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
    );
  }

  static UserSegmentModel activeUsers({
    required String createdBy,
    required String createdByName,
  }) {
    return UserSegmentModel(
      id: 'active_users',
      name: 'Utilisateurs actifs',
      description: 'Utilisateurs avec un statut actif',
      criteria: [
        const SegmentCriterion(
          field: 'isActive',
          operator: SegmentOperator.equals,
          value: true,
          displayName: 'Statut actif',
        ),
      ],
      type: PredefinedSegmentType.activeUsers,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
    );
  }

  static UserSegmentModel adminUsers({
    required String createdBy,
    required String createdByName,
  }) {
    return UserSegmentModel(
      id: 'admin_users',
      name: 'Administrateurs',
      description: 'Utilisateurs avec des privilèges d\'administration',
      criteria: [
        const SegmentCriterion(
          field: 'roles',
          operator: SegmentOperator.arrayContains,
          value: 'admin',
          displayName: 'Rôle admin',
        ),
        const SegmentCriterion(
          field: 'isActive',
          operator: SegmentOperator.equals,
          value: true,
          displayName: 'Statut actif',
        ),
      ],
      type: PredefinedSegmentType.adminUsers,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserSegmentModel(id: $id, name: $name, type: $type, criteria: ${criteria.length})';
  }
}
