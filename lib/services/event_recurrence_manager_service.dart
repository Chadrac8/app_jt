import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// Service simplifié pour les événements récurrents avec le nouveau modèle EventRecurrence
class EventRecurrenceManagerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _eventsCollection = 'events';

  /// Génère les instances d'événements pour une période donnée
  /// Compatible avec le nouveau modèle EventRecurrence dans EventModel
  static Future<List<Map<String, dynamic>>> getEventsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? searchQuery,
    List<String>? typeFilters,
    String? status,
  }) async {
    try {
      // Récupérer tous les événements
      Query query = _firestore.collection(_eventsCollection);
      
      // Filtrer par statut si spécifié
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      final eventsSnapshot = await query.get();
      final allEventInstances = <Map<String, dynamic>>[];

      for (final doc in eventsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final event = EventModel.fromFirestore(doc);

        // Appliquer les filtres de recherche et de type
        if (!_matchesFilters(event, searchQuery, typeFilters)) {
          continue;
        }

        if (event.isRecurring && event.recurrence != null) {
          // Générer les instances d'événements récurrents
          final instances = _generateRecurringInstances(event, startDate, endDate);
          allEventInstances.addAll(instances);
        } else {
          // Événement simple - inclure seulement s'il est dans la période
          if (_isEventInPeriod(event, startDate, endDate)) {
            allEventInstances.add({
              ...data,
              'id': doc.id,
              'isRecurringInstance': false,
              'originalEventId': doc.id,
              'instanceDate': event.startDate,
              'startDate': Timestamp.fromDate(event.startDate),
              'endDate': event.endDate != null ? Timestamp.fromDate(event.endDate!) : null,
            });
          }
        }
      }

      // Trier par date de début
      allEventInstances.sort((a, b) {
        final dateA = a['startDate'] is Timestamp 
            ? (a['startDate'] as Timestamp).toDate()
            : a['startDate'] as DateTime;
        final dateB = b['startDate'] is Timestamp 
            ? (b['startDate'] as Timestamp).toDate()
            : b['startDate'] as DateTime;
        return dateA.compareTo(dateB);
      });

      return allEventInstances;
    } catch (e) {
      print('Erreur lors de la récupération des événements: $e');
      rethrow;
    }
  }

  /// Génère les instances d'un événement récurrent pour une période
  static List<Map<String, dynamic>> _generateRecurringInstances(
    EventModel event,
    DateTime startDate,
    DateTime endDate,
  ) {
    final instances = <Map<String, dynamic>>[];
    
    if (event.recurrence == null) return instances;

    try {
      // Générer les occurrences en utilisant la nouvelle classe EventRecurrence
      final occurrences = event.recurrence!.generateOccurrences(
        event.startDate,
        startDate,
        endDate,
      );

      for (final occurrence in occurrences) {
        // Calculer la date de fin pour cette instance
        DateTime? instanceEndDate;
        if (event.endDate != null) {
          final duration = event.endDate!.difference(event.startDate);
          instanceEndDate = occurrence.add(duration);
        }

        instances.add({
          'id': '${event.id}_${occurrence.millisecondsSinceEpoch}',
          'title': '${event.title} (${_getRecurrenceLabel(event.recurrence!)})',
          'description': event.description,
          'startDate': Timestamp.fromDate(occurrence),
          'endDate': instanceEndDate != null ? Timestamp.fromDate(instanceEndDate) : null,
          'location': event.location,
          'imageUrl': event.imageUrl,
          'type': event.type,
          'responsibleIds': event.responsibleIds,
          'visibility': event.visibility,
          'visibilityTargets': event.visibilityTargets,
          'status': event.status,
          'isRegistrationEnabled': event.isRegistrationEnabled,
          'closeDate': event.closeDate,
          'maxParticipants': event.maxParticipants,
          'hasWaitingList': event.hasWaitingList,
          'isRecurring': false, // Les instances ne sont pas récurrentes
          'recurrence': null,
          'attachmentUrls': event.attachmentUrls,
          'customFields': event.customFields,
          'createdAt': Timestamp.fromDate(event.createdAt),
          'updatedAt': Timestamp.fromDate(event.updatedAt),
          'createdBy': event.createdBy,
          'lastModifiedBy': event.lastModifiedBy,
          // Métadonnées pour les instances récurrentes
          'isRecurringInstance': true,
          'originalEventId': event.id,
          'instanceDate': occurrence,
          'recurrenceDescription': event.recurrence!.description,
        });
      }
    } catch (e) {
      print('Erreur lors de la génération des instances récurrentes: $e');
      // En cas d'erreur, ajouter l'événement original s'il est dans la période
      if (_isEventInPeriod(event, startDate, endDate)) {
        instances.add({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'startDate': Timestamp.fromDate(event.startDate),
          'endDate': event.endDate != null ? Timestamp.fromDate(event.endDate!) : null,
          'location': event.location,
          'imageUrl': event.imageUrl,
          'type': event.type,
          'responsibleIds': event.responsibleIds,
          'visibility': event.visibility,
          'visibilityTargets': event.visibilityTargets,
          'status': event.status,
          'isRegistrationEnabled': event.isRegistrationEnabled,
          'closeDate': event.closeDate,
          'maxParticipants': event.maxParticipants,
          'hasWaitingList': event.hasWaitingList,
          'isRecurring': true,
          'recurrence': event.recurrence?.toMap(),
          'attachmentUrls': event.attachmentUrls,
          'customFields': event.customFields,
          'createdAt': Timestamp.fromDate(event.createdAt),
          'updatedAt': Timestamp.fromDate(event.updatedAt),
          'createdBy': event.createdBy,
          'lastModifiedBy': event.lastModifiedBy,
          'isRecurringInstance': false,
          'originalEventId': event.id,
          'instanceDate': event.startDate,
          'recurrenceDescription': 'Événement récurrent (erreur de génération)',
        });
      }
    }

    return instances;
  }

  /// Obtient un label descriptif pour une récurrence
  static String _getRecurrenceLabel(EventRecurrence recurrence) {
    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        return recurrence.interval == 1 ? 'Quotidien' : 'Tous les ${recurrence.interval} jours';
      case RecurrenceFrequency.weekly:
        return recurrence.interval == 1 ? 'Hebdomadaire' : 'Toutes les ${recurrence.interval} semaines';
      case RecurrenceFrequency.monthly:
        return recurrence.interval == 1 ? 'Mensuel' : 'Tous les ${recurrence.interval} mois';
      case RecurrenceFrequency.yearly:
        return recurrence.interval == 1 ? 'Annuel' : 'Tous les ${recurrence.interval} ans';
    }
  }

  /// Vérifie si un événement correspond aux filtres
  static bool _matchesFilters(
    EventModel event,
    String? searchQuery,
    List<String>? typeFilters,
  ) {
    // Filtre de recherche
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      if (!event.title.toLowerCase().contains(query) &&
          !event.description.toLowerCase().contains(query) &&
          !event.location.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Filtre de type
    if (typeFilters != null && typeFilters.isNotEmpty) {
      if (!typeFilters.contains(event.type)) {
        return false;
      }
    }

    return true;
  }

  /// Vérifie si un événement est dans la période donnée
  static bool _isEventInPeriod(
    EventModel event,
    DateTime startDate,
    DateTime endDate,
  ) {
    final eventStart = event.startDate;
    final eventEnd = event.endDate ?? event.startDate;

    // L'événement est dans la période s'il y a une intersection
    return eventStart.isBefore(endDate) && eventEnd.isAfter(startDate);
  }

  /// Exclut une instance spécifique d'un événement récurrent
  static Future<void> excludeRecurringInstance({
    required String originalEventId,
    required DateTime instanceDate,
  }) async {
    try {
      final eventDoc = await _firestore
          .collection(_eventsCollection)
          .doc(originalEventId)
          .get();

      if (!eventDoc.exists) throw Exception('Événement non trouvé');

      final event = EventModel.fromFirestore(eventDoc);
      
      if (!event.isRecurring || event.recurrence == null) {
        throw Exception('L\'événement n\'est pas récurrent');
      }

      // Ajouter la date aux exceptions
      final updatedExceptions = List<DateTime>.from(event.recurrence!.exceptions);
      
      // Vérifier si la date n'est pas déjà dans les exceptions
      bool alreadyExcluded = updatedExceptions.any((exception) =>
          exception.year == instanceDate.year &&
          exception.month == instanceDate.month &&
          exception.day == instanceDate.day);

      if (!alreadyExcluded) {
        updatedExceptions.add(instanceDate);
        
        final updatedRecurrence = event.recurrence!.copyWith(
          exceptions: updatedExceptions,
        );

        await _firestore
            .collection(_eventsCollection)
            .doc(originalEventId)
            .update({
          'recurrence': updatedRecurrence.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de l\'exclusion de l\'instance: $e');
      rethrow;
    }
  }

  /// Obtient les statistiques des événements récurrents
  static Future<Map<String, dynamic>> getRecurrenceStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      final events = await getEventsForPeriod(
        startDate: start,
        endDate: end,
      );

      final recurringEvents = events.where((e) => e['isRecurringInstance'] == true).length;
      final simpleEvents = events.where((e) => e['isRecurringInstance'] == false).length;
      
      // Compter par fréquence
      final frequencyCount = <String, int>{};
      for (final event in events) {
        if (event['isRecurringInstance'] == true) {
          final description = event['recurrenceDescription'] as String? ?? 'Inconnu';
          frequencyCount[description] = (frequencyCount[description] ?? 0) + 1;
        }
      }

      return {
        'totalEvents': events.length,
        'recurringInstances': recurringEvents,
        'simpleEvents': simpleEvents,
        'frequencyBreakdown': frequencyCount,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'error': e.toString(),
        'totalEvents': 0,
        'recurringInstances': 0,
        'simpleEvents': 0,
        'frequencyBreakdown': <String, int>{},
      };
    }
  }
}