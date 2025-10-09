import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_recurrence_model.dart';

/// Enum pour définir les types de fréquence de récurrence
enum RecurrenceFrequency {
  daily,
  weekly, 
  monthly,
  yearly
}

/// Enum pour définir le type de fin de récurrence
enum RecurrenceEndType {
  never,
  afterOccurrences,
  onDate
}

/// Enum pour les jours de la semaine
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

/// Classe pour gérer la récurrence des événements
class EventRecurrence {
  final RecurrenceFrequency frequency;
  final int interval; // ex: tous les 2 semaines = interval 2
  final List<WeekDay>? daysOfWeek; // pour récurrence weekly/monthly
  final int? dayOfMonth; // pour récurrence monthly (1-31)
  final int? weekOfMonth; // pour récurrence monthly (1-5, première/deuxième/etc. semaine)
  final int? monthOfYear; // pour récurrence yearly (1-12)
  final RecurrenceEndType endType;
  final int? occurrences; // nombre d'occurrences si endType = afterOccurrences
  final DateTime? endDate; // date de fin si endType = onDate
  final List<DateTime> exceptions; // dates à exclure

  const EventRecurrence({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.monthOfYear,
    this.endType = RecurrenceEndType.never,
    this.occurrences,
    this.endDate,
    this.exceptions = const [],
  });

