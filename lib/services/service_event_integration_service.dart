import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/event_model.dart';
import '../models/event_recurrence_model.dart';
import 'events_firebase_service.dart';
import 'event_recurrence_service.dart';
import 'service_notification_service.dart';

/// Service d'intégration entre Services et Événements
/// Inspiré de Planning Center Online où chaque service est un événement
class ServiceEventIntegrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crée un service et son événement lié automatiquement
  static Future<String> createServiceWithEvent(ServiceModel service) async {
    try {
      print('🎯 Création service avec événement lié: ${service.name}');
      
      // 1. Créer l'objet EventRecurrence si le service est récurrent
      EventRecurrence? eventRecurrence;
      if (service.isRecurring && service.recurrencePattern != null) {
        eventRecurrence = _convertServicePatternToEventRecurrence(
          service.recurrencePattern!,
          service.dateTime,
        );
      }

      // 2. Créer l'événement associé avec la récurrence incluse
      final event = EventModel(
        id: '',
        title: service.name,
        description: service.description ?? '',
        type: 'culte', // Type événement pour services
        startDate: service.dateTime,
        endDate: service.dateTime.add(Duration(minutes: service.durationMinutes)),
        location: service.location,
        visibility: 'publique',
        responsibleIds: [],
        visibilityTargets: [],
        status: service.status,
        isRegistrationEnabled: true, // ✅ ACTIVER LES INSCRIPTIONS
        maxParticipants: null,
        hasWaitingList: true, // ✅ ACTIVER LISTE D'ATTENTE
        isRecurring: service.isRecurring,
        recurrence: eventRecurrence, // ✅ AJOUTER LA RÉCURRENCE DIRECTEMENT
        imageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: service.createdBy,
        isServiceEvent: true, // ✅ NOUVEAU: Marquer comme événement-service
      );

      final eventId = await EventsFirebaseService.createEvent(event);
      print('✅ Événement créé: $eventId');

      // 3. Si récurrent, créer AUSSI la règle de récurrence dans event_recurrences (pour compatibilité)
      if (service.isRecurring && service.recurrencePattern != null) {
        await _createRecurrenceFromServicePattern(
          eventId,
          service.recurrencePattern!,
          service.dateTime,
        );
      }

      // 3. Créer le service avec le lien vers l'événement
      final serviceWithEvent = service.copyWith(linkedEventId: eventId);
      final serviceId = await _createService(serviceWithEvent);
      
      // 4. ✅ NOUVEAU: Mettre à jour l'événement avec le lien vers le service
      await _updateEventWithServiceLink(eventId, serviceId);
      
      // 5. ✅ NOUVEAU: Envoyer notifications
      await ServiceNotificationService.notifyNewService(serviceWithEvent);
      await ServiceNotificationService.scheduleServiceReminder(serviceWithEvent);
      
      print('✅ Service créé avec succès: $serviceId (lié à événement $eventId)');
      return serviceId;
    } catch (e) {
      print('❌ Erreur création service avec événement: $e');
      rethrow;
    }
  }

  /// Met à jour un service et synchronise avec son événement lié
  static Future<void> updateServiceWithEvent(ServiceModel service) async {
    try {
      print('🔄 Mise à jour service et événement: ${service.id}');
      
      // 1. Mettre à jour le service
      await _updateService(service);

      // 2. Si lié à un événement, synchroniser
      if (service.linkedEventId != null) {
        final event = await EventsFirebaseService.getEvent(service.linkedEventId!);
        if (event != null) {
          final updatedEvent = event.copyWith(
            title: service.name,
            description: service.description ?? '',
            startDate: service.dateTime,
            endDate: service.dateTime.add(Duration(minutes: service.durationMinutes)),
            location: service.location,
            status: service.status,
            isRecurring: service.isRecurring, // ✅ Synchroniser flag récurrence
            updatedAt: DateTime.now(),
          );
          await EventsFirebaseService.updateEvent(updatedEvent);
          print('✅ Événement synchronisé');
          
          // ✅ NOUVEAU: Gérer les changements de récurrence
          if (service.isRecurring && service.recurrencePattern != null) {
            await _updateRecurrencePattern(
              service.linkedEventId!,
              service.recurrencePattern!,
              service.dateTime,
            );
          } else if (!service.isRecurring) {
            // Supprimer la récurrence si le service n'est plus récurrent
            await _removeRecurrence(service.linkedEventId!);
          }
          
          // ✅ NOUVEAU: Notifier les changements
          await ServiceNotificationService.notifyServiceUpdate(service);
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour service/événement: $e');
      rethrow;
    }
  }

  /// Supprime un service et son événement lié
  static Future<void> deleteServiceWithEvent(String serviceId) async {
    try {
      print('🗑️ Suppression service et événement: $serviceId');
      
      final service = await getService(serviceId);
      if (service == null) return;

      // ✅ NOUVEAU: Notifier l'annulation si le service est publié
      if (service.status == 'publie') {
        await ServiceNotificationService.notifyServiceCancellation(service);
      }

      // 1. Supprimer l'événement lié (et ses récurrences/instances)
      if (service.linkedEventId != null) {
        await EventsFirebaseService.deleteEvent(service.linkedEventId!);
        print('✅ Événement lié supprimé');
      }

      // 2. Supprimer le service
      await _firestore.collection('services').doc(serviceId).delete();
      print('✅ Service supprimé');
    } catch (e) {
      print('❌ Erreur suppression service/événement: $e');
      rethrow;
    }
  }

  /// Récupère un service
  static Future<ServiceModel?> getService(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération service: $e');
      return null;
    }
  }

  /// Crée une règle de récurrence à partir du pattern de service
  static Future<void> _createRecurrenceFromServicePattern(
    String eventId,
    Map<String, dynamic> pattern,
    DateTime startDate,
  ) async {
    try {
      // Convertir le pattern de service en EventRecurrenceModel
      final recurrence = EventRecurrenceModel(
        id: '',
        parentEventId: eventId,
        type: _mapPatternToRecurrenceType(pattern['type'] ?? 'weekly'),
        interval: pattern['interval'] ?? 1,
        daysOfWeek: pattern['daysOfWeek'] != null 
            ? List<int>.from(pattern['daysOfWeek']) 
            : null,
        dayOfMonth: pattern['dayOfMonth'],
        monthsOfYear: pattern['monthsOfYear'] != null
            ? List<int>.from(pattern['monthsOfYear'])
            : null,
        endDate: pattern['endDate'] != null
            ? DateTime.parse(pattern['endDate'])
            : null,
        occurrenceCount: pattern['occurrenceCount'],
        exceptions: [],
        overrides: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await EventRecurrenceService.createRecurrence(recurrence);
      print('✅ Récurrence créée pour le service');
    } catch (e) {
      print('❌ Erreur création récurrence: $e');
      rethrow;
    }
  }

  /// Mappe le type de pattern de service vers RecurrenceType
  static RecurrenceType _mapPatternToRecurrenceType(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'yearly':
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.weekly;
    }
  }

  /// Convertit un pattern de service en EventRecurrence pour l'EventModel
  static EventRecurrence _convertServicePatternToEventRecurrence(
    Map<String, dynamic> pattern,
    DateTime startDate,
  ) {
    final type = pattern['type']?.toString().toLowerCase() ?? 'weekly';
    final interval = pattern['interval'] ?? 1;
    final endDate = pattern['endDate'] != null
        ? DateTime.parse(pattern['endDate'])
        : null;
    final occurrenceCount = pattern['occurrenceCount'];
    
    // Déterminer le type de fin
    final endType = occurrenceCount != null
        ? RecurrenceEndType.afterOccurrences
        : (endDate != null ? RecurrenceEndType.onDate : RecurrenceEndType.never);

    // Convertir les jours de semaine si présents
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

  /// Mappe un entier vers WeekDay
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

  /// Récupère le WeekDay d'une date
  static WeekDay _getWeekDayFromDate(DateTime date) {
    return _mapIntToWeekDay(date.weekday);
  }

  /// Crée un service dans Firestore
  static Future<String> _createService(ServiceModel service) async {
    final docRef = await _firestore.collection('services').add(service.toFirestore());
    return docRef.id;
  }

  /// Met à jour un service dans Firestore
  static Future<void> _updateService(ServiceModel service) async {
    await _firestore
        .collection('services')
        .doc(service.id)
        .update(service.toFirestore());
  }

  /// ✅ NOUVEAU: Met à jour l'événement avec le lien vers le service
  static Future<void> _updateEventWithServiceLink(String eventId, String serviceId) async {
    try {
      final event = await EventsFirebaseService.getEvent(eventId);
      if (event != null) {
        final updatedEvent = event.copyWith(
          linkedServiceId: serviceId,
          isServiceEvent: true,
          updatedAt: DateTime.now(),
        );
        await EventsFirebaseService.updateEvent(updatedEvent);
        print('✅ Événement $eventId lié au service $serviceId');
      }
    } catch (e) {
      print('❌ Erreur mise à jour lien événement→service: $e');
    }
  }

  /// ✅ NOUVEAU: Met à jour le pattern de récurrence d'un événement
  static Future<void> _updateRecurrencePattern(
    String eventId,
    Map<String, dynamic> pattern,
    DateTime startDate,
  ) async {
    try {
      // Récupérer la récurrence existante
      final existingRecurrences = await EventRecurrenceService.getEventRecurrences(eventId);
      
      if (existingRecurrences.isNotEmpty) {
        // Mettre à jour la récurrence existante
        final existing = existingRecurrences.first;
        final updated = existing.copyWith(
          type: _mapPatternToRecurrenceType(pattern['type'] ?? 'weekly'),
          interval: pattern['interval'] ?? 1,
          daysOfWeek: pattern['daysOfWeek'] != null 
              ? List<int>.from(pattern['daysOfWeek']) 
              : null,
          dayOfMonth: pattern['dayOfMonth'],
          monthsOfYear: pattern['monthsOfYear'] != null
              ? List<int>.from(pattern['monthsOfYear'])
              : null,
          endDate: pattern['endDate'] != null
              ? DateTime.parse(pattern['endDate'])
              : null,
          occurrenceCount: pattern['occurrenceCount'],
          updatedAt: DateTime.now(),
        );
        await EventRecurrenceService.updateRecurrence(updated);
        print('✅ Récurrence mise à jour pour événement $eventId');
      } else {
        // Créer une nouvelle récurrence
        await _createRecurrenceFromServicePattern(eventId, pattern, startDate);
        print('✅ Nouvelle récurrence créée pour événement $eventId');
      }
    } catch (e) {
      print('❌ Erreur mise à jour récurrence: $e');
    }
  }

  /// ✅ NOUVEAU: Supprime la récurrence d'un événement
  static Future<void> _removeRecurrence(String eventId) async {
    try {
      final recurrences = await EventRecurrenceService.getEventRecurrences(eventId);
      for (final recurrence in recurrences) {
        await EventRecurrenceService.deleteRecurrence(recurrence.id);
      }
      print('✅ Récurrence supprimée pour événement $eventId');
    } catch (e) {
      print('❌ Erreur suppression récurrence: $e');
    }
  }

  /// Récupère l'événement lié à un service
  static Future<EventModel?> getLinkedEvent(String serviceId) async {
    try {
      final service = await getService(serviceId);
      if (service?.linkedEventId != null) {
        return await EventsFirebaseService.getEvent(service!.linkedEventId!);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération événement lié: $e');
      return null;
    }
  }

  /// Récupère le service lié à un événement
  static Future<ServiceModel?> getServiceByEventId(String eventId) async {
    try {
      final query = await _firestore
          .collection('services')
          .where('linkedEventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ServiceModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération service par événement: $e');
      return null;
    }
  }

  // ========== 🔄 FONCTIONNALITÉS DE FLEXIBILITÉ ==========

  /// ✅ NOUVEAU: Convertit un événement existant en service
  static Future<String> convertEventToService(String eventId) async {
    try {
      print('🔄 Conversion événement → service: $eventId');
      
      final event = await EventsFirebaseService.getEvent(eventId);
      if (event == null) throw Exception('Événement non trouvé');
      
      // Créer un service à partir de l'événement
      final service = ServiceModel(
        id: '',
        name: event.title,
        description: event.description,
        type: 'culte', // Type par défaut, peut être personnalisé
        dateTime: event.startDate,
        location: event.location,
        durationMinutes: event.endDate != null 
            ? event.endDate!.difference(event.startDate).inMinutes 
            : 120,
        status: event.status,
        isRecurring: event.isRecurring,
        linkedEventId: eventId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: event.createdBy,
      );
      
      final serviceId = await _createService(service);
      
      // Mettre à jour l'événement avec le lien vers le service
      await _updateEventWithServiceLink(eventId, serviceId);
      
      print('✅ Événement converti en service: $serviceId');
      return serviceId;
    } catch (e) {
      print('❌ Erreur conversion événement→service: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Dissocie un service de son événement
  static Future<void> unlinkServiceFromEvent(String serviceId) async {
    try {
      print('🔗 Dissociation service ↔ événement: $serviceId');
      
      final service = await getService(serviceId);
      if (service == null) return;
      
      final eventId = service.linkedEventId;
      
      // Retirer le lien du service
      final unlinked = service.copyWith(linkedEventId: null);
      await _updateService(unlinked);
      
      // Retirer le lien de l'événement
      if (eventId != null) {
        final event = await EventsFirebaseService.getEvent(eventId);
        if (event != null) {
          final unlinkedEvent = event.copyWith(
            linkedServiceId: null,
            isServiceEvent: false,
            updatedAt: DateTime.now(),
          );
          await EventsFirebaseService.updateEvent(unlinkedEvent);
        }
      }
      
      print('✅ Service et événement dissociés');
    } catch (e) {
      print('❌ Erreur dissociation: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Duplique un service avec son événement
  static Future<String> duplicateServiceWithEvent(String serviceId) async {
    try {
      print('📋 Duplication service avec événement: $serviceId');
      
      final original = await getService(serviceId);
      if (original == null) throw Exception('Service non trouvé');
      
      // Créer une copie du service (sans ID ni lien)
      final duplicate = ServiceModel(
        id: '',
        name: '${original.name} (Copie)',
        description: original.description,
        type: original.type,
        dateTime: original.dateTime.add(const Duration(days: 7)), // Décalage d'une semaine
        location: original.location,
        durationMinutes: original.durationMinutes,
        status: 'brouillon', // Commencer en brouillon
        isRecurring: original.isRecurring,
        recurrencePattern: original.recurrencePattern,
        linkedEventId: null, // Sera créé
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: original.createdBy,
      );
      
      // Créer le service et l'événement
      final newServiceId = await createServiceWithEvent(duplicate);
      
      print('✅ Service dupliqué: $newServiceId');
      return newServiceId;
    } catch (e) {
      print('❌ Erreur duplication: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Relie un service existant à un événement existant
  static Future<void> linkServiceToEvent(String serviceId, String eventId) async {
    try {
      print('🔗 Liaison service → événement: $serviceId → $eventId');
      
      final service = await getService(serviceId);
      if (service == null) throw Exception('Service non trouvé');
      
      final event = await EventsFirebaseService.getEvent(eventId);
      if (event == null) throw Exception('Événement non trouvé');
      
      // Vérifier que l'événement n'est pas déjà lié
      if (event.linkedServiceId != null) {
        throw Exception('Cet événement est déjà lié à un autre service');
      }
      
      // Vérifier que le service n'est pas déjà lié
      if (service.linkedEventId != null) {
        throw Exception('Ce service est déjà lié à un autre événement');
      }
      
      // Créer les liens bidirectionnels
      final linkedService = service.copyWith(linkedEventId: eventId);
      await _updateService(linkedService);
      
      await _updateEventWithServiceLink(eventId, serviceId);
      
      print('✅ Service et événement liés');
    } catch (e) {
      print('❌ Erreur liaison: $e');
      rethrow;
    }
  }
}
