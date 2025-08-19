class Sermon {
  final String id;
  final String title;
  final String date;
  final String? location;
  final String? content;
  final int? year;
  bool isFavorite;
  double readingProgress;
  String? notes;

  Sermon({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.content,
    this.year,
    this.isFavorite = false,
    this.readingProgress = 0.0,
    this.notes,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      location: json['location'],
      content: json['content'],
      year: json['year'],
      isFavorite: json['isFavorite'] ?? false,
      readingProgress: (json['readingProgress'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'content': content,
      'year': year,
      'isFavorite': isFavorite,
      'readingProgress': readingProgress,
      'notes': notes,
    };
  }
}