  /// Factory pour créer une récurrence quotidienne
  factory EventRecurrence.daily({
    int interval = 1,
    RecurrenceEndType endType = RecurrenceEndType.never,
    int? occurrences,
    DateTime? endDate,
    List<DateTime> exceptions = const [],
  }) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.daily,
      interval: interval,
      endType: endType,
      occurrences: occurrences,
      endDate: endDate,
      exceptions: exceptions,
    );
  }

  /// Factory pour créer une récurrence hebdomadaire
  factory EventRecurrence.weekly({
    int interval = 1,
    List<WeekDay> daysOfWeek = const [],
    RecurrenceEndType endType = RecurrenceEndType.never,
    int? occurrences,
    DateTime? endDate,
    List<DateTime> exceptions = const [],
  }) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.weekly,
      interval: interval,
      daysOfWeek: daysOfWeek,
      endType: endType,
      occurrences: occurrences,
      endDate: endDate,
      exceptions: exceptions,
    );
  }

  /// Factory pour créer une récurrence mensuelle
  factory EventRecurrence.monthly({
    int interval = 1,
    int? dayOfMonth,
    int? weekOfMonth,
    WeekDay? dayOfWeek,
    RecurrenceEndType endType = RecurrenceEndType.never,
    int? occurrences,
    DateTime? endDate,
    List<DateTime> exceptions = const [],
  }) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.monthly,
      interval: interval,
      dayOfMonth: dayOfMonth,
      weekOfMonth: weekOfMonth,
      daysOfWeek: dayOfWeek != null ? [dayOfWeek] : null,
      endType: endType,
      occurrences: occurrences,
      endDate: endDate,
      exceptions: exceptions,
    );
  }

  /// Factory pour créer une récurrence annuelle
  factory EventRecurrence.yearly({
    int interval = 1,
    int? monthOfYear,
    int? dayOfMonth,
    RecurrenceEndType endType = RecurrenceEndType.never,
    int? occurrences,
    DateTime? endDate,
    List<DateTime> exceptions = const [],
  }) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.yearly,
      interval: interval,
      monthOfYear: monthOfYear,
      dayOfMonth: dayOfMonth,
      endType: endType,
      occurrences: occurrences,
      endDate: endDate,
      exceptions: exceptions,
    );
  }

  /// Conversion depuis Firestore
  factory EventRecurrence.fromMap(Map<String, dynamic> map) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.toString().split('.').last == map['frequency'],
        orElse: () => RecurrenceFrequency.weekly,
      ),
      interval: map['interval'] ?? 1,
      daysOfWeek: map['daysOfWeek'] != null
          ? (map['daysOfWeek'] as List).map((day) =>
              WeekDay.values.firstWhere(
                (d) => d.toString().split('.').last == day,
                orElse: () => WeekDay.monday,
              )).toList()
          : null,
      dayOfMonth: map['dayOfMonth'],
      weekOfMonth: map['weekOfMonth'],
      monthOfYear: map['monthOfYear'],
      endType: RecurrenceEndType.values.firstWhere(
        (t) => t.toString().split('.').last == map['endType'],
        orElse: () => RecurrenceEndType.never,
      ),
      occurrences: map['occurrences'],
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
      exceptions: map['exceptions'] != null
          ? (map['exceptions'] as List).map((e) => (e as Timestamp).toDate()).toList()
          : [],
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.toString().split('.').last,
      'interval': interval,
      'daysOfWeek': daysOfWeek?.map((d) => d.toString().split('.').last).toList(),
      'dayOfMonth': dayOfMonth,
      'weekOfMonth': weekOfMonth,
      'monthOfYear': monthOfYear,
      'endType': endType.toString().split('.').last,
      'occurrences': occurrences,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'exceptions': exceptions.map((e) => Timestamp.fromDate(e)).toList(),
    };
  }

  /// Génère les dates d'occurrence pour une période donnée
  List<DateTime> generateOccurrences(
    DateTime startDate,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <DateTime>[];
    var currentDate = startDate;
    var count = 0;

    // Si on a une limite d'occurrences et qu'on l'a atteinte
    if (this.occurrences != null && count >= this.occurrences!) {
      return occurrences;
    }

    // Si on a une date de fin et qu'on l'a dépassée
    if (endDate != null && currentDate.isAfter(endDate!)) {
      return occurrences;
    }

    while (currentDate.isBefore(rangeEnd) || currentDate.isAtSameMomentAs(rangeEnd)) {
      // Vérifier si la date n'est pas dans les exceptions
      bool isException = exceptions.any((exception) =>
          currentDate.year == exception.year &&
          currentDate.month == exception.month &&
          currentDate.day == exception.day);

      if (!isException && 
          (currentDate.isAfter(rangeStart) || currentDate.isAtSameMomentAs(rangeStart))) {
        occurrences.add(currentDate);
        count++;
      }

      // Arrêter si on a atteint le nombre d'occurrences demandé
      if (this.occurrences != null && count >= this.occurrences!) {
        break;
      }

      // Arrêter si on a atteint la date de fin
      if (endDate != null && currentDate.isAfter(endDate!)) {
        break;
      }

      // Calculer la prochaine occurrence
      currentDate = _getNextOccurrence(currentDate);
      
      // Protection contre les boucles infinies
      if (currentDate.year > rangeEnd.year + 10) break;
    }

    return occurrences;
  }

  /// Calcule la prochaine occurrence selon la fréquence
  DateTime _getNextOccurrence(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: interval));
        
      case RecurrenceFrequency.weekly:
        if (daysOfWeek == null || daysOfWeek!.isEmpty) {
          return current.add(Duration(days: 7 * interval));
        }
        
        // Trouver le prochain jour de la semaine dans la liste
        var nextDate = current.add(const Duration(days: 1));
        while (!_isDayOfWeekMatch(nextDate)) {
          nextDate = nextDate.add(const Duration(days: 1));
          // Si on a fait le tour de la semaine sans trouver, passer à la semaine suivante
          if (nextDate.difference(current).inDays > 7) {
            nextDate = current.add(Duration(days: 7 * interval));
            while (!_isDayOfWeekMatch(nextDate)) {
              nextDate = nextDate.add(const Duration(days: 1));
            }
            break;
          }
        }
        return nextDate;
        
      case RecurrenceFrequency.monthly:
        if (dayOfMonth != null) {
          var nextMonth = DateTime(current.year, current.month + interval, dayOfMonth!);
          // Ajuster si le jour n'existe pas dans le mois (ex: 31 février)
          if (nextMonth.month != current.month + interval) {
            nextMonth = DateTime(current.year, current.month + interval + 1, 1);
            nextMonth = nextMonth.subtract(const Duration(days: 1));
          }
          return nextMonth;
        } else if (weekOfMonth != null && daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          // Ex: le 2ème lundi du mois
          var nextMonth = DateTime(current.year, current.month + interval, 1);
          return _getNthWeekdayOfMonth(nextMonth, weekOfMonth!, daysOfWeek!.first);
        }
        return DateTime(current.year, current.month + interval, current.day);
        
      case RecurrenceFrequency.yearly:
        return DateTime(current.year + interval, 
                       monthOfYear ?? current.month, 
                       dayOfMonth ?? current.day);
    }
  }

  /// Vérifie si une date correspond aux jours de la semaine définis
  bool _isDayOfWeekMatch(DateTime date) {
    if (daysOfWeek == null || daysOfWeek!.isEmpty) return true;
    
    final weekday = WeekDay.values[date.weekday - 1]; // DateTime.weekday est 1-7 (lundi-dimanche)
    return daysOfWeek!.contains(weekday);
  }

  /// Obtient le Nème jour de la semaine d'un mois
  DateTime _getNthWeekdayOfMonth(DateTime month, int weekNumber, WeekDay weekDay) {
    var firstDay = DateTime(month.year, month.month, 1);
    var firstWeekday = WeekDay.values[firstDay.weekday - 1];
    
    // Calculer le premier occurrence du jour de la semaine
    var daysToAdd = (weekDay.index - firstWeekday.index) % 7;
    var firstOccurrence = firstDay.add(Duration(days: daysToAdd));
    
    // Ajouter les semaines nécessaires
    return firstOccurrence.add(Duration(days: 7 * (weekNumber - 1)));
  }

  /// Description textuelle de la récurrence
  String get description {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        if (interval == 1) return 'Tous les jours';
        return 'Tous les $interval jours';
        
      case RecurrenceFrequency.weekly:
        if (interval == 1) {
          if (daysOfWeek == null || daysOfWeek!.isEmpty) {
            return 'Toutes les semaines';
          }
          final days = daysOfWeek!.map(_weekDayToString).join(', ');
          return 'Toutes les semaines le $days';
        }
        return 'Toutes les $interval semaines';
        
      case RecurrenceFrequency.monthly:
        if (interval == 1) return 'Tous les mois';
        return 'Tous les $interval mois';
        
      case RecurrenceFrequency.yearly:
        if (interval == 1) return 'Tous les ans';
        return 'Tous les $interval ans';
    }
  }

  String _weekDayToString(WeekDay day) {
    switch (day) {
      case WeekDay.monday: return 'lundi';
      case WeekDay.tuesday: return 'mardi';
      case WeekDay.wednesday: return 'mercredi';
      case WeekDay.thursday: return 'jeudi';
      case WeekDay.friday: return 'vendredi';
      case WeekDay.saturday: return 'samedi';
      case WeekDay.sunday: return 'dimanche';
    }
  }

  EventRecurrence copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<WeekDay>? daysOfWeek,
    int? dayOfMonth,
    int? weekOfMonth,
    int? monthOfYear,
    RecurrenceEndType? endType,
    int? occurrences,
    DateTime? endDate,
    List<DateTime>? exceptions,
  }) {
    return EventRecurrence(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      endType: endType ?? this.endType,
      occurrences: occurrences ?? this.occurrences,
      endDate: endDate ?? this.endDate,
      exceptions: exceptions ?? this.exceptions,
    );
  }

  /// Convertit un EventRecurrenceModel vers EventRecurrence
  static EventRecurrence fromEventRecurrenceModel(EventRecurrenceModel model) {
    RecurrenceFrequency frequency;
    switch (model.type) {
      case RecurrenceType.daily:
        frequency = RecurrenceFrequency.daily;
        break;
      case RecurrenceType.weekly:
        frequency = RecurrenceFrequency.weekly;
        break;
      case RecurrenceType.monthly:
        frequency = RecurrenceFrequency.monthly;
        break;
      case RecurrenceType.yearly:
        frequency = RecurrenceFrequency.yearly;
        break;
      case RecurrenceType.custom:
        frequency = RecurrenceFrequency.weekly; // Par défaut
        break;
    }

    // Convertir les jours de la semaine depuis List<int> vers List<WeekDay>
    List<WeekDay>? daysOfWeek;
    if (model.daysOfWeek != null && model.daysOfWeek!.isNotEmpty) {
      daysOfWeek = model.daysOfWeek!.map((dayInt) {
        // EventRecurrenceModel utilise 1-7 (Lundi=1, Dimanche=7)
        // WeekDay enum commence à 0 (Lundi=0, Dimanche=6)
        return WeekDay.values[dayInt - 1];
      }).toList();
    }

    RecurrenceEndType endType;
    if (model.endDate != null) {
      endType = RecurrenceEndType.onDate;
    } else if (model.occurrenceCount != null) {
      endType = RecurrenceEndType.afterOccurrences;
    } else {
      endType = RecurrenceEndType.never;
    }

    return EventRecurrence(
      frequency: frequency,
      interval: model.interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: model.dayOfMonth,
      weekOfMonth: null, // EventRecurrenceModel ne semble pas avoir cette propriété
      monthOfYear: model.monthsOfYear?.isNotEmpty == true 
          ? model.monthsOfYear!.first 
          : null,
      endType: endType,
      occurrences: model.occurrenceCount,
      endDate: model.endDate,
      exceptions: model.exceptions,
    );
  }

  /// Convertit un EventRecurrence vers EventRecurrenceModel
  EventRecurrenceModel toEventRecurrenceModel({
    required String id,
    required String parentEventId,
  }) {
    RecurrenceType type;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        type = RecurrenceType.daily;
        break;
      case RecurrenceFrequency.weekly:
        type = RecurrenceType.weekly;
        break;
      case RecurrenceFrequency.monthly:
        type = RecurrenceType.monthly;
        break;
      case RecurrenceFrequency.yearly:
        type = RecurrenceType.yearly;
        break;
    }

    // Convertir les jours de la semaine depuis List<WeekDay> vers List<int>
    List<int>? daysOfWeekInt;
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      daysOfWeekInt = daysOfWeek!.map((weekDay) {
        // WeekDay enum commence à 0 (Lundi=0, Dimanche=6)
        // EventRecurrenceModel utilise 1-7 (Lundi=1, Dimanche=7)
        return weekDay.index + 1;
      }).toList();
    }

    return EventRecurrenceModel(
      id: id,
      parentEventId: parentEventId,
      type: type,
      interval: interval,
      daysOfWeek: daysOfWeekInt,
      dayOfMonth: dayOfMonth,
      monthsOfYear: monthOfYear != null ? [monthOfYear!] : null,
      endDate: endType == RecurrenceEndType.onDate ? endDate : null,
      occurrenceCount: endType == RecurrenceEndType.afterOccurrences ? occurrences : null,
      exceptions: exceptions,
      overrides: [], // Par défaut vide
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String type; // 'celebration', 'bapteme', 'formation', 'sortie', 'conference', 'reunion', 'autre'
  final List<String> responsibleIds;
  final String visibility; // 'publique', 'privee', 'groupe', 'role'
  final List<String> visibilityTargets; // Group IDs or Role IDs if restricted
  final String status; // 'brouillon', 'publie', 'archive', 'annule'
  final bool isRegistrationEnabled;
  final DateTime? closeDate;
  final int? maxParticipants;
  final bool hasWaitingList;
  final bool isRecurring;
  final EventRecurrence? recurrence;
  final List<String> attachmentUrls;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  
  // Nouveaux champs pour l'intégration Services ↔ Events
  final String? linkedServiceId;  // Référence vers ServiceModel
  final bool isServiceEvent;      // Flag pour identifier les événements-services

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.type,
    this.responsibleIds = const [],
    this.visibility = 'publique',
    this.visibilityTargets = const [],
    this.status = 'brouillon',
    this.isRegistrationEnabled = false,
    this.closeDate,
    this.maxParticipants,
    this.hasWaitingList = false,
    this.isRecurring = false,
    this.recurrence,
    this.attachmentUrls = const [],
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.linkedServiceId,
    this.isServiceEvent = false,
  });

  String get typeLabel {
    switch (type) {
      case 'celebration': return 'Célébration';
      case 'bapteme': return 'Baptême';
      case 'formation': return 'Formation';
      case 'sortie': return 'Sortie';
      case 'conference': return 'Conférence';
      case 'reunion': return 'Réunion';
      default: return 'Autre';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'brouillon': return 'Brouillon';
      case 'publie': return 'Publié';
      case 'archive': return 'Archivé';
      case 'annule': return 'Annulé';
      default: return status;
    }
  }

  String get visibilityLabel {
    switch (visibility) {
      case 'publique': return 'Publique';
      case 'privee': return 'Privée';
      case 'groupe': return 'Réservée aux groupes';
      case 'role': return 'Réservée aux rôles';
      default: return visibility;
    }
  }

  bool get isPublished => status == 'publie';
  bool get isDraft => status == 'brouillon';
  bool get isArchived => status == 'archive';
  bool get isCancelled => status == 'annule';
  
  bool get isOpen {
    if (!isRegistrationEnabled) return false;
    if (closeDate == null) return true;
    return DateTime.now().isBefore(closeDate!);
  }
  
  bool get isMultiDay => endDate != null && !isSameDay(startDate, endDate!);
  
  Duration get duration {
    if (endDate != null) {
      return endDate!.difference(startDate);
    }
    return Duration(hours: 2); // Default duration
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      type: data['type'] ?? 'autre',
      responsibleIds: List<String>.from(data['responsibleIds'] ?? []),
      visibility: data['visibility'] ?? 'publique',
      visibilityTargets: List<String>.from(data['visibilityTargets'] ?? []),
      status: data['status'] ?? 'brouillon',
      isRegistrationEnabled: data['isRegistrationEnabled'] ?? false,
      maxParticipants: data['maxParticipants'],
      hasWaitingList: data['hasWaitingList'] ?? false,
      isRecurring: data['isRecurring'] ?? false,
      recurrence: data['recurrence'] != null 
          ? EventRecurrence.fromMap(data['recurrence']) 
          : null,
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      linkedServiceId: data['linkedServiceId'],
      isServiceEvent: data['isServiceEvent'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'imageUrl': imageUrl,
      'type': type,
      'responsibleIds': responsibleIds,
      'visibility': visibility,
      'visibilityTargets': visibilityTargets,
      'status': status,
      'isRegistrationEnabled': isRegistrationEnabled,
      'maxParticipants': maxParticipants,
      'hasWaitingList': hasWaitingList,
      'isRecurring': isRecurring,
      'recurrence': recurrence?.toMap(),
      'attachmentUrls': attachmentUrls,
      'customFields': customFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'linkedServiceId': linkedServiceId,
      'isServiceEvent': isServiceEvent,
    };
  }

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? type,
    List<String>? responsibleIds,
    String? visibility,
    List<String>? visibilityTargets,
    String? status,
    bool? isRegistrationEnabled,
    int? maxParticipants,
    bool? hasWaitingList,
    bool? isRecurring,
    EventRecurrence? recurrence,
    List<String>? attachmentUrls,
    Map<String, dynamic>? customFields,
    DateTime? updatedAt,
    String? lastModifiedBy,
    String? linkedServiceId,
    bool? isServiceEvent,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      responsibleIds: responsibleIds ?? this.responsibleIds,
      visibility: visibility ?? this.visibility,
      visibilityTargets: visibilityTargets ?? this.visibilityTargets,
      status: status ?? this.status,
      isRegistrationEnabled: isRegistrationEnabled ?? this.isRegistrationEnabled,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      hasWaitingList: hasWaitingList ?? this.hasWaitingList,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      linkedServiceId: linkedServiceId ?? this.linkedServiceId,
      isServiceEvent: isServiceEvent ?? this.isServiceEvent,
    );
  }
}

class EventFormModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<EventFormField> fields;
  final String confirmationMessage;
  final String? confirmationEmailTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventFormModel({
    required this.id,
    required this.eventId,
    required this.title,
    this.description = '',
    this.fields = const [],
    this.confirmationMessage = 'Merci pour votre inscription !',
    this.confirmationEmailTemplate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventFormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventFormModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fields: (data['fields'] as List? ?? [])
          .map((field) => EventFormField.fromMap(field))
          .toList(),
      confirmationMessage: data['confirmationMessage'] ?? 'Merci pour votre inscription !',
      confirmationEmailTemplate: data['confirmationEmailTemplate'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'fields': fields.map((field) => field.toMap()).toList(),
      'confirmationMessage': confirmationMessage,
      'confirmationEmailTemplate': confirmationEmailTemplate,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class EventFormField {
  final String id;
  final String label;
  final String type; // 'text', 'email', 'phone', 'number', 'select', 'checkbox', 'textarea'
  final bool isRequired;
  final List<String> options; // For select and checkbox types
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic>? validation;
  final int order;

  EventFormField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options = const [],
    this.placeholder,
    this.helpText,
    this.validation,
    required this.order,
  });

  factory EventFormField.fromMap(Map<String, dynamic> map) {
    return EventFormField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? false,
      options: List<String>.from(map['options'] ?? []),
      placeholder: map['placeholder'],
      helpText: map['helpText'],
      validation: map['validation'],
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'isRequired': isRequired,
      'options': options,
      'placeholder': placeholder,
      'helpText': helpText,
      'validation': validation,
      'order': order,
    };
  }
}

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String? personId; // Null if external registration
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final Map<String, dynamic> formResponses;
  final String status; // 'confirmed', 'waiting', 'cancelled'
  final DateTime registrationDate;
  final bool isPresent;
  final DateTime? attendanceRecordedAt;
  final String? notes;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    this.personId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.formResponses = const {},
    this.status = 'confirmed',
    required this.registrationDate,
    this.isPresent = false,
    this.attendanceRecordedAt,
    this.notes,
  });

  String get fullName => '$firstName $lastName';

  bool get isConfirmed => status == 'confirmed';
  bool get isWaiting => status == 'waiting';
  bool get isCancelled => status == 'cancelled';

  factory EventRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventRegistrationModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      personId: data['personId'],
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      formResponses: Map<String, dynamic>.from(data['formResponses'] ?? {}),
      status: data['status'] ?? 'confirmed',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      isPresent: data['isPresent'] ?? false,
      attendanceRecordedAt: data['attendanceRecordedAt'] != null 
          ? (data['attendanceRecordedAt'] as Timestamp).toDate() 
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'personId': personId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'formResponses': formResponses,
      'status': status,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'isPresent': isPresent,
      'attendanceRecordedAt': attendanceRecordedAt != null 
          ? Timestamp.fromDate(attendanceRecordedAt!) 
          : null,
      'notes': notes,
    };
  }

  EventRegistrationModel copyWith({
    String? status,
    bool? isPresent,
    DateTime? attendanceRecordedAt,
    String? notes,
  }) {
    return EventRegistrationModel(
      id: id,
      eventId: eventId,
      personId: personId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      formResponses: formResponses,
      status: status ?? this.status,
      registrationDate: registrationDate,
      isPresent: isPresent ?? this.isPresent,
      attendanceRecordedAt: attendanceRecordedAt ?? this.attendanceRecordedAt,
      notes: notes ?? this.notes,
    );
  }
}

