import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Modèle pour la segmentation des utilisateurs
class UserSegment {
  final String id;
  final String name;
  final String description;
  final SegmentType type;
  final List<SegmentCriteria> criteria;
  final List<String> userIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic> metadata;

  UserSegment({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    List<SegmentCriteria>? criteria,
    List<String>? userIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
    this.isActive = true,
    Map<String, dynamic>? metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    criteria = criteria ?? [],
    userIds = userIds ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    metadata = metadata ?? {};

  factory UserSegment.fromJson(Map<String, dynamic> json) {
    return UserSegment(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: SegmentType.values[json['type']],
      criteria: (json['criteria'] as List<dynamic>?)
          ?.map((c) => SegmentCriteria.fromJson(c))
          .toList() ?? [],
      userIds: List<String>.from(json['userIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'userIds': userIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}

/// Types de segments
enum SegmentType {
  role,        // Par rôle (admin, membre, visiteur)
  department,  // Par département (jeunes, adultes, enfants)
  location,    // Par localisation géographique
  activity,    // Par activité/engagement
  custom,      // Personnalisé
  dynamic      // Dynamique (critères automatiques)
}

/// Critères de segmentation
class SegmentCriteria {
  final String field;
  final SegmentOperator operator;
  final dynamic value;
  final String? description;

  const SegmentCriteria({
    required this.field,
    required this.operator,
    required this.value,
    this.description,
  });

  factory SegmentCriteria.fromJson(Map<String, dynamic> json) {
    return SegmentCriteria(
      field: json['field'],
      operator: SegmentOperator.values[json['operator']],
      value: json['value'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator.index,
      'value': value,
      'description': description,
    };
  }
}

/// Opérateurs de segmentation
enum SegmentOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  inList,
  notInList,
  isNull,
  isNotNull
}

/// Service de segmentation des utilisateurs
class UserSegmentationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau segment
  Future<UserSegment> createSegment(UserSegment segment) async {
    await _firestore
        .collection('userSegments')
        .doc(segment.id)
        .set(segment.toJson());
    return segment;
  }

  /// Récupérer tous les segments
  Future<List<UserSegment>> getAllSegments() async {
    final snapshot = await _firestore
        .collection('userSegments')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => UserSegment.fromJson(doc.data()))
        .toList();
  }

  /// Récupérer un segment par ID
  Future<UserSegment?> getSegmentById(String segmentId) async {
    final doc = await _firestore
        .collection('userSegments')
        .doc(segmentId)
        .get();
    
    if (doc.exists) {
      return UserSegment.fromJson(doc.data()!);
    }
    return null;
  }

  /// Mettre à jour un segment
  Future<void> updateSegment(UserSegment segment) async {
    final updatedSegment = segment.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('userSegments')
        .doc(segment.id)
        .update(updatedSegment.toJson());
  }

  /// Supprimer un segment
  Future<void> deleteSegment(String segmentId) async {
    await _firestore
        .collection('userSegments')
        .doc(segmentId)
        .update({'isActive': false});
  }

  /// Évaluer les critères pour un utilisateur
  Future<List<UserSegment>> getUserSegments(String userId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    if (!userDoc.exists) return [];
    
    final userData = userDoc.data()!;
    final allSegments = await getAllSegments();
    
    return allSegments.where((segment) {
      return _evaluateSegmentCriteria(segment, userData);
    }).toList();
  }

  /// Récupérer les utilisateurs d'un segment
  Future<List<String>> getSegmentUsers(String segmentId) async {
    final segment = await getSegmentById(segmentId);
    if (segment == null) return [];

    if (segment.type == SegmentType.custom) {
      return segment.userIds;
    }

    // Pour les segments dynamiques, évaluer les critères
    final usersSnapshot = await _firestore.collection('users').get();
    final matchingUsers = <String>[];

    for (final userDoc in usersSnapshot.docs) {
      if (_evaluateSegmentCriteria(segment, userDoc.data())) {
        matchingUsers.add(userDoc.id);
      }
    }

    return matchingUsers;
  }

  /// Ajouter un utilisateur à un segment personnalisé
  Future<void> addUserToSegment(String segmentId, String userId) async {
    await _firestore
        .collection('userSegments')
        .doc(segmentId)
        .update({
      'userIds': FieldValue.arrayUnion([userId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Retirer un utilisateur d'un segment personnalisé
  Future<void> removeUserFromSegment(String segmentId, String userId) async {
    await _firestore
        .collection('userSegments')
        .doc(segmentId)
        .update({
      'userIds': FieldValue.arrayRemove([userId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Évaluer les critères d'un segment pour un utilisateur
  bool _evaluateSegmentCriteria(UserSegment segment, Map<String, dynamic> userData) {
    if (segment.criteria.isEmpty) return false;

    for (final criteria in segment.criteria) {
      if (!_evaluateCriteria(criteria, userData)) {
        return false; // Tous les critères doivent être satisfaits (AND)
      }
    }
    return true;
  }

  /// Évaluer un critère spécifique
  bool _evaluateCriteria(SegmentCriteria criteria, Map<String, dynamic> userData) {
    final fieldValue = _getNestedValue(userData, criteria.field);

    switch (criteria.operator) {
      case SegmentOperator.equals:
        return fieldValue == criteria.value;
      case SegmentOperator.notEquals:
        return fieldValue != criteria.value;
      case SegmentOperator.contains:
        return fieldValue?.toString().contains(criteria.value.toString()) ?? false;
      case SegmentOperator.notContains:
        return !(fieldValue?.toString().contains(criteria.value.toString()) ?? false);
      case SegmentOperator.greaterThan:
        return (fieldValue is num) && fieldValue > criteria.value;
      case SegmentOperator.lessThan:
        return (fieldValue is num) && fieldValue < criteria.value;
      case SegmentOperator.greaterOrEqual:
        return (fieldValue is num) && fieldValue >= criteria.value;
      case SegmentOperator.lessOrEqual:
        return (fieldValue is num) && fieldValue <= criteria.value;
      case SegmentOperator.inList:
        return (criteria.value as List).contains(fieldValue);
      case SegmentOperator.notInList:
        return !(criteria.value as List).contains(fieldValue);
      case SegmentOperator.isNull:
        return fieldValue == null;
      case SegmentOperator.isNotNull:
        return fieldValue != null;
    }
  }

  /// Récupérer une valeur nested dans un Map
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic value = data;
    
    for (final key in keys) {
      if (value is Map<String, dynamic> && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    
    return value;
  }
}

/// Extension pour UserSegment
extension UserSegmentExtension on UserSegment {
  UserSegment copyWith({
    String? id,
    String? name,
    String? description,
    SegmentType? type,
    List<SegmentCriteria>? criteria,
    List<String>? userIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      criteria: criteria ?? this.criteria,
      userIds: userIds ?? this.userIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Segments prédéfinis pour une église
class ChurchSegmentPresets {
  static UserSegment administrateurs(String createdBy) {
    return UserSegment(
      name: 'Administrateurs',
      description: 'Tous les administrateurs de l\'église',
      type: SegmentType.role,
      criteria: [
        const SegmentCriteria(
          field: 'role',
          operator: SegmentOperator.equals,
          value: 'admin',
          description: 'Rôle administrateur',
        ),
      ],
      createdBy: createdBy,
    );
  }

  static UserSegment membres(String createdBy) {
    return UserSegment(
      name: 'Membres',
      description: 'Tous les membres actifs de l\'église',
      type: SegmentType.role,
      criteria: [
        const SegmentCriteria(
          field: 'role',
          operator: SegmentOperator.equals,
          value: 'member',
          description: 'Rôle membre',
        ),
        const SegmentCriteria(
          field: 'isActive',
          operator: SegmentOperator.equals,
          value: true,
          description: 'Membre actif',
        ),
      ],
      createdBy: createdBy,
    );
  }

  static UserSegment jeunes(String createdBy) {
    return UserSegment(
      name: 'Jeunes',
      description: 'Département des jeunes (13-30 ans)',
      type: SegmentType.department,
      criteria: [
        const SegmentCriteria(
          field: 'age',
          operator: SegmentOperator.greaterOrEqual,
          value: 13,
          description: 'Âge minimum 13 ans',
        ),
        const SegmentCriteria(
          field: 'age',
          operator: SegmentOperator.lessOrEqual,
          value: 30,
          description: 'Âge maximum 30 ans',
        ),
      ],
      createdBy: createdBy,
    );
  }

  static UserSegment enfants(String createdBy) {
    return UserSegment(
      name: 'Enfants',
      description: 'Département des enfants (5-12 ans)',
      type: SegmentType.department,
      criteria: [
        const SegmentCriteria(
          field: 'age',
          operator: SegmentOperator.greaterOrEqual,
          value: 5,
          description: 'Âge minimum 5 ans',
        ),
        const SegmentCriteria(
          field: 'age',
          operator: SegmentOperator.lessOrEqual,
          value: 12,
          description: 'Âge maximum 12 ans',
        ),
      ],
      createdBy: createdBy,
    );
  }
}
