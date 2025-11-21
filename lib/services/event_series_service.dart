import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../auth/auth_service.dart';

/// Service pour gérer les séries d'événements récurrents (Style Google Calendar)
/// 
/// Principe : Chaque occurrence est un événement à part entière dans Firestore.
/// Les occurrences sont liées par un `seriesId` commun.
/// 
/// Avantages :
/// - Modification facile d'une occurrence spécifique
/// - Suppression flexible (une, futures, toutes)
/// - Indépendance totale des occurrences
/// - Compatible avec tous les outils existants
class EventSeriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String eventsCollection = 'events';

  /// Crée une série d'événements récurrents (génère N événements individuels)
  /// 
  /// [masterEvent] : L'événement maître contenant toutes les informations de base
  /// [recurrence] : La règle de récurrence pour générer les occurrences
  /// [preGenerateMonths] : Nombre de mois à générer à l'avance (par défaut 6) - utilisé uniquement si endType = never
  /// 
  /// Priorité de fin de récurrence :
  /// 1. endDate (si endType = onDate) ← Date choisie par l'utilisateur
  /// 2. occurrences (si endType = afterOccurrences) ← Nombre d'occurrences
  /// 3. preGenerateMonths (si endType = never) ← 6 mois par défaut
  /// 
  /// Retourne la liste des IDs des événements créés
  static Future<List<String>> createRecurringSeries({
    required EventModel masterEvent,
    required EventRecurrence recurrence,
    int preGenerateMonths = 6,
  }) async {
    try {
      print('📅 Création série récurrente: ${masterEvent.title}');
      print('   Règle: ${recurrence.description}');
      
      // Générer un ID unique pour la série
      final seriesId = 'series_${DateTime.now().millisecondsSinceEpoch}_${masterEvent.title.hashCode}';
      
      // Calculer les dates d'occurrences selon le type de fin
      // Priorité : endDate > occurrences > preGenerateMonths
      final DateTime until;
      
      if (recurrence.endType == RecurrenceEndType.onDate && recurrence.endDate != null) {
        // Cas 1 : Date de fin spécifique
        until = recurrence.endDate!;
        print('   Mode: Date de fin définie');
        print('   Date de fin: ${until.toString().split(' ')[0]}');
      } else if (recurrence.endType == RecurrenceEndType.afterOccurrences && recurrence.occurrences != null) {
        // Cas 2 : Nombre d'occurrences spécifique
        // On génère suffisamment loin pour être sûr d'avoir assez d'occurrences
        // La méthode generateOccurrences s'arrêtera au bon nombre
        until = DateTime.now().add(const Duration(days: 365 * 10)); // 10 ans max
        print('   Mode: Nombre d\'occurrences limité');
        print('   Nombre d\'occurrences: ${recurrence.occurrences}');
      } else {
        // Cas 3 : Jamais (utilise preGenerateMonths)
        until = DateTime.now().add(Duration(days: 30 * preGenerateMonths));
        print('   Mode: Génération automatique');
        print('   Pré-génération: $preGenerateMonths mois (jusqu\'au ${until.toString().split(' ')[0]})');
      }
      
      final occurrenceDates = recurrence.generateOccurrences(
        masterEvent.startDate,
        masterEvent.startDate,
        until,
      );
      
      print('   Occurrences à créer: ${occurrenceDates.length}');
      
      if (occurrenceDates.isEmpty) {
        throw Exception('Aucune occurrence générée avec cette règle de récurrence');
      }
      
      // Créer les événements en batch (max 500 par batch Firestore)
      final List<String> createdIds = [];
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (int i = 0; i < occurrenceDates.length; i++) {
        final occurrenceDate = occurrenceDates[i];
        
        // Calculer la date de fin si l'événement original a une durée
        DateTime? endDate;
        if (masterEvent.endDate != null) {
          final duration = masterEvent.endDate!.difference(masterEvent.startDate);
          endDate = occurrenceDate.add(duration);
        }
        
        // Créer l'événement pour cette occurrence
        final docRef = _firestore.collection(eventsCollection).doc();
        final occurrenceEvent = masterEvent.copyWith(
          startDate: occurrenceDate,
          endDate: endDate,
          seriesId: seriesId,
          isSeriesMaster: i == 0, // Le premier est le maître
          isModifiedOccurrence: false,
          originalStartDate: occurrenceDate,
          occurrenceIndex: i,
          updatedAt: DateTime.now(),
        );
        
        // Ne pas inclure l'ID dans toFirestore car Firestore le génère
        final eventData = occurrenceEvent.toFirestore();
        batch.set(docRef, eventData);
        createdIds.add(docRef.id);
        
        batchCount++;
        
        // Firestore limite à 500 opérations par batch
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
          print('   ✅ Batch de 500 événements créé');
        }
      }
      
      // Commit le dernier batch s'il reste des opérations
      if (batchCount > 0) {
        await batch.commit();
        print('   ✅ Batch final de $batchCount événements créé');
      }
      
      print('✅ Série créée: ${createdIds.length} événements (ID: $seriesId)');
      return createdIds;
      
    } catch (e) {
      print('❌ Erreur création série: $e');
      rethrow;
    }
  }

  /// Récupère tous les événements d'une série (non supprimés)
  static Future<List<EventModel>> getSeriesEvents(String seriesId) async {
    try {
      final snapshot = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('deletedAt', isNull: true)
          .orderBy('startDate')
          .get();
      
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération série: $e');
      return [];
    }
  }

  /// Récupère l'événement maître d'une série
  static Future<EventModel?> getSeriesMaster(String seriesId) async {
    try {
      final snapshot = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('isSeriesMaster', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return EventModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Erreur récupération maître: $e');
      return null;
    }
  }

  /// Modifie une occurrence spécifique (et seulement celle-ci)
  static Future<void> updateSingleOccurrence(
    String eventId,
    EventModel updatedEvent,
  ) async {
    try {
      print('✏️ Modification occurrence unique: $eventId');
      
      // Marquer comme modifiée si les propriétés importantes ont changé
      final isModified = updatedEvent.originalStartDate != null &&
          !_isSameDateTime(updatedEvent.startDate, updatedEvent.originalStartDate!);
      
      final eventToSave = updatedEvent.copyWith(
        isModifiedOccurrence: isModified,
        updatedAt: DateTime.now(),
        lastModifiedBy: AuthService.currentUser?.uid,
      );
      
      await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .update(eventToSave.toFirestore());
      
      print('✅ Occurrence modifiée');
    } catch (e) {
      print('❌ Erreur modification occurrence: $e');
      rethrow;
    }
  }

  /// Modifie cette occurrence ET toutes les occurrences futures
  static Future<void> updateThisAndFutureOccurrences(
    String eventId,
    EventModel updatedEvent,
  ) async {
    try {
      print('✏️ Modification occurrence et futures: $eventId');
      
      // Récupérer l'événement actuel pour avoir sa date
      final currentEvent = await _getEventById(eventId);
      if (currentEvent == null) {
        throw Exception('Événement non trouvé');
      }
      
      // Récupérer toutes les occurrences futures (y compris celle-ci)
      final futureEvents = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: currentEvent.seriesId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(currentEvent.startDate))
          .where('deletedAt', isNull: true)
          .get();
      
      print('   Occurrences futures à modifier: ${futureEvents.docs.length}');
      
      // Mettre à jour en batch
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final doc in futureEvents.docs) {
        final event = EventModel.fromFirestore(doc);
        
        // Calculer la nouvelle date en préservant l'intervalle relatif
        DateTime newStartDate;
        if (doc.id == eventId) {
          // Pour l'événement actuel, utiliser la nouvelle date fournie
          newStartDate = updatedEvent.startDate;
        } else {
          // Pour les événements futurs, calculer l'offset
          final offset = event.startDate.difference(currentEvent.startDate);
          newStartDate = updatedEvent.startDate.add(offset);
        }
        
        DateTime? newEndDate;
        if (updatedEvent.endDate != null) {
          final duration = updatedEvent.endDate!.difference(updatedEvent.startDate);
          newEndDate = newStartDate.add(duration);
        }
        
        final eventToUpdate = event.copyWith(
          title: updatedEvent.title,
          description: updatedEvent.description,
          location: updatedEvent.location,
          startDate: newStartDate,
          endDate: newEndDate,
          type: updatedEvent.type,
          visibility: updatedEvent.visibility,
          responsibleIds: updatedEvent.responsibleIds,
          imageUrl: updatedEvent.imageUrl,
          isModifiedOccurrence: false, // Reset car on applique uniformément
          updatedAt: DateTime.now(),
          lastModifiedBy: AuthService.currentUser?.uid,
        );
        
        batch.update(doc.reference, eventToUpdate.toFirestore());
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ ${futureEvents.docs.length} occurrences futures modifiées');
    } catch (e) {
      print('❌ Erreur modification occurrences futures: $e');
      rethrow;
    }
  }

  /// Modifie TOUTES les occurrences de la série
  static Future<void> updateAllOccurrences(
    String seriesId,
    EventModel updatedEvent,
  ) async {
    try {
      print('✏️ Modification toutes occurrences série: $seriesId');
      
      final allEvents = await getSeriesEvents(seriesId);
      print('   Occurrences à modifier: ${allEvents.length}');
      
      if (allEvents.isEmpty) {
        throw Exception('Aucun événement trouvé pour cette série');
      }
      
      // Récupérer la date de référence (première occurrence)
      final firstEvent = allEvents.first;
      
      // Mettre à jour en batch
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final event in allEvents) {
        // Calculer la nouvelle date en préservant l'intervalle
        final offset = event.startDate.difference(firstEvent.startDate);
        final newStartDate = updatedEvent.startDate.add(offset);
        
        DateTime? newEndDate;
        if (updatedEvent.endDate != null) {
          final duration = updatedEvent.endDate!.difference(updatedEvent.startDate);
          newEndDate = newStartDate.add(duration);
        }
        
        final eventToUpdate = event.copyWith(
          title: updatedEvent.title,
          description: updatedEvent.description,
          location: updatedEvent.location,
          startDate: newStartDate,
          endDate: newEndDate,
          type: updatedEvent.type,
          visibility: updatedEvent.visibility,
          responsibleIds: updatedEvent.responsibleIds,
          imageUrl: updatedEvent.imageUrl,
          isModifiedOccurrence: false, // Reset
          updatedAt: DateTime.now(),
          lastModifiedBy: AuthService.currentUser?.uid,
        );
        
        batch.update(
          _firestore.collection(eventsCollection).doc(event.id),
          eventToUpdate.toFirestore(),
        );
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ ${allEvents.length} occurrences modifiées');
    } catch (e) {
      print('❌ Erreur modification toutes occurrences: $e');
      rethrow;
    }
  }

  /// Supprime une occurrence spécifique (soft delete)
  static Future<void> deleteSingleOccurrence(String eventId) async {
    try {
      print('🗑️ Suppression occurrence unique: $eventId');
      
      await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .update({
            'deletedAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'lastModifiedBy': AuthService.currentUser?.uid,
          });
      
      print('✅ Occurrence supprimée (soft delete)');
    } catch (e) {
      print('❌ Erreur suppression occurrence: $e');
      rethrow;
    }
  }

  /// Supprime cette occurrence ET toutes les futures
  static Future<void> deleteThisAndFutureOccurrences(String eventId) async {
    try {
      print('🗑️ Suppression occurrence et futures: $eventId');
      
      final currentEvent = await _getEventById(eventId);
      if (currentEvent == null) {
        throw Exception('Événement non trouvé');
      }
      
      final futureEvents = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: currentEvent.seriesId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(currentEvent.startDate))
          .where('deletedAt', isNull: true)
          .get();
      
      print('   Occurrences futures à supprimer: ${futureEvents.docs.length}');
      
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final doc in futureEvents.docs) {
        batch.update(doc.reference, {
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'lastModifiedBy': AuthService.currentUser?.uid,
        });
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ ${futureEvents.docs.length} occurrences supprimées');
    } catch (e) {
      print('❌ Erreur suppression occurrences futures: $e');
      rethrow;
    }
  }

  /// Supprime toute la série (soft delete)
  static Future<void> deleteAllOccurrences(String seriesId) async {
    try {
      print('🗑️ Suppression série complète: $seriesId');
      
      final allEvents = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('deletedAt', isNull: true)
          .get();
      
      print('   Occurrences à supprimer: ${allEvents.docs.length}');
      
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final doc in allEvents.docs) {
        batch.update(doc.reference, {
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'lastModifiedBy': AuthService.currentUser?.uid,
        });
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ ${allEvents.docs.length} occurrences supprimées');
    } catch (e) {
      print('❌ Erreur suppression série: $e');
      rethrow;
    }
  }

  /// Génère des occurrences supplémentaires (quand on approche de la fin)
  static Future<void> extendSeries(
    String seriesId,
    int additionalMonths,
  ) async {
    try {
      print('📅 Extension série: $seriesId (+$additionalMonths mois)');
      
      // Récupérer l'événement maître
      final master = await getSeriesMaster(seriesId);
      if (master == null || master.recurrence == null) {
        throw Exception('Événement maître ou récurrence non trouvée');
      }
      
      // Récupérer la dernière occurrence
      final allEvents = await getSeriesEvents(seriesId);
      if (allEvents.isEmpty) {
        throw Exception('Aucune occurrence existante');
      }
      
      final lastEvent = allEvents.last;
      final lastOccurrenceIndex = lastEvent.occurrenceIndex ?? allEvents.length - 1;
      
      // Générer les nouvelles occurrences
      final until = lastEvent.startDate.add(Duration(days: 30 * additionalMonths));
      final newOccurrenceDates = master.recurrence!.generateOccurrences(
        lastEvent.startDate.add(const Duration(days: 1)), // Commencer après la dernière
        lastEvent.startDate.add(const Duration(days: 1)),
        until,
      );
      
      print('   Nouvelles occurrences: ${newOccurrenceDates.length}');
      
      if (newOccurrenceDates.isEmpty) {
        print('   Aucune nouvelle occurrence à créer');
        return;
      }
      
      // Créer les nouveaux événements
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (int i = 0; i < newOccurrenceDates.length; i++) {
        final occurrenceDate = newOccurrenceDates[i];
        
        DateTime? endDate;
        if (master.endDate != null) {
          final duration = master.endDate!.difference(master.startDate);
          endDate = occurrenceDate.add(duration);
        }
        
        final docRef = _firestore.collection(eventsCollection).doc();
        final newEvent = master.copyWith(
          startDate: occurrenceDate,
          endDate: endDate,
          isSeriesMaster: false,
          isModifiedOccurrence: false,
          originalStartDate: occurrenceDate,
          occurrenceIndex: lastOccurrenceIndex + 1 + i,
          updatedAt: DateTime.now(),
        );
        
        batch.set(docRef, newEvent.toFirestore());
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ ${newOccurrenceDates.length} occurrences ajoutées');
    } catch (e) {
      print('❌ Erreur extension série: $e');
      rethrow;
    }
  }

  /// Récupère le nombre d'occurrences d'une série
  static Future<int> getSeriesCount(String seriesId) async {
    try {
      final snapshot = await _firestore
          .collection(eventsCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('deletedAt', isNull: true)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage série: $e');
      return 0;
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  static Future<EventModel?> _getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .get();
      
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Erreur récupération événement: $e');
      return null;
    }
  }

  static bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}
