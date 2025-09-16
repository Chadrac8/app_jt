import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/event_recurrence_manager_service.dart';

/// Service pour gérer l'affichage des événements récurrents dans les calendriers
class RecurringCalendarService {
  // Cache pour optimiser les performances
  final Map<String, List<EventModel>> _eventsCache = {};
  final Map<String, Map<String, dynamic>> _statisticsCache = {};

  /// Obtient les événements pour une date donnée avec gestion du cache
  Future<List<EventModel>> getEventsForDay(DateTime day) async {
    final dayKey = _getDayKey(day);
    
    if (_eventsCache.containsKey(dayKey)) {
      return _eventsCache[dayKey]!;
    }
    
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: startOfDay,
      endDate: endOfDay,
    );
    
    // Convertir les données d'événements en EventModel
    final events = eventsData.map((data) {
      final eventData = data['event'] as Map<String, dynamic>;
      return EventModel(
        id: eventData['id'] ?? '',
        title: eventData['title'] ?? '',
        description: eventData['description'] ?? '',
        startDate: (eventData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (eventData['endDate'] as Timestamp?)?.toDate(),
        location: eventData['location'] ?? '',
        type: eventData['type'] ?? 'autre',
        status: eventData['status'] ?? 'brouillon',
        createdBy: eventData['createdBy'] ?? '',
        isRecurring: eventData['isRecurring'] ?? false,
        isRegistrationEnabled: eventData['isRegistrationEnabled'] ?? false,
        createdAt: (eventData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (eventData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        recurrence: eventData['recurrence'] != null 
          ? EventRecurrence.fromMap(eventData['recurrence']) 
          : null,
      );
    }).toList();
    
    _eventsCache[dayKey] = events;
    return events;
  }

  /// Obtient les événements pour une semaine
  Future<Map<DateTime, List<EventModel>>> getEventsForWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: weekStart,
      endDate: weekEnd,
    );
    
    final Map<DateTime, List<EventModel>> eventsByDay = {};
    
    for (int i = 0; i < 7; i++) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      eventsByDay[day] = [];
    }
    
    for (final eventData in eventsData) {
      final event = _convertEventData(eventData);
      final eventDay = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      
      if (eventsByDay.containsKey(eventDay)) {
        eventsByDay[eventDay]!.add(event);
      }
    }
    
