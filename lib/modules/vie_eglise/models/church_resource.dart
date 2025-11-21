import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les ressources de l'église
class ChurchResource {
  final String id;
  final String title;
  final String description;
  final String? content;
  final String? fileUrl;
  final String? imageUrl;
  final String resourceType; // 'document', 'video', 'audio', 'link'
  final String category; // 'formation', 'worship', 'bible', 'prayer', 'ministry'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final List<String> tags;
  final int downloadCount;
  final double? fileSizeMB;

  ChurchResource({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.fileUrl,
    this.imageUrl,
    this.resourceType = 'document',
    this.category = 'formation',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.tags = const [],
    this.downloadCount = 0,
    this.fileSizeMB,
  });

  factory ChurchResource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChurchResource(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      fileUrl: data['fileUrl'],
      imageUrl: data['imageUrl'],
      resourceType: data['resourceType'] ?? 'document',
      category: data['category'] ?? 'formation',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      tags: List<String>.from(data['tags'] ?? []),
      downloadCount: data['downloadCount'] ?? 0,
      fileSizeMB: data['fileSizeMB']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'fileUrl': fileUrl,
      'imageUrl': imageUrl,
      'resourceType': resourceType,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'tags': tags,
      'downloadCount': downloadCount,
      'fileSizeMB': fileSizeMB,
    };
  }

  ChurchResource copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? fileUrl,
    String? imageUrl,
    String? resourceType,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? tags,
    int? downloadCount,
    double? fileSizeMB,
  }) {
    return ChurchResource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      resourceType: resourceType ?? this.resourceType,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      downloadCount: downloadCount ?? this.downloadCount,
      fileSizeMB: fileSizeMB ?? this.fileSizeMB,
    );
  }
}

/// Types de ressources disponibles
enum ResourceType {
  document('document', 'Document', 'Documents PDF, Word, etc.'),
  video('video', 'Vidéo', 'Vidéos et enregistrements'),
  audio('audio', 'Audio', 'Enregistrements audio et podcasts'),
  link('link', 'Lien', 'Liens vers des ressources externes');

  const ResourceType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ResourceType fromValue(String value) {
    return ResourceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ResourceType.document,
    );
  }
}

/// Catégories de ressources disponibles
enum ResourceCategory {
  formation('formation', 'Formation', 'Ressources de formation et d\'enseignement'),
  worship('worship', 'Culte', 'Ressources pour le culte et la louange'),
  bible('bible', 'Bible', 'Études bibliques et commentaires'),
  prayer('prayer', 'Prière', 'Ressources pour la prière'),
  ministry('ministry', 'Ministère', 'Ressources pour les ministères'),
  youth('youth', 'Jeunesse', 'Ressources pour les jeunes'),
  children('children', 'Enfants', 'Ressources pour les enfants'),
  evangelism('evangelism', 'Évangélisation', 'Ressources d\'évangélisation');

  const ResourceCategory(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ResourceCategory fromValue(String value) {
    return ResourceCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ResourceCategory.formation,
    );
  }
}
