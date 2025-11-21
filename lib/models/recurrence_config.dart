/// Configuration de récurrence pour groupes et événements
/// Inspiré de Planning Center Online Groups
class RecurrenceConfig {
  /// Fréquence de récurrence
  final RecurrenceFrequency frequency;
  
  /// Intervalle (tous les X jours/semaines/mois)
  final int interval;
  
  /// Jour de la semaine (1=Lundi, 7=Dimanche) - pour weekly/monthly
  final int? dayOfWeek;
  
  /// Heure de début (format "HH:mm")
  final String time;
  
  /// Durée en minutes
  final int durationMinutes;
  
  /// Date de début de la récurrence
  final DateTime startDate;
  
  /// Date de fin de la récurrence (optionnel)
  final DateTime? endDate;
  
  /// Nombre maximum d'occurrences (optionnel)
  final int? maxOccurrences;
  
  /// Dates à exclure (vacances, jours fériés)
  final List<DateTime> excludeDates;
  
  /// Fuseau horaire
  final String timezone;

  const RecurrenceConfig({
    required this.frequency,
    this.interval = 1,
    this.dayOfWeek,
    required this.time,
    this.durationMinutes = 120,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.excludeDates = const [],
    this.timezone = 'Europe/Paris',
  });

  /// Créer depuis Map (depuis Firestore)
  factory RecurrenceConfig.fromMap(Map<String, dynamic> map) {
    return RecurrenceConfig(
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.weekly,
      ),
      interval: map['interval'] ?? 1,
      dayOfWeek: map['dayOfWeek'],
      time: map['time'] ?? '19:00',
      durationMinutes: map['durationMinutes'] ?? 120,
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      maxOccurrences: map['maxOccurrences'],
      excludeDates: (map['excludeDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d))
              .toList() ??
          [],
      timezone: map['timezone'] ?? 'Europe/Paris',
    );
  }

  /// Convertir en Map (pour Firestore)
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'dayOfWeek': dayOfWeek,
      'time': time,
      'durationMinutes': durationMinutes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'excludeDates': excludeDates.map((d) => d.toIso8601String()).toList(),
      'timezone': timezone,
    };
  }

  /// Copier avec modifications
  RecurrenceConfig copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    int? dayOfWeek,
    String? time,
    int? durationMinutes,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    List<DateTime>? excludeDates,
    String? timezone,
  }) {
    return RecurrenceConfig(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      excludeDates: excludeDates ?? this.excludeDates,
      timezone: timezone ?? this.timezone,
    );
  }

  /// Description lisible
  String get description {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1
            ? 'Tous les jours à $time'
            : 'Tous les $interval jours à $time';
      case RecurrenceFrequency.weekly:
        final day = _getDayName(dayOfWeek ?? 1);
        return interval == 1
            ? 'Tous les $day à $time'
            : 'Toutes les $interval semaines le $day à $time';
      case RecurrenceFrequency.monthly:
        return interval == 1
            ? 'Tous les mois à $time'
            : 'Tous les $interval mois à $time';
      case RecurrenceFrequency.yearly:
        return 'Tous les ans à $time';
      case RecurrenceFrequency.custom:
        return 'Récurrence personnalisée';
    }
  }

  String _getDayName(int day) {
    const days = [
      '',
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    return days[day];
  }

  /// Calculer le nombre total d'occurrences
  int calculateTotalOccurrences() {
    if (maxOccurrences != null) {
      return maxOccurrences!;
    }

    if (endDate == null) {
      // Par défaut, 6 mois
      return _calculateOccurrencesBetween(
        startDate,
        startDate.add(const Duration(days: 180)),
      );
    }

    return _calculateOccurrencesBetween(startDate, endDate!);
  }

  int _calculateOccurrencesBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (!excludeDates.any((d) => _isSameDay(d, current))) {
        count++;
      }
      current = _getNextOccurrence(current);
      if (count > 1000) break; // Safety limit
    }

    return count;
  }

  DateTime _getNextOccurrence(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime(
          current.year,
          current.month + interval,
          current.day,
          current.hour,
          current.minute,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          current.year + interval,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
      case RecurrenceFrequency.custom:
        return current.add(Duration(days: interval));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Vérifier si une occurrence doit être générée à cette date
  /// PHASE 3 - Méthode clé pour génération événements
  bool shouldGenerateOccurrence(DateTime date) {
    // Avant startDate
    if (date.isBefore(startDate)) return false;

    // Après endDate si défini
    if (endDate != null && date.isAfter(endDate!)) return false;

    // Date exclue
    if (excludeDates.any((d) => _isSameDay(d, date))) return false;

    return true;
  }

  /// Obtenir la prochaine occurrence après une date donnée
  /// PHASE 3 - Navigation dans récurrence
  DateTime getNextOccurrence(DateTime afterDate) {
    return _getNextOccurrence(afterDate);
  }

  /// Valider configuration
  /// PHASE 3 - Validation avant sauvegarde
  bool isValid() {
    // Interval positif
    if (interval <= 0) return false;

    // Weekly : dayOfWeek requis
    if (frequency == RecurrenceFrequency.weekly) {
      if (dayOfWeek == null || dayOfWeek! < 1 || dayOfWeek! > 7) {
        return false;
      }
    }

    // EndDate après startDate
    if (endDate != null && endDate!.isBefore(startDate)) {
      return false;
    }

    // MaxOccurrences positif
    if (maxOccurrences != null && maxOccurrences! <= 0) {
      return false;
    }

    return true;
  }

  /// Conversion JSON (alias de toMap pour compatibilité)
  Map<String, dynamic> toJson() => toMap();

  /// fromJson (alias de fromMap pour compatibilité)
  factory RecurrenceConfig.fromJson(Map<String, dynamic> json) {
    return RecurrenceConfig.fromMap(json);
  }

  @override
  String toString() {
    return 'RecurrenceConfig(frequency: $frequency, interval: $interval, time: $time)';
  }
}

/// Fréquence de récurrence
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Quotidien';
      case RecurrenceFrequency.weekly:
        return 'Hebdomadaire';
      case RecurrenceFrequency.monthly:
        return 'Mensuel';
      case RecurrenceFrequency.yearly:
        return 'Annuel';
      case RecurrenceFrequency.custom:
        return 'Personnalisé';
    }
  }

  static RecurrenceFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'custom':
        return RecurrenceFrequency.custom;
      default:
        throw Exception('Invalid frequency: $value');
    }
  }
}

