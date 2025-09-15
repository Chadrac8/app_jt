import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour la récurrence d'événements inspiré de Planning Center Online
class EventRecurrenceModel {
  final String id;
  final String parentEventId;
  final RecurrenceType type;
  final int interval; // ex: tous les 2 semaines
  final List<int>? daysOfWeek; // 1-7 (Lundi-Dimanche) pour récurrence hebdomadaire
  final int? dayOfMonth; // 1-31 pour récurrence mensuelle
  final List<int>? monthsOfYear; // 1-12 pour récurrence annuelle
  final DateTime? endDate; // Date de fin de la récurrence
  final int? occurrenceCount; // Nombre d'occurrences max
  final List<DateTime> exceptions; // Dates à exclure
  final List<RecurrenceOverride> overrides; // Modifications spécifiques à certaines dates
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventRecurrenceModel({
    required this.id,
    required this.parentEventId,
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.monthsOfYear,
    this.endDate,
    this.occurrenceCount,
    this.exceptions = const [],
    this.overrides = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Génère les prochaines occurrences de l'événement
  List<DateTime> generateOccurrences({
    required DateTime startDate,
    DateTime? until,
    int? maxCount,
  }) {
    final occurrences = <DateTime>[];
    var currentDate = startDate;
    final endLimit = until ?? endDate ?? DateTime.now().add(const Duration(days: 365));
    final countLimit = maxCount ?? occurrenceCount ?? 100;

    switch (type) {
      case RecurrenceType.daily:
        while (currentDate.isBefore(endLimit) && occurrences.length < countLimit) {
          if (!exceptions.contains(currentDate)) {
            occurrences.add(currentDate);
          }
          currentDate = currentDate.add(Duration(days: interval));
        }
        break;

      case RecurrenceType.weekly:
        while (currentDate.isBefore(endLimit) && occurrences.length < countLimit) {
          if (daysOfWeek?.contains(currentDate.weekday) == true && !exceptions.contains(currentDate)) {
            occurrences.add(currentDate);
          }
          currentDate = currentDate.add(const Duration(days: 1));
          
          // Passer à la semaine suivante si nécessaire
          if (currentDate.weekday == 1 && interval > 1) {
            currentDate = currentDate.add(Duration(days: 7 * (interval - 1)));
          }
        }
        break;

      case RecurrenceType.monthly:
        while (currentDate.isBefore(endLimit) && occurrences.length < countLimit) {
          final targetDate = _getMonthlyDate(currentDate, dayOfMonth);
          if (targetDate != null && !exceptions.contains(targetDate)) {
            occurrences.add(targetDate);
          }
          currentDate = DateTime(currentDate.year, currentDate.month + interval, 1);
        }
        break;

      case RecurrenceType.yearly:
        while (currentDate.isBefore(endLimit) && occurrences.length < countLimit) {
          if (monthsOfYear?.contains(currentDate.month) == true && !exceptions.contains(currentDate)) {
            occurrences.add(currentDate);
          }
          currentDate = DateTime(currentDate.year + interval, currentDate.month, currentDate.day);
        }
        break;

      case RecurrenceType.custom:
        // Logique personnalisée basée sur les paramètres spécifiques
        break;
    }

    return occurrences;
  }

  DateTime? _getMonthlyDate(DateTime baseDate, int? targetDay) {
    if (targetDay == null) return null;
    
    try {
      return DateTime(baseDate.year, baseDate.month, targetDay);
    } catch (e) {
      // Si le jour n'existe pas dans ce mois (ex: 31 février), prendre le dernier jour du mois
      final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0).day;
      return DateTime(baseDate.year, baseDate.month, lastDay);
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentEventId': parentEventId,
      'type': type.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'monthsOfYear': monthsOfYear,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'occurrenceCount': occurrenceCount,
      'exceptions': exceptions.map((date) => Timestamp.fromDate(date)).toList(),
      'overrides': overrides.map((override) => override.toFirestore()).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EventRecurrenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventRecurrenceModel(
      id: doc.id,
      parentEventId: data['parentEventId'] ?? '',
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecurrenceType.daily,
      ),
      interval: data['interval'] ?? 1,
      daysOfWeek: data['daysOfWeek']?.cast<int>(),
      dayOfMonth: data['dayOfMonth'],
      monthsOfYear: data['monthsOfYear']?.cast<int>(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      occurrenceCount: data['occurrenceCount'],
      exceptions: (data['exceptions'] as List<dynamic>?)
          ?.map((timestamp) => (timestamp as Timestamp).toDate())
          .toList() ?? [],
      overrides: (data['overrides'] as List<dynamic>?)
          ?.map((override) => RecurrenceOverride.fromFirestore(override))
          .toList() ?? [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  EventRecurrenceModel copyWith({
    String? parentEventId,
    RecurrenceType? type,
    int? interval,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    List<int>? monthsOfYear,
    DateTime? endDate,
    int? occurrenceCount,
    List<DateTime>? exceptions,
    List<RecurrenceOverride>? overrides,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return EventRecurrenceModel(
      id: id,
      parentEventId: parentEventId ?? this.parentEventId,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthsOfYear: monthsOfYear ?? this.monthsOfYear,
      endDate: endDate ?? this.endDate,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      exceptions: exceptions ?? this.exceptions,
      overrides: overrides ?? this.overrides,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Types de récurrence disponibles
enum RecurrenceType {
  daily,    // Quotidien
  weekly,   // Hebdomadaire
  monthly,  // Mensuel
  yearly,   // Annuel
  custom,   // Personnalisé
}

/// Modèle pour les modifications spécifiques d'une occurrence
class RecurrenceOverride {
  final DateTime originalDate;
  final DateTime? newDate; // null si l'occurrence est annulée
  final String? title;
  final String? description;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic> customFields;

  RecurrenceOverride({
    required this.originalDate,
    this.newDate,
    this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.customFields = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'originalDate': Timestamp.fromDate(originalDate),
      'newDate': newDate != null ? Timestamp.fromDate(newDate!) : null,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'customFields': customFields,
    };
  }

  factory RecurrenceOverride.fromFirestore(Map<String, dynamic> data) {
    return RecurrenceOverride(
      originalDate: (data['originalDate'] as Timestamp).toDate(),
      newDate: data['newDate'] != null ? (data['newDate'] as Timestamp).toDate() : null,
      title: data['title'],
      description: data['description'],
      location: data['location'],
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : null,
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }
}

/// Modèle pour une instance d'événement récurrent
class EventInstanceModel {
  final String id;
  final String parentEventId;
  final String? recurrenceId;
  final DateTime originalDate;
  final DateTime actualDate;
  final bool isOverride;
  final bool isCancelled;
  final Map<String, dynamic> overrideData;
  final DateTime createdAt;

  EventInstanceModel({
    required this.id,
    required this.parentEventId,
    this.recurrenceId,
    required this.originalDate,
    required this.actualDate,
    this.isOverride = false,
    this.isCancelled = false,
    this.overrideData = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'parentEventId': parentEventId,
      'recurrenceId': recurrenceId,
      'originalDate': Timestamp.fromDate(originalDate),
      'actualDate': Timestamp.fromDate(actualDate),
      'isOverride': isOverride,
      'isCancelled': isCancelled,
      'overrideData': overrideData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EventInstanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventInstanceModel(
      id: doc.id,
      parentEventId: data['parentEventId'] ?? '',
      recurrenceId: data['recurrenceId'],
      originalDate: (data['originalDate'] as Timestamp).toDate(),
      actualDate: (data['actualDate'] as Timestamp).toDate(),
      isOverride: data['isOverride'] ?? false,
      isCancelled: data['isCancelled'] ?? false,
      overrideData: Map<String, dynamic>.from(data['overrideData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
