import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les éléments de la vie de l'église
class ChurchLifeItem {
  final String id;
  final String title;
  final String description;
  final String? content; // Contenu détaillé
  final String? imageUrl;
  final String category; // 'announcement', 'news', 'testimony', 'ministry'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final DateTime? publishDate;
  final List<String> tags;
  final int priority; // Pour l'ordre d'affichage

  ChurchLifeItem({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.imageUrl,
    this.category = 'news',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.publishDate,
    this.tags = const [],
    this.priority = 0,
  });

  factory ChurchLifeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChurchLifeItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'news',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      publishDate: (data['publishDate'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      priority: data['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'publishDate': publishDate != null ? Timestamp.fromDate(publishDate!) : null,
      'tags': tags,
      'priority': priority,
    };
  }

  ChurchLifeItem copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? imageUrl,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? publishDate,
    List<String>? tags,
    int? priority,
  }) {
    return ChurchLifeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      publishDate: publishDate ?? this.publishDate,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }
}

/// Catégories disponibles pour les éléments de vie d'église
enum ChurchLifeCategory {
  announcement('announcement', 'Annonces', 'Annonces importantes de l\'église'),
  news('news', 'Actualités', 'Nouvelles et événements récents'),
  testimony('testimony', 'Témoignages', 'Témoignages des membres'),
  ministry('ministry', 'Ministères', 'Informations sur les ministères'),
  event('event', 'Événements', 'Événements spéciaux'),
  prayer('prayer', 'Prière', 'Demandes et sujets de prière');

  const ChurchLifeCategory(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ChurchLifeCategory fromValue(String value) {
    return ChurchLifeCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ChurchLifeCategory.news,
    );
  }
}
