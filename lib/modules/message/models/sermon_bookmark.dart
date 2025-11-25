import 'dart:typed_data';

/// Modèle représentant un signet (bookmark) dans un sermon
class SermonBookmark {
  final String id;
  final String sermonId;
  final String title;
  final String? description;
  final int pageNumber; // Pour PDF
  final int? position; // Position en millisecondes pour audio/vidéo
  final String? thumbnailBase64; // Miniature encodée en base64
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SermonBookmark({
    required this.id,
    required this.sermonId,
    required this.title,
    this.description,
    required this.pageNumber,
    this.position,
    this.thumbnailBase64,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory SermonBookmark.fromJson(Map<String, dynamic> json) {
    return SermonBookmark(
      id: json['id'] as String,
      sermonId: json['sermonId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      pageNumber: json['pageNumber'] as int,
      position: json['position'] as int?,
      thumbnailBase64: json['thumbnailBase64'] as String?,
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
      'description': description,
      'pageNumber': pageNumber,
      'position': position,
      'thumbnailBase64': thumbnailBase64,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SermonBookmark copyWith({
    String? id,
    String? sermonId,
    String? title,
    String? description,
    int? pageNumber,
    int? position,
    String? thumbnailBase64,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SermonBookmark(
      id: id ?? this.id,
      sermonId: sermonId ?? this.sermonId,
      title: title ?? this.title,
      description: description ?? this.description,
      pageNumber: pageNumber ?? this.pageNumber,
      position: position ?? this.position,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Décode la miniature si elle existe
  Uint8List? get thumbnailBytes {
    if (thumbnailBase64 == null || thumbnailBase64!.isEmpty) {
      return null;
    }
    try {
      return Uint8List.fromList(thumbnailBase64!.codeUnits);
    } catch (e) {
      return null;
    }
  }

  /// Formatte la position en temps lisible (pour audio/vidéo)
  String get formattedPosition {
    if (position == null) return '';
    
    final duration = Duration(milliseconds: position!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  /// Formatte la page
  String get formattedPage => 'Page $pageNumber';
}