class EventStatisticsModel {
  final String eventId;
  final int totalRegistrations;
  final int confirmedRegistrations;
  final int waitingRegistrations;
  final int cancelledRegistrations;
  final int presentCount;
  final Map<String, int> registrationsByDate;
  final Map<String, dynamic> formResponsesSummary;
  final double fillRate;
  final double attendanceRate;
  final DateTime lastUpdated;

  EventStatisticsModel({
    required this.eventId,
    required this.totalRegistrations,
    required this.confirmedRegistrations,
    required this.waitingRegistrations,
    required this.cancelledRegistrations,
    required this.presentCount,
    required this.registrationsByDate,
    required this.formResponsesSummary,
    required this.fillRate,
    required this.attendanceRate,
    required this.lastUpdated,
  });

  factory EventStatisticsModel.fromMap(Map<String, dynamic> data) {
    return EventStatisticsModel(
      eventId: data['eventId'] ?? '',
      totalRegistrations: data['totalRegistrations'] ?? 0,
      confirmedRegistrations: data['confirmedRegistrations'] ?? 0,
      waitingRegistrations: data['waitingRegistrations'] ?? 0,
      cancelledRegistrations: data['cancelledRegistrations'] ?? 0,
      presentCount: data['presentCount'] ?? 0,
      registrationsByDate: Map<String, int>.from(data['registrationsByDate'] ?? {}),
      formResponsesSummary: Map<String, dynamic>.from(data['formResponsesSummary'] ?? {}),
      fillRate: data['fillRate']?.toDouble() ?? 0.0,
      attendanceRate: data['attendanceRate']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'totalRegistrations': totalRegistrations,
      'confirmedRegistrations': confirmedRegistrations,
      'waitingRegistrations': waitingRegistrations,
      'cancelledRegistrations': cancelledRegistrations,
      'presentCount': presentCount,
      'registrationsByDate': registrationsByDate,
      'formResponsesSummary': formResponsesSummary,
      'fillRate': fillRate,
      'attendanceRate': attendanceRate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}