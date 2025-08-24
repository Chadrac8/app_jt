import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modèle pour les groupes d'actions "Pour vous"
class ActionGroup {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String iconCodePoint;
  final String? color; // Couleur hexadécimale
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  ActionGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconCodePoint,
    this.color,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ActionGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActionGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: IconData(
        data['iconCodePoint'] ?? Icons.folder.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      iconCodePoint: data['iconCodePoint']?.toString() ?? Icons.folder.codePoint.toString(),
      color: data['color'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconCodePoint': int.parse(iconCodePoint),
      'color': color,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  ActionGroup copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    String? iconCodePoint,
    String? color,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ActionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      color: color ?? this.color,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
