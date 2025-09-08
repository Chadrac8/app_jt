import 'package:cloud_firestore/cloud_firestore.dart';

class Permission {
  final String id;
  final String name;
  final String description;
  final String module;
  final String action;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.module,
    required this.action,
    this.createdAt,
    this.updatedAt,
  });

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      module: map['module'] ?? '',
      action: map['action'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'module': module,
      'action': action,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Permission.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Permission.fromMap({...data, 'id': doc.id});
  }

  Permission copyWith({
    String? id,
    String? name,
    String? description,
    String? module,
    String? action,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Permission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      module: module ?? this.module,
      action: action ?? this.action,
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

  @override
  String toString() {
    return 'Permission(id: $id, name: $name, module: $module, action: $action)';
  }
}
