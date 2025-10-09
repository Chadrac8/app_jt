# Analyse de l'Intégration Services ↔ Events

## 📋 Vue d'ensemble

Ce document analyse l'intégration entre les modules Services et Événements, identifie les fonctionnalités manquantes et propose des améliorations.

---

## ✅ Fonctionnalités Implémentées

### 1. **Service d'Intégration Principal** ✅
**Fichier**: `lib/services/service_event_integration_service.dart`

**Méthodes implémentées**:
- ✅ `createServiceWithEvent()` - Crée service + événement lié
- ✅ `updateServiceWithEvent()` - Met à jour service et synchronise événement
- ✅ `deleteServiceWithEvent()` - Supprime service et événement en cascade
- ✅ `getService()` - Récupère un service
- ✅ `getLinkedEvent()` - Récupère l'événement lié à un service
- ✅ `getServiceByEventId()` - Récupère le service lié à un événement
- ✅ `_createRecurrenceFromServicePattern()` - Convertit pattern service → récurrence événement
- ✅ `_mapPatternToRecurrenceType()` - Mappe types de récurrence

### 2. **Modèle de Données** ✅
**Fichier**: `lib/models/service_model.dart`

- ✅ Champ `linkedEventId` présent
- ✅ Sérialization Firestore complète
- ✅ Méthode `copyWith` avec linkedEventId

### 3. **Utilisation dans l'UI** ✅
**Fichiers**:
- `lib/modules/services/views/service_form_page.dart` ✅
- `lib/modules/services/views/service_detail_page.dart` ✅
- `lib/modules/services/views/services_home_page.dart` ✅

**Actions intégrées**:
- ✅ Création de service → Appelle `createServiceWithEvent()`
- ✅ Modification de service → Appelle `updateServiceWithEvent()`
- ✅ Suppression de service → Appelle `deleteServiceWithEvent()`

---

## ❌ Fonctionnalités Manquantes ou Incomplètes

### 🔴 **Priorité HAUTE**

#### 1. **Lien Bidirectionnel Incomplet**
**Problème**: EventModel n'a pas de champ pour référencer le service

**Impact**: 
- Impossible de savoir si un événement est lié à un service depuis EventModel
- Pas de filtrage facile des "événements-services" dans le calendrier
- Requêtes inefficaces pour trouver le service d'un événement

**Solution suggérée**:
```dart
// Dans lib/models/event_model.dart
class EventModel {
  // ... autres champs
  final String? linkedServiceId;  // NOUVEAU : Référence vers ServiceModel
  final bool isServiceEvent;      // NOUVEAU : Flag pour identifier les événements-services
  
  EventModel({
    // ...
    this.linkedServiceId,
    this.isServiceEvent = false,
  });
}
```

**Modifications nécessaires**:
```dart
// Dans ServiceEventIntegrationService.createServiceWithEvent()
final event = EventModel(
  // ... autres champs
  linkedServiceId: '', // Sera mis à jour après création du service
  isServiceEvent: true,
);

final eventId = await EventsFirebaseService.createEvent(event);

// Créer le service
final serviceId = await _createService(serviceWithEvent);

// Mettre à jour l'événement avec l'ID du service
await _updateEventWithServiceLink(eventId, serviceId);
```

---

#### 2. **Gestion des Inscriptions Manquante**
**Problème**: Les services créés ont `isRegistrationEnabled: false` par défaut

**Impact**:
- Impossible pour les membres de s'inscrire aux services via le calendrier
- Perte de la fonctionnalité d'inscription des événements
- Pas de suivi de participation

**Solution suggérée**:
```dart
// Dans ServiceEventIntegrationService.createServiceWithEvent()
final event = EventModel(
  // ...
  isRegistrationEnabled: true,  // Activer les inscriptions
  maxParticipants: service.maxParticipants, // Capacité si définie
  hasWaitingList: service.hasWaitingList ?? true,
);
```

**Modifications au ServiceModel**:
```dart
class ServiceModel {
  // ... autres champs
  final int? maxParticipants;    // NOUVEAU : Capacité maximale
  final bool hasWaitingList;     // NOUVEAU : Liste d'attente
}
```

---

#### 3. **Synchronisation des Récurrences Incomplète**
**Problème**: Lors de la modification d'un service récurrent, la récurrence n'est pas mise à jour

**Impact**:
- Changements de récurrence non reflétés
- Instances générées ne correspondent pas au nouveau pattern
- Incohérence entre service et événement

