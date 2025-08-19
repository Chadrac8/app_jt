import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un élément de ressource
class ResourceItem {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String? redirectUrl;
  final String? redirectRoute;
  final String? coverImageUrl;
  final bool isActive;
  final int order;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.redirectUrl,
    this.redirectRoute,
    this.coverImageUrl,
    this.isActive = true,
    this.order = 0,
    this.category = 'general',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory ResourceItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'library_books',
      redirectUrl: data['redirectUrl'],
      redirectRoute: data['redirectRoute'],
      coverImageUrl: data['coverImageUrl'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      category: data['category'] ?? 'general',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir vers Map pour Firestore
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
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Copier avec modifications
  ResourceItem copyWith({
    String? title,
    String? description,
    String? iconName,
    String? redirectUrl,
    String? redirectRoute,
    String? coverImageUrl,
    bool? isActive,
    int? order,
    String? category,
  }) {
    return ResourceItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      redirectRoute: redirectRoute ?? this.redirectRoute,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Vérifier si la ressource a une redirection
  bool get hasRedirect => redirectUrl != null || redirectRoute != null;

  /// Obtenir l'URL ou la route de redirection
  String? get redirectTarget => redirectUrl ?? redirectRoute;

  /// Vérifier si c'est une redirection externe
  bool get isExternalRedirect => redirectUrl != null && redirectUrl!.startsWith('http');

  @override
  String toString() {
    return 'ResourceItem(id: $id, title: $title, isActive: $isActive)';
  }
}
