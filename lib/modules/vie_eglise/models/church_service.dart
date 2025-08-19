import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les services de l'église
class ChurchService {
  final String id;
  final String title;
  final String description;
  final String? content;
  final String serviceType; // 'worship', 'prayer', 'bible_study', 'special', 'youth', 'children'
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String? location;
  final String? pastor;
  final String? imageUrl;
  final bool isActive;
  final bool isRecurring; // Service récurrent (ex: tous les dimanches)
  final String? recurrencePattern; // 'weekly', 'monthly', 'yearly'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final List<String> tags;
  final int attendanceCount;

  ChurchService({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.serviceType = 'worship',
    this.scheduleDate,
    this.scheduleTime,
    this.location,
    this.pastor,
    this.imageUrl,
    this.isActive = true,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.tags = const [],
    this.attendanceCount = 0,
  });

  factory ChurchService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChurchService(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      serviceType: data['serviceType'] ?? 'worship',
      scheduleDate: (data['scheduleDate'] as Timestamp?)?.toDate(),
      scheduleTime: data['scheduleTime'],
      location: data['location'],
      pastor: data['pastor'],
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      tags: List<String>.from(data['tags'] ?? []),
      attendanceCount: data['attendanceCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'serviceType': serviceType,
      'scheduleDate': scheduleDate != null ? Timestamp.fromDate(scheduleDate!) : null,
      'scheduleTime': scheduleTime,
      'location': location,
      'pastor': pastor,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'tags': tags,
      'attendanceCount': attendanceCount,
    };
  }

  ChurchService copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? serviceType,
    DateTime? scheduleDate,
    String? scheduleTime,
    String? location,
    String? pastor,
    String? imageUrl,
    bool? isActive,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? tags,
    int? attendanceCount,
  }) {
    return ChurchService(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      serviceType: serviceType ?? this.serviceType,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      location: location ?? this.location,
      pastor: pastor ?? this.pastor,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      attendanceCount: attendanceCount ?? this.attendanceCount,
    );
  }
}

/// Types de services disponibles
enum ServiceType {
  worship('worship', 'Culte', 'Services de culte et louange'),
  prayer('prayer', 'Prière', 'Réunions de prière'),
  bibleStudy('bible_study', 'Étude biblique', 'Études de la Bible'),
  special('special', 'Service spécial', 'Services spéciaux et événements'),
  youth('youth', 'Jeunesse', 'Services pour les jeunes'),
  children('children', 'Enfants', 'Services pour les enfants'),
  conference('conference', 'Conférence', 'Conférences et séminaires'),
  evangelism('evangelism', 'Évangélisation', 'Services d\'évangélisation');

  const ServiceType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ServiceType fromValue(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ServiceType.worship,
    );
  }
}

/// Modèles de récurrence pour les services
enum RecurrencePattern {
  weekly('weekly', 'Hebdomadaire', 'Chaque semaine'),
  biweekly('biweekly', 'Bi-hebdomadaire', 'Toutes les deux semaines'),
  monthly('monthly', 'Mensuel', 'Chaque mois'),
  yearly('yearly', 'Annuel', 'Chaque année');

  const RecurrencePattern(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static RecurrencePattern fromValue(String value) {
    return RecurrencePattern.values.firstWhere(
      (pattern) => pattern.value == value,
      orElse: () => RecurrencePattern.weekly,
    );
  }
}