**Solution suggérée**:
```dart
// Dans ServiceEventIntegrationService
static Future<void> updateServiceWithEvent(ServiceModel service) async {
  try {
    // 1. Mettre à jour le service
    await _updateService(service);

    // 2. Synchroniser l'événement
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
          isRecurring: service.isRecurring,  // Synchroniser flag récurrence
          updatedAt: DateTime.now(),
        );
        await EventsFirebaseService.updateEvent(updatedEvent);
        
        // NOUVEAU : Gérer les changements de récurrence
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
      }
    }
  } catch (e) {
    print('❌ Erreur mise à jour service/événement: $e');
    rethrow;
  }
}

// NOUVELLE méthode
static Future<void> _updateRecurrencePattern(
  String eventId,
  Map<String, dynamic> pattern,
  DateTime startDate,
) async {
  // Récupérer la récurrence existante
  final existingRecurrences = await EventRecurrenceService.getRecurrences(eventId: eventId);
  
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
  } else {
    // Créer une nouvelle récurrence
    await _createRecurrenceFromServicePattern(eventId, pattern, startDate);
  }
}

// NOUVELLE méthode
static Future<void> _removeRecurrence(String eventId) async {
  final recurrences = await EventRecurrenceService.getRecurrences(eventId: eventId);
  for (final recurrence in recurrences) {
    await EventRecurrenceService.deleteRecurrence(recurrence.id);
  }
}
```

---

### 🟠 **Priorité MOYENNE**

#### 4. **Notifications Non Implémentées**
**Problème**: Aucune notification lors de la création/modification/suppression de services

**Impact**:
- Membres non informés des nouveaux services
- Pas de rappels avant les services
- Mauvaise communication

**Solution suggérée**:
```dart
// Créer un nouveau fichier: lib/services/service_notification_service.dart

class ServiceNotificationService {
  /// Envoie une notification de nouveau service
  static Future<void> notifyNewService(ServiceModel service) async {
    // Récupérer tous les membres de l'église
    final members = await _getChurchMembers();
    
    // Envoyer notification via Firebase Cloud Messaging
    await NotificationService.sendToMultiple(
      userIds: members,
      title: 'Nouveau service: ${service.name}',
      body: 'Le ${_formatDate(service.dateTime)} à ${_formatTime(service.dateTime)}',
      data: {
        'type': 'new_service',
        'serviceId': service.id,
        'eventId': service.linkedEventId,
      },
    );
  }
  
  /// Envoie un rappel 24h avant le service
  static Future<void> scheduleServiceReminder(ServiceModel service) async {
    final reminderTime = service.dateTime.subtract(const Duration(hours: 24));
    
    // Utiliser Firebase Cloud Functions pour scheduler
    await CloudFunctions.instance.httpsCallable('scheduleNotification').call({
      'serviceId': service.id,
      'scheduledFor': reminderTime.toIso8601String(),
      'title': 'Rappel: ${service.name}',
      'body': 'Le service aura lieu demain à ${_formatTime(service.dateTime)}',
    });
  }
  
  /// Notifie les changements de service
  static Future<void> notifyServiceUpdate(ServiceModel service) async {
    // Récupérer les personnes inscrites via l'événement lié
    if (service.linkedEventId != null) {
      final registrations = await EventsFirebaseService.getEventRegistrations(
        service.linkedEventId!,
      );
      
      final registeredUserIds = registrations.map((r) => r.personId).toList();
      
      await NotificationService.sendToMultiple(
        userIds: registeredUserIds,
        title: 'Modification: ${service.name}',
        body: 'Le service a été modifié. Consultez les détails.',
        data: {
          'type': 'service_update',
          'serviceId': service.id,
        },
      );
    }
  }
}

// Intégrer dans ServiceEventIntegrationService
static Future<String> createServiceWithEvent(ServiceModel service) async {
  // ... création existante
  
  // NOUVEAU: Envoyer notifications
  await ServiceNotificationService.notifyNewService(serviceWithEvent);
  await ServiceNotificationService.scheduleServiceReminder(serviceWithEvent);
  
  return serviceId;
}
```

---

#### 5. **Synchronisation des Assignations Manquante**
**Problème**: Les assignations de service ne sont pas liées aux rôles d'événement

**Impact**:
- Duplication d'information
- Pas de vue unifiée des responsabilités
- Confusion pour les membres

