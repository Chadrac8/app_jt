import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une citation dans une pépite d'or
class CitationModel {
  final String id;
  final String texte;
  final String auteur;
  final String? reference; // Référence biblique ou livre
  final int ordre;

  CitationModel({
    required this.id,
    required this.texte,
    required this.auteur,
    this.reference,
    required this.ordre,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'texte': texte,
      'auteur': auteur,
      'reference': reference,
      'ordre': ordre,
    };
  }

  factory CitationModel.fromFirestore(Map<String, dynamic> data) {
    return CitationModel(
      id: data['id'] ?? '',
      texte: data['texte'] ?? '',
      auteur: data['auteur'] ?? '',
      reference: data['reference'],
      ordre: data['ordre'] ?? 0,
    );
  }

  CitationModel copyWith({
    String? id,
    String? texte,
    String? auteur,
    String? reference,
    int? ordre,
  }) {
    return CitationModel(
      id: id ?? this.id,
      texte: texte ?? this.texte,
      auteur: auteur ?? this.auteur,
      reference: reference ?? this.reference,
      ordre: ordre ?? this.ordre,
    );
  }
}

/// Modèle pour une pépite d'or
class PepiteOrModel {
  final String id;
  final String theme;
  final String description;
  final List<CitationModel> citations;
  final DateTime dateCreation;
  final DateTime? datePublication;
  final String auteur; // ID de l'auteur
  final String nomAuteur; // Nom d'affichage de l'auteur
  final bool estPubliee;
  final bool estFavorite; // Pour les membres
  final int nbVues;
  final int nbPartages;
  final List<String> tags;
  final String? imageUrl;

  PepiteOrModel({
    required this.id,
    required this.theme,
    required this.description,
    required this.citations,
    required this.dateCreation,
    this.datePublication,
    required this.auteur,
    required this.nomAuteur,
    this.estPubliee = false,
    this.estFavorite = false,
    this.nbVues = 0,
    this.nbPartages = 0,
    this.tags = const [],
    this.imageUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'theme': theme,
      'description': description,
      'citations': citations.map((c) => c.toFirestore()).toList(),
      'dateCreation': Timestamp.fromDate(dateCreation),
      'datePublication': datePublication != null 
          ? Timestamp.fromDate(datePublication!) 
          : null,
      'auteur': auteur,
      'nomAuteur': nomAuteur,
      'estPubliee': estPubliee,
      'estFavorite': estFavorite,
      'nbVues': nbVues,
      'nbPartages': nbPartages,
      'tags': tags,
      'imageUrl': imageUrl,
    };
  }

  factory PepiteOrModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final citationsList = data['citations'] as List<dynamic>? ?? [];
    final citations = citationsList
        .map((c) => CitationModel.fromFirestore(c as Map<String, dynamic>))
        .toList();

    return PepiteOrModel(
      id: doc.id,
      theme: data['theme'] ?? '',
      description: data['description'] ?? '',
      citations: citations,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      datePublication: (data['datePublication'] as Timestamp?)?.toDate(),
      auteur: data['auteur'] ?? '',
      nomAuteur: data['nomAuteur'] ?? '',
      estPubliee: data['estPubliee'] ?? false,
      estFavorite: data['estFavorite'] ?? false,
      nbVues: data['nbVues'] ?? 0,
      nbPartages: data['nbPartages'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
    );
  }

  PepiteOrModel copyWith({
    String? id,
    String? theme,
    String? description,
    List<CitationModel>? citations,
    DateTime? dateCreation,
    DateTime? datePublication,
    String? auteur,
    String? nomAuteur,
    bool? estPubliee,
    bool? estFavorite,
    int? nbVues,
    int? nbPartages,
    List<String>? tags,
    String? imageUrl,
  }) {
    return PepiteOrModel(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      description: description ?? this.description,
      citations: citations ?? this.citations,
      dateCreation: dateCreation ?? this.dateCreation,
      datePublication: datePublication ?? this.datePublication,
      auteur: auteur ?? this.auteur,
      nomAuteur: nomAuteur ?? this.nomAuteur,
      estPubliee: estPubliee ?? this.estPubliee,
      estFavorite: estFavorite ?? this.estFavorite,
      nbVues: nbVues ?? this.nbVues,
      nbPartages: nbPartages ?? this.nbPartages,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Résumé de la première citation pour l'aperçu
  String get premiereCitation {
    if (citations.isEmpty) return '';
    return citations.first.texte.length > 100 
        ? '${citations.first.texte.substring(0, 100)}...'
        : citations.first.texte;
  }

  /// Nom du premier auteur pour l'aperçu
  String get premierAuteur {
    if (citations.isEmpty) return '';
    return citations.first.auteur;
  }

  /// Durée de lecture estimée (basée sur le nombre de mots)
  int get dureeDeeLectureMinutes {
    final totalMots = citations.fold<int>(0, (sum, citation) {
      return sum + citation.texte.split(' ').length;
    });
    return (totalMots / 200).ceil(); // ~200 mots par minute
  }
}