    return eventsByDay;
  }

  /// Obtient les événements pour un mois avec optimisation
  Future<Map<DateTime, List<EventModel>>> getEventsForMonth(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    // Étendre aux semaines complètes pour l'affichage du calendrier
    final calendarStart = _getStartOfCalendarMonth(firstDay);
    final calendarEnd = _getEndOfCalendarMonth(lastDay);
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: calendarStart,
      endDate: calendarEnd,
    );
    
    final Map<DateTime, List<EventModel>> eventsByDay = {};
    
    // Initialiser tous les jours du mois visible
    DateTime currentDay = calendarStart;
    while (currentDay.isBefore(calendarEnd) || currentDay.isAtSameMomentAs(calendarEnd)) {
      final dayKey = DateTime(currentDay.year, currentDay.month, currentDay.day);
      eventsByDay[dayKey] = [];
      currentDay = currentDay.add(const Duration(days: 1));
    }
    
    // Grouper les événements par jour
    for (final eventData in eventsData) {
      final event = _convertEventData(eventData);
      final eventDay = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      
      if (eventsByDay.containsKey(eventDay)) {
        eventsByDay[eventDay]!.add(event);
      }
    }
    
    return eventsByDay;
  }

  /// Obtient les statistiques des événements récurrents pour une période
  Future<Map<String, dynamic>> getRecurrenceStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final periodKey = '${_getDayKey(startDate)}_${_getDayKey(endDate)}';
    
    if (_statisticsCache.containsKey(periodKey)) {
      return _statisticsCache[periodKey]!;
    }
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: startDate,
      endDate: endDate,
    );
    
    final events = eventsData.map((data) => _convertEventData(data)).toList();
    
    int totalEvents = events.length;
    int recurringInstances = 0;
    int simpleEvents = 0;
    Map<String, int> frequencyBreakdown = {};
    Map<String, int> typeBreakdown = {};
    
    for (final event in events) {
      if (event.isRecurring) {
        if (event.recurrence != null) {
          final frequency = event.recurrence!.frequency.toString().split('.').last;
          frequencyBreakdown[frequency] = (frequencyBreakdown[frequency] ?? 0) + 1;
          recurringInstances++;
        }
      } else {
        simpleEvents++;
      }
      
      final type = event.typeLabel;
      typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
    }
    
    final statistics = {
      'totalEvents': totalEvents,
      'recurringInstances': recurringInstances,
      'simpleEvents': simpleEvents,
      'frequencyBreakdown': frequencyBreakdown,
      'typeBreakdown': typeBreakdown,
      'period': {
        'start': startDate,
        'end': endDate,
      },
    };
    
    _statisticsCache[periodKey] = statistics;
    return statistics;
  }

  /// Recherche d'événements avec support des récurrences
  Future<List<EventModel>> searchEvents(
    String query,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final searchStartDate = startDate ?? DateTime.now();
    final searchEndDate = endDate ?? DateTime.now().add(const Duration(days: 365));
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: searchStartDate,
      endDate: searchEndDate,
    );
    
    final events = eventsData.map((data) => _convertEventData(data)).toList();
    
    if (query.isEmpty) return events;
    
    final queryLower = query.toLowerCase();
    return events.where((event) {
      return event.title.toLowerCase().contains(queryLower) ||
             event.description.toLowerCase().contains(queryLower) ||
             event.location.toLowerCase().contains(queryLower) ||
             event.typeLabel.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Filtre les événements par critères
  List<EventModel> filterEvents(
    List<EventModel> events, {
    List<String>? types,
    List<String>? statuses,
    bool? isRecurring,
    bool? hasRegistration,
  }) {
    return events.where((event) {
      if (types != null && types.isNotEmpty && !types.contains(event.type)) {
        return false;
      }
      
      if (statuses != null && statuses.isNotEmpty && !statuses.contains(event.status)) {
        return false;
      }
      
      if (isRecurring != null && event.isRecurring != isRecurring) {
        return false;
      }
      
      if (hasRegistration != null && event.isRegistrationEnabled != hasRegistration) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Obtient les prochains événements récurrents
  Future<List<EventModel>> getUpcomingRecurringEvents({
    int limit = 10,
    Duration? lookAhead,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(lookAhead ?? const Duration(days: 30));
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: now,
      endDate: endDate,
    );
    
    final events = eventsData.map((data) => _convertEventData(data)).toList();
    
    // Filtrer et trier les événements récurrents
    final recurringEvents = events
        .where((event) => event.isRecurring && event.startDate.isAfter(now))
        .toList();
    
    recurringEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    return recurringEvents.take(limit).toList();
  }

  /// Obtient les événements en conflit potentiel
  Future<List<Map<String, dynamic>>> getConflictingEvents(
    EventModel newEvent,
    Duration conflictBuffer,
  ) async {
    final startDate = newEvent.startDate.subtract(conflictBuffer);
    final endDate = (newEvent.endDate ?? newEvent.startDate).add(conflictBuffer);
    
    final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
      startDate: startDate,
      endDate: endDate,
    );
    
    final existingEvents = eventsData.map((data) => _convertEventData(data)).toList();
    
    final conflicts = <Map<String, dynamic>>[];
    
    for (final existing in existingEvents) {
      if (existing.id == newEvent.id) continue;
      
      final conflict = _checkEventConflict(newEvent, existing, conflictBuffer);
      if (conflict != null) {
        conflicts.add(conflict);
      }
    }
    
    return conflicts;
  }

  /// Nettoie le cache (à appeler périodiquement)
  void clearCache() {
    _eventsCache.clear();
    _statisticsCache.clear();
  }

  /// Nettoie le cache pour une date spécifique
  void clearCacheForDate(DateTime date) {
    final dayKey = _getDayKey(date);
    _eventsCache.remove(dayKey);
    
    // Nettoyer aussi le cache des statistiques qui incluent cette date
    final keysToRemove = _statisticsCache.keys
        .where((key) => key.contains(dayKey))
        .toList();
    
    for (final key in keysToRemove) {
      _statisticsCache.remove(key);
    }
  }

  // Méthodes utilitaires privées

  EventModel _convertEventData(Map<String, dynamic> data) {
    final eventData = data['event'] as Map<String, dynamic>;
    return EventModel(
      id: eventData['id'] ?? '',
      title: eventData['title'] ?? '',
      description: eventData['description'] ?? '',
      startDate: (eventData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (eventData['endDate'] as Timestamp?)?.toDate(),
      location: eventData['location'] ?? '',
      type: eventData['type'] ?? 'autre',
      status: eventData['status'] ?? 'brouillon',
      createdBy: eventData['createdBy'] ?? '',
      isRecurring: eventData['isRecurring'] ?? false,
      isRegistrationEnabled: eventData['isRegistrationEnabled'] ?? false,
      createdAt: (eventData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (eventData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrence: eventData['recurrence'] != null 
        ? EventRecurrence.fromMap(eventData['recurrence']) 
        : null,
    );
  }

  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  DateTime _getStartOfCalendarMonth(DateTime firstDayOfMonth) {
    final weekday = firstDayOfMonth.weekday;
    final daysToSubtract = weekday == 7 ? 0 : weekday;
    return firstDayOfMonth.subtract(Duration(days: daysToSubtract));
  }

  DateTime _getEndOfCalendarMonth(DateTime lastDayOfMonth) {
    final weekday = lastDayOfMonth.weekday;
    final daysToAdd = weekday == 7 ? 6 : 6 - weekday;
    return lastDayOfMonth.add(Duration(days: daysToAdd));
  }

  Map<String, dynamic>? _checkEventConflict(
    EventModel event1,
    EventModel event2,
    Duration buffer,
  ) {
    final start1 = event1.startDate.subtract(buffer);
    final end1 = (event1.endDate ?? event1.startDate).add(buffer);
    final start2 = event2.startDate;
    final end2 = event2.endDate ?? event2.startDate;

    // Vérifier le chevauchement
    if (start1.isBefore(end2) && end1.isAfter(start2)) {
      return {
        'conflictingEvent': event2,
        'conflictType': _getConflictType(event1, event2),
        'overlapDuration': _calculateOverlapDuration(start1, end1, start2, end2),
      };
    }

    return null;
  }

  String _getConflictType(EventModel event1, EventModel event2) {
    if (event1.location.isNotEmpty && 
        event2.location.isNotEmpty && 
        event1.location == event2.location) {
      return 'same_location';
    }
    
    if (event1.type == event2.type) {
      return 'same_type';
    }
    
    return 'time_overlap';
  }

  Duration _calculateOverlapDuration(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;
    
    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart);
    }
    
    return Duration.zero;
  }
}