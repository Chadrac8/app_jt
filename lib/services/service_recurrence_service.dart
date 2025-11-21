import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/event_model.dart';

/// Service pour gérer les récurrences de services (Style Planning Center Online)
/// 
/// Principe : Chaque occurrence de service est un ServiceModel autonome dans Firestore.
/// Les occurrences sont liées par un `seriesId` commun.
/// 
/// Avantages :
/// - Chaque occurrence a sa propre date/heure
/// - Modifications isolées d'une occurrence spécifique
/// - Suppression flexible (une, futures, toutes)
/// - Gestion des exceptions et modifications
/// - Compatible avec tous les outils existants
class ServiceRecurrenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String servicesCollection = 'services';

  /// Crée une série de services récurrents
  /// 
  /// [masterService] : Le service maître contenant toutes les informations de base
  /// [recurrencePattern] : Le pattern de récurrence
  /// [preGenerateMonths] : Nombre de mois à générer à l'avance (par défaut 6)
  /// 
  /// Retourne la liste des IDs des services créés
  static Future<List<String>> createRecurringSeries({
    required ServiceModel masterService,
    required Map<String, dynamic> recurrencePattern,
    int preGenerateMonths = 6,
  }) async {
    try {
      print('🔄 Création série services récurrents: ${masterService.name}');
      
      // Générer un ID unique pour la série
      final seriesId = 'series_${DateTime.now().millisecondsSinceEpoch}_${masterService.name.hashCode}';
      
      // Convertir le pattern en EventRecurrence pour générer les dates
      final eventRecurrence = _convertPatternToEventRecurrence(
        recurrencePattern,
        masterService.dateTime,
      );
      
      // Calculer la date limite pour la génération
      final DateTime until;
      if (eventRecurrence.endType == RecurrenceEndType.onDate && eventRecurrence.endDate != null) {
        until = eventRecurrence.endDate!;
      } else if (eventRecurrence.endType == RecurrenceEndType.afterOccurrences && eventRecurrence.occurrences != null) {
        until = DateTime.now().add(const Duration(days: 365 * 2)); // 2 ans max pour trouver les occurrences
      } else {
        until = DateTime.now().add(Duration(days: 30 * preGenerateMonths));
      }
      
      // Générer les dates d'occurrences
      final occurrenceDates = eventRecurrence.generateOccurrences(
        masterService.dateTime,
        masterService.dateTime,
        until,
      );
      
      print('   Occurrences à créer: ${occurrenceDates.length}');
      
      if (occurrenceDates.isEmpty) {
        throw Exception('Aucune occurrence générée avec cette règle de récurrence');
      }
      
      // Créer les services en batch
      final List<String> createdIds = [];
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (int i = 0; i < occurrenceDates.length; i++) {
        final occurrenceDate = occurrenceDates[i];
        
        // Créer le service pour cette occurrence
        final docRef = _firestore.collection(servicesCollection).doc();
        final occurrenceService = masterService.copyWith(
          dateTime: occurrenceDate,
          seriesId: seriesId,
          parentServiceId: i == 0 ? null : masterService.id, // Le maître n'a pas de parent
          isSeriesMaster: i == 0, // Le premier est le maître
          occurrenceIndex: i,
          originalDateTime: occurrenceDate, // Date originale pour détecter les modifications
          isModifiedOccurrence: false,
          updatedAt: DateTime.now(),
        );
        
        final serviceData = occurrenceService.toFirestore();
        batch.set(docRef, serviceData);
        createdIds.add(docRef.id);
        
        batchCount++;
        
        // Firestore limite à 500 opérations par batch
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
          print('   ✅ Batch de 500 services créé');
        }
      }
      
      // Commit le dernier batch s'il reste des opérations
      if (batchCount > 0) {
        await batch.commit();
        print('   ✅ Batch final de $batchCount services créé');
      }
      
      print('✅ Série services créée: ${createdIds.length} occurrences (ID: $seriesId)');
      return createdIds;
      
    } catch (e) {
      print('❌ Erreur création série services: $e');
      rethrow;
    }
  }

  /// Récupère tous les services d'une série
  static Future<List<ServiceModel>> getSeriesServices(String seriesId) async {
    try {
      final snapshot = await _firestore
          .collection(servicesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération série services: $e');
      return [];
    }
  }

  /// Modifie une occurrence spécifique dans une série
  /// 
  /// [serviceId] : ID du service à modifier
  /// [updates] : Modifications à appliquer
  /// [updateFutures] : true pour modifier aussi les occurrences futures
  static Future<void> updateOccurrence({
    required String serviceId,
    required Map<String, dynamic> updates,
    bool updateFutures = false,
  }) async {
    try {
      print('🔄 Modification occurrence service: $serviceId');
      
      final service = await getService(serviceId);
      if (service == null) {
        throw Exception('Service non trouvé');
      }
      
      if (!service.isRecurring || service.seriesId == null) {
        // Service simple, modification directe
        await _updateSingleService(serviceId, updates);
        return;
      }
      
      if (updateFutures) {
        // Modifier cette occurrence et toutes les futures
        print('   Mode: Modification occurrence + futures');
        await _updateFuturesOccurrences(service, updates);
      } else {
        // Modifier seulement cette occurrence
        print('   Mode: Modification occurrence uniquement');
        await _updateSingleOccurrence(service, updates);
      }
      
      print('✅ Occurrence(s) modifiée(s)');
    } catch (e) {
      print('❌ Erreur modification occurrence: $e');
      rethrow;
    }
  }

  /// Supprime une occurrence spécifique ou plusieurs occurrences
  /// 
  /// [serviceId] : ID du service à supprimer
  /// [deleteScope] : 'this' | 'future' | 'all'
  static Future<void> deleteOccurrence({
    required String serviceId,
    required String deleteScope, // 'this', 'future', 'all'
  }) async {
    try {
      print('🗑️ Suppression occurrence service: $serviceId (scope: $deleteScope)');
      
      final service = await getService(serviceId);
      if (service == null) {
        throw Exception('Service non trouvé');
      }
      
      if (!service.isRecurring || service.seriesId == null) {
        // Service simple, suppression directe
        await _deleteSingleService(serviceId);
        return;
      }
      
      switch (deleteScope) {
        case 'this':
          // Supprimer seulement cette occurrence
          await _deleteSingleService(serviceId);
          break;
          
        case 'future':
          // Supprimer cette occurrence et toutes les futures
          await _deleteFutureOccurrences(service);
          break;
          
        case 'all':
          // Supprimer toute la série
          await _deleteAllOccurrences(service.seriesId!);
          break;
      }
      
      print('✅ Occurrence(s) supprimée(s)');
    } catch (e) {
      print('❌ Erreur suppression occurrence: $e');
      rethrow;
    }
  }

  /// Ajoute une exception (date à exclure) dans une série
  static Future<void> addException({
    required String seriesId,
    required DateTime exceptionDate,
  }) async {
    try {
      print('➕ Ajout exception série: $seriesId, date: $exceptionDate');
      
      // Trouver le service maître de la série
      final masterService = await _getSeriesMaster(seriesId);
      if (masterService == null) {
        throw Exception('Service maître de la série non trouvé');
      }
      
      // Ajouter l'exception à la liste
      final newExceptions = List<String>.from(masterService.exceptions);
      final exceptionString = exceptionDate.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      
      if (!newExceptions.contains(exceptionString)) {
        newExceptions.add(exceptionString);
        
        // Mettre à jour le service maître
        await _updateSingleService(masterService.id, {
          'exceptions': newExceptions,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        // Supprimer l'occurrence correspondante si elle existe
        await _deleteOccurrenceByDate(seriesId, exceptionDate);
      }
      
      print('✅ Exception ajoutée');
    } catch (e) {
      print('❌ Erreur ajout exception: $e');
      rethrow;
    }
  }

  /// Récupère un service par son ID
  static Future<ServiceModel?> getService(String serviceId) async {
    try {
      final doc = await _firestore.collection(servicesCollection).doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération service: $e');
      return null;
    }
  }

  // ===== MÉTHODES PRIVÉES =====

  /// Convertit un pattern de récurrence en EventRecurrence
  static EventRecurrence _convertPatternToEventRecurrence(
    Map<String, dynamic> pattern,
    DateTime startDate,
  ) {
    final type = pattern['type']?.toString().toLowerCase() ?? 'weekly';
    final interval = pattern['interval'] ?? 1;
    final endDate = pattern['endDate'] != null
        ? DateTime.parse(pattern['endDate'])
        : null;
    final occurrenceCount = pattern['occurrenceCount'];
    
    final endType = occurrenceCount != null
        ? RecurrenceEndType.afterOccurrences
        : (endDate != null ? RecurrenceEndType.onDate : RecurrenceEndType.never);

    List<WeekDay>? daysOfWeek;
    if (pattern['daysOfWeek'] != null) {
      daysOfWeek = (pattern['daysOfWeek'] as List)
          .map((day) => _mapIntToWeekDay(day as int))
          .toList();
    }

    switch (type) {
      case 'daily':
        return EventRecurrence.daily(
          interval: interval,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
      
      case 'weekly':
        return EventRecurrence.weekly(
          interval: interval,
          daysOfWeek: daysOfWeek ?? [_getWeekDayFromDate(startDate)],
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
      
      case 'monthly':
        return EventRecurrence.monthly(
          interval: interval,
          dayOfMonth: pattern['dayOfMonth'] ?? startDate.day,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
      
      case 'yearly':
        return EventRecurrence.yearly(
          interval: interval,
          monthOfYear: pattern['monthOfYear'] ?? startDate.month,
          dayOfMonth: pattern['dayOfMonth'] ?? startDate.day,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
      
      default:
        return EventRecurrence.weekly(
          interval: interval,
          daysOfWeek: [_getWeekDayFromDate(startDate)],
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
    }
  }

  static WeekDay _mapIntToWeekDay(int day) {
    switch (day) {
      case 1: return WeekDay.monday;
      case 2: return WeekDay.tuesday;
      case 3: return WeekDay.wednesday;
      case 4: return WeekDay.thursday;
      case 5: return WeekDay.friday;
      case 6: return WeekDay.saturday;
      case 7: return WeekDay.sunday;
      default: return WeekDay.sunday;
    }
  }

  static WeekDay _getWeekDayFromDate(DateTime date) {
    return _mapIntToWeekDay(date.weekday);
  }

  static Future<void> _updateSingleService(String serviceId, Map<String, dynamic> updates) async {
    await _firestore.collection(servicesCollection).doc(serviceId).update(updates);
  }

  static Future<void> _updateSingleOccurrence(ServiceModel service, Map<String, dynamic> updates) async {
    // Marquer comme occurrence modifiée
    updates['isModifiedOccurrence'] = true;
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    
    await _updateSingleService(service.id, updates);
  }

  static Future<void> _updateFuturesOccurrences(ServiceModel service, Map<String, dynamic> updates) async {
    final snapshot = await _firestore
        .collection(servicesCollection)
        .where('seriesId', isEqualTo: service.seriesId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(service.dateTime))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      batch.update(doc.reference, updates);
    }
    
    await batch.commit();
  }

  static Future<void> _deleteSingleService(String serviceId) async {
    await _firestore.collection(servicesCollection).doc(serviceId).delete();
  }

  static Future<void> _deleteFutureOccurrences(ServiceModel service) async {
    final snapshot = await _firestore
        .collection(servicesCollection)
        .where('seriesId', isEqualTo: service.seriesId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(service.dateTime))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  static Future<void> _deleteAllOccurrences(String seriesId) async {
    final snapshot = await _firestore
        .collection(servicesCollection)
        .where('seriesId', isEqualTo: seriesId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  static Future<ServiceModel?> _getSeriesMaster(String seriesId) async {
    final snapshot = await _firestore
        .collection(servicesCollection)
        .where('seriesId', isEqualTo: seriesId)
        .where('isSeriesMaster', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ServiceModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  static Future<void> _deleteOccurrenceByDate(String seriesId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection(servicesCollection)
        .where('seriesId', isEqualTo: seriesId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}