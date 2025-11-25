/// Modèle représentant un sermon de William Branham
/// Inspiré de La Table VGR et MessageHub
class WBSermon {
  final String id;
  final String title;
  final String date; // Format: "63-0317E"
  final String location;
  final String language; // "fr", "en", etc.
  final String? translator; // "VGR" ou "SHP"
  final int? durationMinutes;
  
  // URLs des ressources
  final String? pdfUrl;
  final String? audioUrl;
  final String? videoUrl;
  
  // Contenu du sermon
  final String? textContent; // Texte complet du sermon en HTML
  
  // Métadonnées
  final List<String> series;
  final String? description;
  final DateTime? publishedDate;
  final bool isFavorite;

  const WBSermon({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.language,
    this.translator,
    this.durationMinutes,
    this.pdfUrl,
    this.audioUrl,
    this.videoUrl,
    this.textContent,
    this.series = const [],
    this.description,
    this.publishedDate,
    this.isFavorite = false,
  });

  factory WBSermon.fromJson(Map<String, dynamic> json) {
    return WBSermon(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      language: json['language'] as String? ?? 'fr',
      translator: json['translator'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      pdfUrl: json['pdfUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      textContent: json['textContent'] as String?,
      series: (json['series'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      description: json['description'] as String?,
      publishedDate: json['publishedDate'] != null 
          ? DateTime.tryParse(json['publishedDate'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'language': language,
      'translator': translator,
      'durationMinutes': durationMinutes,
      'pdfUrl': pdfUrl,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'textContent': textContent,
      'series': series,
      'description': description,
      'publishedDate': publishedDate?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  WBSermon copyWith({
    String? id,
    String? title,
    String? date,
    String? location,
    String? language,
    String? translator,
    int? durationMinutes,
    String? pdfUrl,
    String? audioUrl,
    String? videoUrl,
    String? textContent,
    List<String>? series,
    String? description,
    DateTime? publishedDate,
    bool? isFavorite,
  }) {
    return WBSermon(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      language: language ?? this.language,
      translator: translator ?? this.translator,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      textContent: textContent ?? this.textContent,
      series: series ?? this.series,
      description: description ?? this.description,
      publishedDate: publishedDate ?? this.publishedDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Extrait l'année du date code (ex: "63-0317E" -> 1963)
  int get year {
    final yearStr = date.split('-').first;
    final year = int.tryParse(yearStr) ?? 0;
    return year < 100 ? (year < 50 ? 2000 + year : 1900 + year) : year;
  }

  /// Retourne un titre formaté avec la date
  String get displayTitle => '$title ($date)';
}