/// Type fin récurrence
enum RecurrenceEndType {
  never,
  on, // À une date
  after; // Après X occurrences

  String get displayName {
    switch (this) {
      case RecurrenceEndType.never:
        return 'Jamais';
      case RecurrenceEndType.on:
        return 'Le';
      case RecurrenceEndType.after:
        return 'Après';
    }
  }

  static RecurrenceEndType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'never':
        return RecurrenceEndType.never;
      case 'on':
        return RecurrenceEndType.on;
      case 'after':
        return RecurrenceEndType.after;
      default:
        throw Exception('Invalid end type: $value');
    }
  }
}

/// Portée de modification pour groupes/événements récurrents
enum GroupEditScope {
  /// Modifier uniquement cette occurrence
  thisOccurrenceOnly,

  /// Modifier cette occurrence et toutes les suivantes
  thisAndFutureOccurrences,

  /// Modifier toutes les occurrences de la série
  allOccurrences,
}

/// Extension pour obtenir des labels lisibles
extension GroupEditScopeExtension on GroupEditScope {
  String get label {
    switch (this) {
      case GroupEditScope.thisOccurrenceOnly:
        return 'Cette occurrence uniquement';
      case GroupEditScope.thisAndFutureOccurrences:
        return 'Cette occurrence et les suivantes';
      case GroupEditScope.allOccurrences:
        return 'Toutes les occurrences';
    }
  }

  String get description {
    switch (this) {
      case GroupEditScope.thisOccurrenceOnly:
        return 'Personnaliser cette occurrence sans affecter les autres';
      case GroupEditScope.thisAndFutureOccurrences:
        return 'Modifier cette occurrence et toutes celles à venir';
      case GroupEditScope.allOccurrences:
        return 'Modifier toutes les occurrences de cette série';
    }
  }
}