**Solution suggérée**:
```dart
// Dans ServiceEventIntegrationService

/// Synchronise les assignations de service avec l'événement
static Future<void> syncServiceAssignmentsToEvent(
  String serviceId,
  List<ServiceAssignment> assignments,
) async {
  try {
    final service = await getService(serviceId);
    if (service?.linkedEventId == null) return;
    
    // Convertir les assignations en responsables d'événement
    final responsibleIds = assignments
        .where((a) => a.status == 'accepted')
        .map((a) => a.personId)
        .toList();
    
    // Mettre à jour l'événement
    final event = await EventsFirebaseService.getEvent(service!.linkedEventId!);
    if (event != null) {
      final updatedEvent = event.copyWith(
        responsibleIds: responsibleIds,
        updatedAt: DateTime.now(),
      );
      await EventsFirebaseService.updateEvent(updatedEvent);
    }
  } catch (e) {
    print('❌ Erreur synchronisation assignations: $e');
  }
}

// Appeler depuis les vues d'assignation
```

---

#### 6. **Statistiques Croisées Non Disponibles**
**Problème**: Pas de vue combinée des statistiques services + événements

**Impact**:
- Analyses incomplètes
- Impossible de voir tendances globales
- Pas de KPIs unifiés

**Solution suggérée**:
```dart
// Créer: lib/services/integrated_statistics_service.dart

class IntegratedStatisticsService {
  /// Récupère les statistiques combinées services + événements
  static Future<Map<String, dynamic>> getCombinedStatistics() async {
    try {
      // Récupérer statistiques des services
      final serviceStats = await ServicesFirebaseService.getStatistics();
      
      // Récupérer statistiques des événements-services uniquement
      final serviceEvents = await _getServiceEvents();
      final eventStats = await _calculateEventStatistics(serviceEvents);
      
      return {
        'totalServices': serviceStats['total'],
        'upcomingServices': serviceStats['upcoming'],
        'totalParticipants': eventStats['totalRegistrations'],
        'averageAttendance': eventStats['averageAttendance'],
        'mostPopularServiceType': serviceStats['mostPopular'],
        'participationRate': _calculateParticipationRate(
          serviceStats['total'],
          eventStats['totalRegistrations'],
        ),
        'recurringServicesCount': serviceStats['recurring'],
        'oneTimeServicesCount': serviceStats['oneTime'],
      };
    } catch (e) {
      print('❌ Erreur statistiques intégrées: $e');
      return {};
    }
  }
  
  /// Récupère tous les événements liés à des services
  static Future<List<EventModel>> _getServiceEvents() async {
    // Requête Firestore avec isServiceEvent = true
    // (nécessite l'implémentation du champ isServiceEvent)
    final query = await FirebaseFirestore.instance
        .collection('events')
        .where('isServiceEvent', isEqualTo: true)
        .get();
    
    return query.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }
}
```

---

### 🟡 **Priorité BASSE**

#### 7. **Conversion Événement → Service**
**Problème**: Impossible de convertir un événement existant en service

**Impact**: Flexibilité limitée

**Solution suggérée**:
```dart
static Future<String> convertEventToService(String eventId) async {
  final event = await EventsFirebaseService.getEvent(eventId);
  if (event == null) throw Exception('Événement non trouvé');
  
  // Créer un service à partir de l'événement
  final service = ServiceModel(
    id: '',
    name: event.title,
    description: event.description,
    type: 'culte', // Type par défaut, à configurer
    dateTime: event.startDate,
    location: event.location,
    durationMinutes: event.endDate.difference(event.startDate).inMinutes,
    status: event.status,
    isRecurring: event.isRecurring,
    linkedEventId: eventId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    createdBy: event.createdBy,
  );
  
  final serviceId = await _createService(service);
  
  // Mettre à jour l'événement avec le lien
  await _updateEventWithServiceLink(eventId, serviceId);
  
  return serviceId;
}
```

---

#### 8. **Détachement Service ↔ Événement**
**Problème**: Impossible de dissocier un service de son événement

**Impact**: Pas de flexibilité si erreur

**Solution suggérée**:
```dart
static Future<void> unlinkServiceFromEvent(String serviceId) async {
  final service = await getService(serviceId);
  if (service == null) return;
  
  // Retirer le lien
  final unlinked = service.copyWith(linkedEventId: null);
  await _updateService(unlinked);
  
  // Option: Supprimer l'événement ou juste le marquer
  if (service.linkedEventId != null) {
    final event = await EventsFirebaseService.getEvent(service.linkedEventId!);
    if (event != null) {
      await EventsFirebaseService.updateEvent(
        event.copyWith(linkedServiceId: null, isServiceEvent: false),
      );
    }
  }
}
```

---

#### 9. **Duplication Service avec Événement**
**Problème**: Dupliquer un service ne duplique pas l'événement

**Impact**: Workflow incomplet

