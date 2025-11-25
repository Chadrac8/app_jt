/// Modèle représentant un surlignement dans un sermon
class SermonHighlight {
  final String id;
  final String sermonId;
  final String text;
  final String? color; // Couleur du surlignement (hex)
  final int? startPosition; // Position de début dans le texte
  final int? endPosition; // Position de fin dans le texte
  final int? pageNumber; // Numéro de page (pour PDF)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SermonHighlight({
    required this.id,
    required this.sermonId,
    required this.text,
    this.color,
    this.startPosition,
    this.endPosition,
    this.pageNumber,
    required this.createdAt,
    this.updatedAt,
  });

  factory SermonHighlight.fromJson(Map<String, dynamic> json) {
    return SermonHighlight(
      id: json['id'] as String,
      sermonId: json['sermonId'] as String,
      text: json['text'] as String,
      color: json['color'] as String?,
      startPosition: json['startPosition'] as int?,
      endPosition: json['endPosition'] as int?,
      pageNumber: json['pageNumber'] as int?,
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
      'text': text,
      'color': color,
      'startPosition': startPosition,
      'endPosition': endPosition,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SermonHighlight copyWith({
    String? id,
    String? sermonId,
    String? text,
    String? color,
    int? startPosition,
    int? endPosition,
    int? pageNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SermonHighlight(
      id: id ?? this.id,
      sermonId: sermonId ?? this.sermonId,
      text: text ?? this.text,
      color: color ?? this.color,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
