import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/event_model.dart';
import 'events_firebase_service.dart';
import 'service_notification_service.dart';
import 'event_series_service.dart'; // ✅ NOUVEAU: Pour gérer les séries d'événements récurrents
import 'service_recurrence_service.dart'; // ✅ NOUVEAU: Service dédié aux récurrences de services

/// Service d'intégration entre Services et Événements
/// Inspiré de Planning Center Online où chaque service est un événement
/// 
/// SYSTÈME DE RÉCURRENCE:
/// - Services simples → 1 événement dans Firestore
/// - Services récurrents → N événements individuels (style Google Calendar)
///   - Tous liés par un seriesId commun
///   - Chaque occurrence = événement complet indépendant
class ServiceEventIntegrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crée un service et son événement lié automatiquement
  /// 
  /// NOUVEAU SYSTÈME DE RÉCURRENCE (Style Planning Center Online):
  /// - Service simple → 1 service + 1 événement dans Firestore
  /// - Service récurrent → N services autonomes + N événements individuels
  /// - Chaque occurrence a sa propre date/heure et peut être modifiée indépendamment
  static Future<String> createServiceWithEvent(ServiceModel service) async {
    try {
      print('🎯 Création service avec événement lié: ${service.name}');
      
      if (service.isRecurring && service.recurrencePattern != null) {
        // ==========================================
        // === SERVICE RÉCURRENT (NOUVEAU SYSTÈME AUTONOME) ===
        // ==========================================
        print('   Mode: Service récurrent (occurrences autonomes)');
        
        // 1. ✅ NOUVEAU: Créer la série de SERVICES avec ServiceRecurrenceService
        final serviceIds = await ServiceRecurrenceService.createRecurringSeries(
          masterService: service,
          recurrencePattern: service.recurrencePattern!,
          preGenerateMonths: 6,
        );

        if (serviceIds.isEmpty) {
          throw Exception('Échec de la création de la série de services');
        }

        print('   ✅ ${serviceIds.length} services autonomes créés dans la série');

        // 2. ✅ NOUVEAU: Créer les événements correspondants pour chaque service
        print('   Création des événements liés...');
        int linkedEventsCount = 0;
        
        for (final serviceId in serviceIds) {
          final createdService = await ServiceRecurrenceService.getService(serviceId);
          if (createdService != null) {
            // Créer l'événement pour ce service spécifique avec SA date
            final linkedEvent = EventModel(
              id: '', // Sera généré par EventsFirebaseService
              title: createdService.name,
              description: createdService.description ?? '',
              type: 'culte',
              startDate: createdService.dateTime, // ✅ Date spécifique à cette occurrence
              endDate: createdService.dateTime.add(Duration(minutes: createdService.durationMinutes)),
              location: createdService.location,
              visibility: 'publique',
              responsibleIds: [],
              visibilityTargets: [],
              status: createdService.status,
              isRegistrationEnabled: true,
              maxParticipants: null,
              hasWaitingList: true,
              isRecurring: false, // ✅ Chaque événement est individuel
              imageUrl: createdService.imageUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: createdService.createdBy,
              isServiceEvent: true,
              
              // ✅ Lien vers la série d'événements pour le calendrier
              seriesId: createdService.seriesId,
              isSeriesMaster: createdService.isSeriesMaster,
              occurrenceIndex: createdService.occurrenceIndex,
            );

            // Créer l'événement et lier au service
            final eventId = await EventsFirebaseService.createEvent(linkedEvent);
            
            // Mettre à jour le service avec le lien événement
            await _updateServiceWithEventLink(serviceId, eventId);
            linkedEventsCount++;
          }
        }

        print('   ✅ $linkedEventsCount événements liés créés');

        // 3. Notifications pour le service maître
        final masterService = await ServiceRecurrenceService.getService(serviceIds.first);
        if (masterService != null) {
          await ServiceNotificationService.notifyNewService(masterService);
          await ServiceNotificationService.scheduleServiceReminder(masterService);
        }

        print('✅ Série services récurrents créée avec succès');
        print('   Services autonomes: ${serviceIds.length}');
        print('   Événements liés: $linkedEventsCount');
        return serviceIds.first; // Retourner l'ID du service maître

      } else {
        // ==========================================
        // === SERVICE SIMPLE (NON RÉCURRENT) ===
        // ==========================================
        print('   Mode: Service simple (1 événement)');
        
        // Créer l'événement simple
        final event = EventModel(
          id: '',
          title: service.name,
          description: service.description ?? '',
          type: 'culte',
          startDate: service.dateTime,
          endDate: service.dateTime.add(Duration(minutes: service.durationMinutes)),
          location: service.location,
          visibility: 'publique',
          responsibleIds: [],
          visibilityTargets: [],
          status: service.status,
          isRegistrationEnabled: true,
          maxParticipants: null,
          hasWaitingList: true,
          isRecurring: false,
          imageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: service.createdBy,
          isServiceEvent: true,
        );

        final eventId = await EventsFirebaseService.createEvent(event);
        print('   ✅ Événement créé: $eventId');

        // Créer le service avec le lien vers l'événement
        final serviceWithEvent = service.copyWith(linkedEventId: eventId);
        final serviceId = await _createService(serviceWithEvent);

        // Mettre à jour l'événement avec le lien vers le service
        await _updateEventWithServiceLink(eventId, serviceId);

        // Notifications
        await ServiceNotificationService.notifyNewService(serviceWithEvent);
        await ServiceNotificationService.scheduleServiceReminder(serviceWithEvent);

        print('✅ Service simple créé avec succès: $serviceId');
        return serviceId;
      }
    } catch (e) {
      print('❌ Erreur création service avec événement: $e');
      rethrow;
    }
  }

  /// Met à jour un service et synchronise avec son événement lié
  /// 
  /// GESTION RÉCURRENCE:
  /// - Service simple → Met à jour 1 événement
  /// - Service récurrent → Met à jour TOUTE LA SÉRIE (tous les événements futurs)
  static Future<void> updateServiceWithEvent(ServiceModel service) async {
    try {
      print('🔄 Mise à jour service et événements: ${service.id}');
      
      // 1. Mettre à jour le service
      await _updateService(service);

      // 2. Si lié à un événement, synchroniser
      if (service.linkedEventId != null) {
        final linkedEvent = await EventsFirebaseService.getEvent(service.linkedEventId!);
        
        if (linkedEvent != null) {
          
          if (linkedEvent.seriesId != null) {
            // ==========================================
            // === SERVICE RÉCURRENT: Mettre à jour TOUTE LA SÉRIE ===
            // ==========================================
            print('   Mode: Service récurrent - Mise à jour série');
            
            // Récupérer tous les événements de la série
            final seriesEvents = await EventSeriesService.getSeriesEvents(linkedEvent.seriesId!);
            print('   ${seriesEvents.length} événements dans la série');
            
            // Mettre à jour chaque événement de la série
            int updatedCount = 0;
            for (final event in seriesEvents) {
              // Calculer la nouvelle date de fin en fonction de la durée
              final duration = Duration(minutes: service.durationMinutes);
              final newEndDate = event.startDate.add(duration);
              
              final updatedEvent = event.copyWith(
                title: service.name,
                description: service.description ?? '',
                // Note: On ne change PAS startDate (chaque occurrence garde sa date)
                endDate: newEndDate,
                location: service.location,
                status: service.status,
                updatedAt: DateTime.now(),
              );
              
              await EventsFirebaseService.updateEvent(updatedEvent);
              updatedCount++;
            }
            
            print('   ✅ $updatedCount événements de la série mis à jour');
            
          } else {
            // ==========================================
            // === SERVICE SIMPLE: Mettre à jour 1 événement ===
            // ==========================================
            print('   Mode: Service simple - Mise à jour 1 événement');
            
            final updatedEvent = linkedEvent.copyWith(
              title: service.name,
              description: service.description ?? '',
              startDate: service.dateTime,
              endDate: service.dateTime.add(Duration(minutes: service.durationMinutes)),
              location: service.location,
              status: service.status,
              isRecurring: service.isRecurring,
              updatedAt: DateTime.now(),
            );
            
            await EventsFirebaseService.updateEvent(updatedEvent);
            print('   ✅ Événement simple mis à jour');
          }
          
          // Notification
          await ServiceNotificationService.notifyServiceUpdate(service);
        }
      }
      
      print('✅ Service et événements synchronisés');
    } catch (e) {
      print('❌ Erreur mise à jour service/événement: $e');
      rethrow;
    }
  }

  /// Supprime un service et son événement lié
  /// 
  /// GESTION RÉCURRENCE:
  /// - Service simple → Supprime 1 événement
  /// - Service récurrent → Supprime TOUTE LA SÉRIE (tous les événements)
  static Future<void> deleteServiceWithEvent(String serviceId) async {
    try {
      print('🗑️ Suppression service et événements: $serviceId');
      
      final service = await getService(serviceId);
      if (service == null) return;

      // Notifier l'annulation si le service est publié
      if (service.status == 'publie') {
        await ServiceNotificationService.notifyServiceCancellation(service);
      }

      // Supprimer l'événement ou la série d'événements
      if (service.linkedEventId != null) {
        final linkedEvent = await EventsFirebaseService.getEvent(service.linkedEventId!);
        
        if (linkedEvent != null && linkedEvent.seriesId != null) {
          // ==========================================
          // === SERVICE RÉCURRENT: Supprimer TOUTE LA SÉRIE ===
          // ==========================================
          print('   Mode: Service récurrent - Suppression série');
          
          await EventSeriesService.deleteAllOccurrences(linkedEvent.seriesId!);
          print('   ✅ Série d\'événements supprimée');
          
        } else if (service.linkedEventId != null) {
          // ==========================================
          // === SERVICE SIMPLE: Supprimer 1 événement ===
          // ==========================================
          print('   Mode: Service simple - Suppression 1 événement');
          
          await EventsFirebaseService.deleteEvent(service.linkedEventId!);
          print('   ✅ Événement simple supprimé');
        }
      }

      // Supprimer le service
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

  /// Met à jour un service avec un lien vers un événement
  static Future<void> _updateServiceWithEventLink(String serviceId, String eventId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'linkedEventId': eventId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
