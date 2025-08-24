import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour le pain quotidien récupéré depuis branham.org
class DailyBreadModel {
  final String id;
  final String text;
  final String reference;
  final String date;
  final String dailyBread; // Pain quotidien (verset biblique)
  final String dailyBreadReference; // Référence du verset biblique
  final String sermonTitle; // Titre de la prédication
  final String sermonDate; // Date de la prédication
  final String audioUrl; // URL du fichier audio M4A
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyBreadModel({
    required this.id,
    required this.text,
    required this.reference,
    required this.date,
    required this.dailyBread,
    required this.dailyBreadReference,
    this.sermonTitle = '',
    this.sermonDate = '',
    this.audioUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'reference': reference,
      'date': date,
      'dailyBread': dailyBread,
      'dailyBreadReference': dailyBreadReference,
      'sermonTitle': sermonTitle,
      'sermonDate': sermonDate,
      'audioUrl': audioUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Création depuis Map Firestore
  factory DailyBreadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyBreadModel(
      id: doc.id,
      text: data['text'] ?? '',
      reference: data['reference'] ?? '',
      date: data['date'] ?? '',
      dailyBread: data['dailyBread'] ?? '',
      dailyBreadReference: data['dailyBreadReference'] ?? '',
      sermonTitle: data['sermonTitle'] ?? '',
      sermonDate: data['sermonDate'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Conversion vers JSON pour cache local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'reference': reference,
      'date': date,
      'dailyBread': dailyBread,
      'dailyBreadReference': dailyBreadReference,
      'sermonTitle': sermonTitle,
      'sermonDate': sermonDate,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Création depuis JSON pour cache local
  factory DailyBreadModel.fromJson(Map<String, dynamic> json) {
    return DailyBreadModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      reference: json['reference'] ?? '',
      date: json['date'] ?? '',
      dailyBread: json['dailyBread'] ?? '',
      dailyBreadReference: json['dailyBreadReference'] ?? '',
      sermonTitle: json['sermonTitle'] ?? '',
      sermonDate: json['sermonDate'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Copie avec modifications
  DailyBreadModel copyWith({
    String? id,
    String? text,
    String? reference,
    String? date,
    String? dailyBread,
    String? dailyBreadReference,
    String? sermonTitle,
    String? sermonDate,
    String? audioUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyBreadModel(
      id: id ?? this.id,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      dailyBread: dailyBread ?? this.dailyBread,
      dailyBreadReference: dailyBreadReference ?? this.dailyBreadReference,
      sermonTitle: sermonTitle ?? this.sermonTitle,
      sermonDate: sermonDate ?? this.sermonDate,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérification si c'est le contenu d'aujourd'hui
  bool get isToday {
    try {
      final quoteDate = DateTime.parse(date);
      final today = DateTime.now();
      return quoteDate.year == today.year &&
             quoteDate.month == today.month &&
             quoteDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  /// Texte formaté pour le partage
  String get shareText {
    return '''
📖 Pain quotidien - $date

VERSET DU JOUR :
$dailyBread
$dailyBreadReference

CITATION DU JOUR :
"$text"
${sermonTitle.isNotEmpty ? '\n$sermonTitle' : ''}
William Marrion Branham

Source : www.branham.org
''';
  }
}
