import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les actions disponibles dans "Pour vous"
class ActionItem {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String? redirectUrl;
  final String? redirectRoute;
  final String? coverImageUrl;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.redirectUrl,
    this.redirectRoute,
    this.coverImageUrl,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ActionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ActionItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'help',
      redirectUrl: data['redirectUrl'],
      redirectRoute: data['redirectRoute'],
      coverImageUrl: data['coverImageUrl'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'redirectUrl': redirectUrl,
      'redirectRoute': redirectRoute,
      'coverImageUrl': coverImageUrl,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  ActionItem copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? redirectUrl,
    String? redirectRoute,
    String? coverImageUrl,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      redirectRoute: redirectRoute ?? this.redirectRoute,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'ActionItem(id: $id, title: $title, description: $description)';
  }
}
