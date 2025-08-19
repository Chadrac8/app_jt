class BranhamMessage {
  final String id;
  final String title;
  final String date;
  final String location;
  final int durationMinutes;
  final String pdfUrl;
  final String audioUrl;
  final String streamUrl;
  final String language;
  final DateTime publishDate;
  final List<String> series;

  BranhamMessage({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.durationMinutes,
    required this.pdfUrl,
    required this.audioUrl,
    required this.streamUrl,
    required this.language,
    required this.publishDate,
    this.series = const [],
  });

  factory BranhamMessage.fromJson(Map<String, dynamic> json) {
    return BranhamMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      pdfUrl: json['pdfUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
      language: json['language'] ?? 'FRN',
      publishDate: DateTime.tryParse(json['publishDate'] ?? '') ?? DateTime.now(),
      series: List<String>.from(json['series'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'durationMinutes': durationMinutes,
      'pdfUrl': pdfUrl,
      'audioUrl': audioUrl,
      'streamUrl': streamUrl,
      'language': language,
      'publishDate': publishDate.toIso8601String(),
      'series': series,
    };
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String get formattedDate {
    final parts = date.split('-');
    if (parts.length >= 2) {
      final year = parts[0];
      final month = parts[1];
      final day = parts.length > 2 ? parts[2] : '01';
      
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      
      final monthIndex = int.tryParse(month) ?? 1;
      final monthName = monthIndex > 0 && monthIndex <= 12 
          ? months[monthIndex - 1] 
          : month;
      
      return '$day $monthName $year';
    }
    return date;
  }

  int get year {
    final parts = date.split('-');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  String get decade {
    final messageYear = year;
    if (messageYear >= 1950 && messageYear < 1960) return '1950s';
    if (messageYear >= 1960 && messageYear < 1970) return '1960s';
    return 'Autre';
  }
}
