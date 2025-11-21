import 'package:cloud_firestore/cloud_firestore.dart';

class Sermon {
  final String id;
  final String titre;
  final String orateur;
  final DateTime date;
  final String? lienYoutube;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String? description;
  final int duree; // durée en minutes
  final List<String> tags;
  final List<String> infographiesUrls; // URLs des schémas et infographies

  Sermon({
    required this.id,
    required this.titre,
    required this.orateur,
    required this.date,
    this.lienYoutube,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.description,
    this.duree = 0,
    this.tags = const [],
    this.infographiesUrls = const [],
  });

  factory Sermon.fromMap(Map<String, dynamic> map, String id) {
    return Sermon(
      id: id,
      titre: map['titre'] ?? '',
      orateur: map['orateur'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lienYoutube: map['lienYoutube'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      imageUrl: map['imageUrl'],
      description: map['description'],
      duree: map['duree'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      infographiesUrls: List<String>.from(map['infographiesUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'orateur': orateur,
      'date': Timestamp.fromDate(date),
      'lienYoutube': lienYoutube,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'description': description,
      'duree': duree,
      'tags': tags,
      'infographiesUrls': infographiesUrls,
    };
  }

  Sermon copyWith({
    String? id,
    String? titre,
    String? orateur,
    DateTime? date,
    String? lienYoutube,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? description,
    int? duree,
    List<String>? tags,
    List<String>? infographiesUrls,
  }) {
    return Sermon(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      orateur: orateur ?? this.orateur,
      date: date ?? this.date,
      lienYoutube: lienYoutube ?? this.lienYoutube,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      duree: duree ?? this.duree,
      tags: tags ?? this.tags,
      infographiesUrls: infographiesUrls ?? this.infographiesUrls,
    );
  }
}
