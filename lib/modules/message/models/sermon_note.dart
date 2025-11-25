/// Modèle représentant une note personnelle sur un sermon
class SermonNote {
  final String id;
  final String sermonId;
  final String title;
  final String content;
  final int? pageNumber; // Numéro de page de référence
  final String? referenceText; // Texte de référence du sermon
  final List<String> tags; // Tags personnels
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SermonNote({
    required this.id,
    required this.sermonId,
    required this.title,
    required this.content,
    this.pageNumber,
    this.referenceText,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    return SermonNote(
      id: json['id'] as String,
      sermonId: json['sermonId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int?,
      referenceText: json['referenceText'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sermonId': sermonId,
      'title': title,
      'content': content,
      'pageNumber': pageNumber,
      'referenceText': referenceText,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SermonNote copyWith({
    String? id,
    String? sermonId,
    String? title,
    String? content,
    int? pageNumber,
    String? referenceText,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SermonNote(
      id: id ?? this.id,
      sermonId: sermonId ?? this.sermonId,
      title: title ?? this.title,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      referenceText: referenceText ?? this.referenceText,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne un aperçu du contenu (premiers 100 caractères)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }
}