**Solution suggérée**:
```dart
static Future<String> duplicateServiceWithEvent(String serviceId) async {
  final original = await getService(serviceId);
  if (original == null) throw Exception('Service non trouvé');
  
  // Créer une copie du service
  final duplicate = original.copyWith(
    id: '',
    name: '${original.name} (Copie)',
    linkedEventId: null, // Sera créé
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // Créer le service et l'événement
  return await createServiceWithEvent(duplicate);
}
```

---

#### 10. **Vue Calendrier Filtrée**
**Problème**: Impossible de filtrer uniquement les services dans le calendrier

**Impact**: Vue encombrée

**Solution suggérée**:
```dart
// Dans EventCalendarView, ajouter un filtre
class EventCalendarView extends StatefulWidget {
  final bool showServicesOnly;  // NOUVEAU paramètre
  
  const EventCalendarView({
    super.key,
    this.showServicesOnly = false,
  });
}

// Dans la logique de chargement
Future<void> _loadEvents() async {
  List<EventModel> events;
  
  if (widget.showServicesOnly) {
    // Charger uniquement les événements-services
    events = await EventsFirebaseService.getEvents(
      filters: {'isServiceEvent': true},
    );
  } else {
    events = await EventsFirebaseService.getEvents();
  }
  
  setState(() => _events = events);
}
```

---

## 📊 Résumé par Priorité

### 🔴 Haute (3 items - 4-6h)
1. Lien bidirectionnel EventModel ↔ ServiceModel
2. Gestion des inscriptions aux services
3. Synchronisation complète des récurrences

### 🟠 Moyenne (4 items - 6-8h)
4. Système de notifications
5. Synchronisation des assignations
6. Statistiques croisées
7. *(Possibilité d'ajouter d'autres)*

### 🟡 Basse (4 items - 3-4h)
8. Conversion Événement → Service
9. Détachement Service ↔ Événement
10. Duplication avec événement
11. Vue calendrier filtrée

**Total estimé**: 13-18 heures pour tout implémenter

---

## 🎯 Plan d'Implémentation Recommandé

### Phase 1 : Fondations (4-6h) 🔴
1. ✅ Ajouter `linkedServiceId` et `isServiceEvent` à EventModel
2. ✅ Implémenter gestion des inscriptions
3. ✅ Compléter synchronisation récurrences

### Phase 2 : Fonctionnalités Utilisateur (6-8h) 🟠
4. 📧 Système de notifications complet
5. 👥 Synchronisation assignations → responsables
6. 📊 Dashboard statistiques intégrées

### Phase 3 : Polish & Flexibilité (3-4h) 🟡
7. 🔄 Conversion bidirectionnelle
8. 🔗 Détachement/re-liaison
9. 📋 Vues filtrées

---

## ✅ Tests Recommandés

### Tests d'Intégration
- [ ] Créer service → Vérifier événement créé avec bon linkedServiceId
- [ ] Modifier service → Vérifier événement synchronisé
- [ ] Supprimer service → Vérifier cascade sur événement
- [ ] Service récurrent → Vérifier instances générées
- [ ] Modifier récurrence → Vérifier nouvelles instances
- [ ] S'inscrire à événement-service → Vérifier dans les deux modules

### Tests de Synchronisation
- [ ] Modifier nom service → Vérifier titre événement
- [ ] Modifier date service → Vérifier date événement
- [ ] Ajouter assignation → Vérifier responsables événement
- [ ] Annuler occurrence → Vérifier dans les deux modules

---

## 🚀 Recommandations

### Priorités Immédiates
1. **Lien bidirectionnel** - Fondamental pour requêtes efficaces
2. **Inscriptions** - Fonctionnalité clé attendue par utilisateurs
3. **Notifications** - Communication essentielle

### Quick Wins
- Vue calendrier filtrée (2h)
- Statistiques de base (2h)

### Long Terme
- Dashboard unifié Services + Events
- Analytics avancées
- Intégration avec module Personnes pour gestion équipes

---

## 📝 Conclusion

L'intégration Services ↔ Events est **fonctionnelle pour les opérations de base** (CRUD), mais **incomplète pour un usage en production**. Les fonctionnalités manquantes principales sont :

1. **Lien bidirectionnel** (critique)
2. **Inscriptions aux services** (haute valeur)
3. **Notifications** (communication essentielle)
4. **Synchronisation récurrences** (cohérence données)

**Estimation totale** : 13-18h pour une intégration complète et robuste.

**Recommandation** : Implémenter au minimum les 3 fonctionnalités haute priorité (4-6h) avant mise en production.
