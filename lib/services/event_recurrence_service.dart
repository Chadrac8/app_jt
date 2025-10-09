import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/event_recurrence_model.dart';

/// Service pour la gestion des événements récurrents
/// Inspiré de Planning Center Online
class EventRecurrenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String recurrencesCollection = 'event_recurrences';
  static const String instancesCollection = 'event_instances';
  static const String exceptionsCollection = 'event_exceptions';

  /// Crée une règle de récurrence pour un événement
  static Future<String> createRecurrence(EventRecurrenceModel recurrence) async {
    try {
      print('📝 Création récurrence avec isActive: ${recurrence.isActive}');
      final firestoreData = recurrence.toFirestore();
      print('📄 Données Firestore: $firestoreData');
      
      final docRef = await _firestore
          .collection(recurrencesCollection)
          .add(firestoreData);

      print('✅ Récurrence créée avec ID: ${docRef.id}');
      
      // Générer les instances immédiatement (6 mois à l'avance)
      final recurrenceWithId = EventRecurrenceModel(
        id: docRef.id,
        parentEventId: recurrence.parentEventId,
        type: recurrence.type,
        interval: recurrence.interval,
        daysOfWeek: recurrence.daysOfWeek,
        dayOfMonth: recurrence.dayOfMonth,
        monthsOfYear: recurrence.monthsOfYear,
        endDate: recurrence.endDate,
        occurrenceCount: recurrence.occurrenceCount,
        exceptions: recurrence.exceptions,
        overrides: recurrence.overrides,
        isActive: recurrence.isActive,
        createdAt: recurrence.createdAt,
        updatedAt: recurrence.updatedAt,
      );
      
      await _generateInstancesForRecurrence(
        recurrenceWithId,
        until: DateTime.now().add(const Duration(days: 180)),
      );

      return docRef.id;
    } catch (e) {
      print('❌ Erreur création récurrence: $e');
      rethrow;
    }
  }

  /// Met à jour une règle de récurrence
  static Future<void> updateRecurrence(EventRecurrenceModel recurrence) async {
    try {
      print('📝 Mise à jour récurrence ${recurrence.id}');
      
      await _firestore
          .collection(recurrencesCollection)
          .doc(recurrence.id)
          .update(recurrence.toFirestore());

      print('✅ Récurrence mise à jour');
      
      // Regénérer les instances futures
      await _regenerateInstances(recurrence);
    } catch (e) {
      print('❌ Erreur mise à jour récurrence: $e');
      rethrow;
    }
  }

  /// Supprime une règle de récurrence et toutes ses instances
  static Future<void> deleteRecurrence(String recurrenceId) async {
    try {
      final batch = _firestore.batch();

      // Supprimer la règle de récurrence
      batch.delete(_firestore.collection(recurrencesCollection).doc(recurrenceId));

      // Supprimer toutes les instances futures avec requête optimisée
      final instances = await _firestore
          .collection(instancesCollection)
          .where('recurrenceId', isEqualTo: recurrenceId)
          .get();

      // Filtrer côté client pour éviter l'erreur d'index
      final now = DateTime.now();
      for (final instance in instances.docs) {
        final data = instance.data();
        final actualDate = (data['actualDate'] as Timestamp).toDate();
        if (actualDate.isAfter(now)) {
          batch.delete(instance.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la récurrence: $e');
    }
  }

  /// Récupère une règle de récurrence
  static Future<EventRecurrenceModel?> getRecurrence(String recurrenceId) async {
    try {
      final doc = await _firestore
          .collection(recurrencesCollection)
          .doc(recurrenceId)
          .get();

      if (doc.exists) {
        return EventRecurrenceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la récurrence: $e');
    }
  }

  /// Récupère les règles de récurrence d'un événement
  static Future<List<EventRecurrenceModel>> getEventRecurrences(String eventId) async {
    try {
      final query = await _firestore
          .collection(recurrencesCollection)
          .where('parentEventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => EventRecurrenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des récurrences: $e');
    }
  }

  /// Récupère les instances d'événement pour une période avec requêtes optimisées
  static Future<List<EventInstanceModel>> getEventInstances({
    String? eventId,
    String? recurrenceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(instancesCollection);
      List<EventInstanceModel> allInstances = [];

      // Si on a recurrenceId, l'utiliser en priorité (requête optimisée)
      if (recurrenceId != null) {
        query = query.where('recurrenceId', isEqualTo: recurrenceId);
        final result = await query.get();
        allInstances = result.docs
            .map((doc) => EventInstanceModel.fromFirestore(doc))
            .toList();
      } 
      // Sinon si on a eventId
      else if (eventId != null) {
        query = query.where('parentEventId', isEqualTo: eventId);
        final result = await query.get();
        allInstances = result.docs
            .map((doc) => EventInstanceModel.fromFirestore(doc))
            .toList();
      }
      // Récupérer toutes les instances et filtrer côté client
      else {
        final result = await query.get();
        allInstances = result.docs
            .map((doc) => EventInstanceModel.fromFirestore(doc))
            .toList();
      }

      // Appliquer les filtres de date côté client pour éviter les erreurs d'index
      if (startDate != null) {
        allInstances = allInstances.where((instance) => 
            instance.actualDate.isAfter(startDate) || 
            instance.actualDate.isAtSameMomentAs(startDate)
        ).toList();
      }

      if (endDate != null) {
        allInstances = allInstances.where((instance) => 
            instance.actualDate.isBefore(endDate) || 
            instance.actualDate.isAtSameMomentAs(endDate)
        ).toList();
      }

      return allInstances;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des instances: $e');
    }
  }

  /// Ajoute une exception à une date spécifique
  static Future<void> addException(String recurrenceId, DateTime date, {String? reason}) async {
    try {
      print('🚫 Ajout exception pour récurrence $recurrenceId à ${date.day}/${date.month}/${date.year}');
      
      final recurrence = await getRecurrence(recurrenceId);
      if (recurrence == null) {
        print('❌ Récurrence non trouvée');
        return;
      }

      // Ajouter l'exception à la liste
      final updatedExceptions = List<DateTime>.from(recurrence.exceptions)..add(date);
      
      await updateRecurrence(recurrence.copyWith(
        exceptions: updatedExceptions,
        updatedAt: DateTime.now(),
      ));

      // Marquer les instances existantes comme annulées
      final instances = await getEventInstances(
        recurrenceId: recurrenceId,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      for (final instance in instances) {
        await _firestore
            .collection(instancesCollection)
            .doc(instance.id)
            .update({'isCancelled': true});
      }
      
      print('✅ Exception ajoutée et instances mises à jour');
    } catch (e) {
      print('❌ Erreur ajout exception: $e');
      rethrow;
    }
  }

  /// Supprime une exception (restaure une occurrence annulée)
  static Future<void> removeException(
    String recurrenceId,
    DateTime date,
  ) async {
    try {
      print('🔄 Suppression exception pour récurrence $recurrenceId à $date');
      
      final recurrence = await getRecurrence(recurrenceId);
      if (recurrence == null) {
        print('❌ Récurrence non trouvée');
        return;
      }

      // Retirer la date des exceptions
      final updatedExceptions = recurrence.exceptions
          .where((d) => !_isSameDay(d, date))
          .toList();

      await updateRecurrence(recurrence.copyWith(
        exceptions: updatedExceptions,
        updatedAt: DateTime.now(),
      ));

      // Restaurer les instances annulées pour cette date
      final instances = await getEventInstances(
        recurrenceId: recurrenceId,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      for (final instance in instances) {
        await _firestore
            .collection(instancesCollection)
            .doc(instance.id)
            .update({'isCancelled': false});
      }
      
      print('✅ Exception supprimée et instances restaurées');
    } catch (e) {
      print('❌ Erreur suppression exception: $e');
      rethrow;
    }
  }

  /// Modifie une occurrence spécifique
  static Future<void> modifyOccurrence(
    String recurrenceId,
    DateTime originalDate,
    RecurrenceOverride override,
  ) async {
    try {
      print('✏️ Modification occurrence pour récurrence $recurrenceId');
      
      final recurrence = await getRecurrence(recurrenceId);
      if (recurrence == null) {
        print('❌ Récurrence non trouvée');
        return;
      }

      // Mettre à jour ou ajouter l'override
      final updatedOverrides = List<RecurrenceOverride>.from(recurrence.overrides)
        ..removeWhere((o) => _isSameDay(o.originalDate, originalDate))
        ..add(override);

      await updateRecurrence(recurrence.copyWith(
        overrides: updatedOverrides,
        updatedAt: DateTime.now(),
      ));

      // Mettre à jour l'instance correspondante
      final instances = await getEventInstances(
        recurrenceId: recurrenceId,
        startDate: DateTime(originalDate.year, originalDate.month, originalDate.day),
        endDate: DateTime(originalDate.year, originalDate.month, originalDate.day, 23, 59, 59),
      );

      for (final instance in instances) {
        await _firestore
            .collection(instancesCollection)
            .doc(instance.id)
            .update({
              'isOverride': true,
              'isCancelled': override.newDate == null,
              'actualDate': override.newDate != null 
                  ? Timestamp.fromDate(override.newDate!) 
                  : Timestamp.fromDate(instance.actualDate),
              'overrideData': override.toFirestore(),
            });
      }
      
      print('✅ Occurrence modifiée');
    } catch (e) {
      print('❌ Erreur modification occurrence: $e');
      rethrow;
    }
  }

  /// Génère les instances d'événement pour une récurrence
  static Future<void> _generateInstancesForRecurrence(
    EventRecurrenceModel recurrence,
    {DateTime? until}
  ) async {
    try {
      print('🔄 Génération des instances pour récurrence ${recurrence.id}');
      
      final parentEvent = await _getParentEvent(recurrence.parentEventId);
      if (parentEvent == null) {
        print('❌ Événement parent non trouvé: ${recurrence.parentEventId}');
        return;
      }

      print('📅 Événement parent trouvé: ${parentEvent.title}');
      print('📅 Date de début: ${parentEvent.startDate}');

      // Générer les dates d'occurrence
      final occurrences = recurrence.generateOccurrences(
        startDate: parentEvent.startDate,
        until: until ?? DateTime.now().add(const Duration(days: 180)),
      );

      print('✅ ${occurrences.length} occurrences générées');

      if (occurrences.isEmpty) {
        print('⚠️ Aucune occurrence générée');
        return;
      }

      // Créer les instances par batch
      final batch = _firestore.batch();
      int count = 0;

      for (final occurrence in occurrences) {
        // Vérifier si c'est une exception
        final isException = recurrence.exceptions.any((ex) => _isSameDay(ex, occurrence));
        if (isException) {
          print('🚫 Date ${occurrence.day}/${occurrence.month} est une exception, ignorée');
          continue;
        }

        // Chercher un override pour cette date
        final override = recurrence.overrides
            .where((o) => _isSameDay(o.originalDate, occurrence))
            .firstOrNull;

        final actualDate = override?.newDate ?? occurrence;
        final isCancelled = override != null && override.newDate == null;

        final instance = EventInstanceModel(
          id: '',
          parentEventId: recurrence.parentEventId,
          recurrenceId: recurrence.id,
          originalDate: occurrence,
          actualDate: actualDate,
          isOverride: override != null,
          isCancelled: isCancelled,
          overrideData: override?.toFirestore() ?? {},
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection(instancesCollection).doc();
        batch.set(docRef, instance.toFirestore());
        count++;

        // Commit par batch de 500 pour éviter les limites Firestore
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }

      // Commit final
      if (count > 0) {
        await batch.commit();
      }

      print('✅ ${occurrences.length} instances créées dans Firestore');
    } catch (e) {
      print('❌ Erreur génération instances: $e');
      rethrow;
    }
  }

  /// Régénère les instances futures après modification d'une récurrence (optimisé)
  static Future<void> _regenerateInstances(EventRecurrenceModel recurrence) async {
    try {
      print('🔄 Régénération des instances pour récurrence ${recurrence.id}');
      final now = DateTime.now();

      // Supprimer les instances futures existantes
      final existingInstances = await _firestore
          .collection(instancesCollection)
          .where('recurrenceId', isEqualTo: recurrence.id)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;
      
      for (final doc in existingInstances.docs) {
        final data = doc.data();
        final actualDate = (data['actualDate'] as Timestamp).toDate();
        if (actualDate.isAfter(now)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }
      
      await batch.commit();
      print('🗑️ $deletedCount instances futures supprimées');

      // Regénérer les nouvelles instances
      await _generateInstancesForRecurrence(
        recurrence,
        until: now.add(const Duration(days: 180)),
      );
    } catch (e) {
      print('❌ Erreur régénération: $e');
      rethrow;
    }
  }

  /// Récupère l'événement parent
  static Future<EventModel?> _getParentEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si deux dates sont le même jour
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Récupère tous les événements (récurrents et non-récurrents) pour une période (optimisé)
  static Future<List<Map<String, dynamic>>> getEventsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? searchQuery,
    List<String>? typeFilters,
  }) async {
    try {
      final events = <Map<String, dynamic>>[];

      // 1. Récupérer les événements non-récurrents avec requête optimisée
      Query query = _firestore.collection('events');
      
      // Appliquer d'abord le filtre isRecurring
      query = query.where('isRecurring', isEqualTo: false);

      final nonRecurringEvents = await query.get();
      
      for (final doc in nonRecurringEvents.docs) {
        final event = EventModel.fromFirestore(doc);
        
        // Filtrer côté client pour éviter les erreurs d'index multiples
        final eventStart = event.startDate;
        if (eventStart.isAfter(endDate) || eventStart.isBefore(startDate)) {
          continue;
        }
        
        // Filtre de type côté client
        if (typeFilters != null && typeFilters.isNotEmpty && 
            !typeFilters.contains(event.type)) {
          continue;
        }
        
        // Filtre de recherche côté client
        if (searchQuery != null && 
            !event.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
            !event.description.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }
        
        events.add({
          'event': event,
          'isRecurring': false,
          'instanceDate': event.startDate,
        });
      }

      // 2. Récupérer les instances d'événements récurrents
      final instances = await getEventInstances(
        startDate: startDate,
        endDate: endDate,
      );

      for (final instance in instances) {
        if (!instance.isCancelled) {
          final parentEvent = await _getParentEvent(instance.parentEventId);
          if (parentEvent != null) {
            if (typeFilters == null || typeFilters.isEmpty || typeFilters.contains(parentEvent.type)) {
              if (searchQuery == null || 
                  parentEvent.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  parentEvent.description.toLowerCase().contains(searchQuery.toLowerCase())) {
                events.add({
                  'event': parentEvent,
                  'isRecurring': true,
                  'instanceDate': instance.actualDate,
                  'instance': instance,
                });
              }
            }
          }
        }
      }

      // Trier par date
      events.sort((a, b) => (a['instanceDate'] as DateTime).compareTo(b['instanceDate'] as DateTime));

      return events;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Génère automatiquement les instances futures (à appeler périodiquement)
  static Future<void> generateFutureInstances() async {
    try {
      final activeRecurrences = await _firestore
          .collection(recurrencesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in activeRecurrences.docs) {
        final recurrence = EventRecurrenceModel.fromFirestore(doc);
        
        // Vérifier s'il faut générer plus d'instances
        final lastInstance = await _firestore
            .collection(instancesCollection)
            .where('recurrenceId', isEqualTo: recurrence.id)
            .orderBy('actualDate', descending: true)
            .limit(1)
            .get();

        final now = DateTime.now();
        final generateUntil = now.add(const Duration(days: 90));

        if (lastInstance.docs.isEmpty || 
            lastInstance.docs.first.data()['actualDate'].toDate().isBefore(generateUntil)) {
          
          final startFrom = lastInstance.docs.isNotEmpty 
              ? lastInstance.docs.first.data()['actualDate'].toDate().add(const Duration(days: 1))
              : now;

          final newOccurrences = recurrence.generateOccurrences(
            startDate: startFrom,
            until: generateUntil,
          );

          final batch = _firestore.batch();
          for (final occurrence in newOccurrences) {
            final instance = EventInstanceModel(
              id: '',
              parentEventId: recurrence.parentEventId,
              recurrenceId: recurrence.id,
              originalDate: occurrence,
              actualDate: occurrence,
              createdAt: now,
            );

            final docRef = _firestore.collection(instancesCollection).doc();
            batch.set(docRef, instance.toFirestore());
          }

          if (newOccurrences.isNotEmpty) {
            await batch.commit();
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la génération automatique des instances: $e');
    }
  }
}
