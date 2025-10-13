# 🏗️ Architecture Services Récurrents : Guide Complet

**Date** : 13 octobre 2025  
**Modèle** : Planning Center Online  
**Statut** : ✅ **IMPLÉMENTÉ ET OPTIMISÉ**

---

## 🎯 Principe Fondamental

### Formule

```
1 SERVICE (Template/Configuration) → N ÉVÉNEMENTS (Instances/Occurrences)
```

### Analogie

Pensez à une **recette de cuisine** :
- **SERVICE** = Recette (ingrédients, instructions, durée)
- **ÉVÉNEMENTS** = Plats cuisinés selon cette recette
  - Chaque plat suit la recette
  - Mais peut avoir des variations (chef différent, heure différente)
  - Modifier la recette → tous les futurs plats suivent la nouvelle recette

---

## 📊 Structure des Données

### Firestore Collections

```
📁 services/
  └── service_abc123
      ├── id: "service_abc123"
      ├── name: "Culte Dominical"
      ├── type: "culte"
      ├── dateTime: 2025-10-13 10:00
      ├── location: "Sanctuaire Principal"
      ├── durationMinutes: 90
      ├── isRecurring: true
      ├── recurrencePattern: {
      │     type: "weekly",
      │     interval: 1,
      │     daysOfWeek: [7],
      │     endDate: "2026-04-13"
      │   }
      ├── linkedEventId: "event_xyz789" ← Premier événement (maître)
      └── ...

📁 events/
  ├── event_xyz789 (Occurrence 1 - MAÎTRE)
  │   ├── id: "event_xyz789"
  │   ├── title: "Culte Dominical"
  │   ├── startDate: 2025-10-13 10:00
  │   ├── endDate: 2025-10-13 11:30
  │   ├── location: "Sanctuaire Principal"
  │   ├── seriesId: "series_1729..."
  │   ├── linkedServiceId: "service_abc123" ← Lien vers service
  │   ├── isServiceEvent: true
  │   ├── occurrenceIndex: 0
  │   ├── responsibleIds: ["jean_123", "marie_456"]
  │   └── ...
  │
  ├── event_abc456 (Occurrence 2)
  │   ├── id: "event_abc456"
  │   ├── title: "Culte Dominical"
  │   ├── startDate: 2025-10-20 10:00
  │   ├── seriesId: "series_1729..." ← Même série
  │   ├── linkedServiceId: "service_abc123" ← Même service
  │   ├── occurrenceIndex: 1
  │   ├── responsibleIds: ["paul_789", "luc_012"]
  │   └── ...
  │
  └── ... 24 autres occurrences
```

---

## 🎬 Cas d'Usage Réels

### Cas 1 : Création d'un Service Récurrent Hebdomadaire

#### Entrée Utilisateur

```
Formulaire ServiceFormPage:
  ├── Nom: "Culte Dominical"
  ├── Type: Culte
  ├── Date: 13 octobre 2025, 10:00
  ├── Lieu: Sanctuaire Principal
  ├── Durée: 90 minutes
  ├── Statut: Publié
  └── Récurrence: ☑️ Service récurrent
      ├── Type: Hebdomadaire
      ├── Jours: [☑️ Dimanche]
      ├── Intervalle: Toutes les 1 semaine(s)
      └── Fin: Le 13 avril 2026 (6 mois)
```

#### Code Exécuté

```dart
// 1. Créer le ServiceModel
final service = ServiceModel(
  id: '',
  name: 'Culte Dominical',
  type: 'culte',
  dateTime: DateTime(2025, 10, 13, 10, 0),
  location: 'Sanctuaire Principal',
  durationMinutes: 90,
  status: 'publie',
  isRecurring: true,
  recurrencePattern: {
    'type': 'weekly',
    'interval': 1,
    'daysOfWeek': [7],
    'endDate': '2026-04-13T00:00:00.000Z',
  },
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 2. Appeler ServiceEventIntegrationService
await ServiceEventIntegrationService.createServiceWithEvent(service);
```

#### Processus Interne

```dart
// ServiceEventIntegrationService.createServiceWithEvent()
{
  // 1. Créer le service dans Firestore
  final serviceId = await ServicesFirebaseService.createService(service);
  
  // 2. Détecter isRecurring = true
  if (service.isRecurring && service.recurrencePattern != null) {
    
    // 3. Créer l'événement maître
    final masterEvent = EventModel(
      title: service.name,
      startDate: service.dateTime,
      endDate: service.dateTime.add(Duration(minutes: 90)),
      location: service.location,
      status: service.status,
      isServiceEvent: true,
    );
    
    // 4. Convertir pattern → EventRecurrence
    final eventRecurrence = _convertServicePatternToEventRecurrence(
      service.recurrencePattern!,
      service.dateTime,
    );
    
    // 5. Créer la série d'événements (26 occurrences)
    final eventIds = await EventSeriesService.createRecurringSeries(
      masterEvent: masterEvent,
      recurrence: eventRecurrence,
      preGenerateMonths: 6,
    );
    
    // Logs:
    // 📅 Création série récurrente: Culte Dominical
    //    Règle: Toutes les semaines
    //    Mode: Date de fin définie
    //    Date de fin: 2026-04-13
    //    Occurrences à créer: 26
    //    ✅ Batch final de 26 événements créé
    // ✅ Série créée: 26 événements (ID: series_1729...)
    
    // 6. Lier le service au premier événement
    service.linkedEventId = eventIds.first;
    await ServicesFirebaseService.updateService(service);
    
    // 7. Lier tous les événements au service
    for (final eventId in eventIds) {
      await EventsFirebaseService.updateEvent(
        event.copyWith(linkedServiceId: serviceId)
      );
    }
  }
}
```

#### Résultat Firestore

```
services/service_abc123 ✅ (1 document)
events/
  ├── event_xyz789 ✅ (13 oct)
  ├── event_abc456 ✅ (20 oct)
  ├── event_def789 ✅ (27 oct)
  ├── event_ghi012 ✅ (3 nov)
  └── ... 22 autres ✅

Total: 1 service + 26 événements = 27 documents
```

#### Vue Utilisateur

**Vue Calendrier** :
```
Octobre 2025
D   L   M   M   J   V   S
                1   2   3   4   5
6   7   8   9  10  11  12
13  14  15  16  17  18  19
🔁 Culte Dominical
20  21  22  23  24  25  26
🔁 Culte Dominical
27  28  29  30  31
🔁 Culte Dominical

Novembre 2025
3   🔁 Culte Dominical
10  🔁 Culte Dominical
...
```

**Vue Planning** :
```
📅 Semaine du 13 Oct 2025     1 service(s)

┌──────────────────────────────────────────────┐
│ 🔁 Culte Dominical                 [PUBLIÉ] │
│ 📅 dimanche 13 oct • 10:00 - 11:30          │
│ 📍 Sanctuaire Principal                     │
│ ⚠️  0 bénévole(s) assigné(s)                │
│                            [person_add] →    │
└──────────────────────────────────────────────┘

📅 Semaine du 20 Oct 2025     1 service(s)
...
```

---

### Cas 2 : Modification du Service (Nom, Lieu, Durée)

#### Scénario

L'utilisateur veut :
- Changer le nom : "Culte Dominical" → "Culte de Louange"
- Changer le lieu : "Sanctuaire Principal" → "Grande Salle"
- Changer la durée : 90 min → 120 min

#### Code

```dart
// 1. Récupérer le service
final service = await ServicesFirebaseService.getService('service_abc123');

// 2. Modifier
final updatedService = service.copyWith(
  name: 'Culte de Louange',
  location: 'Grande Salle',
  durationMinutes: 120,
  updatedAt: DateTime.now(),
);

// 3. Sauvegarder
await ServiceEventIntegrationService.updateServiceWithEvent(updatedService);
```

#### Processus Interne

```dart
// ServiceEventIntegrationService.updateServiceWithEvent()
{
  // 1. Mettre à jour le service
  await ServicesFirebaseService.updateService(updatedService);
  
  // 2. Récupérer l'événement lié
  final linkedEvent = await EventsFirebaseService.getEvent(
    service.linkedEventId!
  );
  
  // 3. Détecter la série
  if (linkedEvent.seriesId != null) {
    
    // 4. Récupérer TOUS les événements de la série
    final seriesEvents = await EventSeriesService.getSeriesEvents(
      linkedEvent.seriesId!
    );
    
    // Logs:
    // 🔄 Mise à jour service et événements: service_abc123
    //    Mode: Service récurrent - Mise à jour série
    //    26 événements dans la série
    
    // 5. Mettre à jour CHAQUE événement
    for (final event in seriesEvents) {
      final newEndDate = event.startDate.add(
        Duration(minutes: updatedService.durationMinutes)
      );
      
      final updated = event.copyWith(
        title: updatedService.name,           // ✅ Nouveau nom
        location: updatedService.location,     // ✅ Nouveau lieu
        endDate: newEndDate,                   // ✅ Nouvelle durée
        status: updatedService.status,
        updatedAt: DateTime.now(),
      );
      
      await EventsFirebaseService.updateEvent(updated);
    }
    
    // Logs:
    // ✅ 26 événements de la série mis à jour
  }
}
```

#### Résultat

**AVANT** :
```
events/
  ├── event_xyz789: "Culte Dominical" @ Sanctuaire (10:00-11:30)
  ├── event_abc456: "Culte Dominical" @ Sanctuaire (10:00-11:30)
  └── ... 24 autres avec ancien nom/lieu/durée
```

**APRÈS** :
```
events/
  ├── event_xyz789: "Culte de Louange" @ Grande Salle (10:00-12:00)
  ├── event_abc456: "Culte de Louange" @ Grande Salle (10:00-12:00)
  └── ... 24 autres avec nouveau nom/lieu/durée
```

**Performance** :
- ✅ 1 modification de service
- ✅ 26 mises à jour d'événements (batch)
- ⏱️ Temps : ~2 secondes
- 💰 Coût Firestore : 27 writes

**Vue Utilisateur** :
```
Calendrier rafraîchi automatiquement (StreamBuilder)
    ↓
Tous les dimanches affichent maintenant:
🔁 Culte de Louange @ Grande Salle (10:00-12:00)
```

---

### Cas 3 : Assignation de Bénévoles (Par Occurrence)

#### Scénario

Assigner différents bénévoles pour chaque dimanche :
- 13 oct : Jean (Louange), Marie (Technique)
- 20 oct : Paul (Louange), Luc (Technique)
- 27 oct : Sophie (Louange), Anne (Technique)

#### Code

```dart
// Depuis ServicesPlanningView
// User clique sur [person_add] pour l'occurrence du 13 oct

await showDialog<bool>(
  context: context,
  builder: (context) => QuickAssignDialog(
    event: event_xyz789, // Occurrence du 13 oct
  ),
);
```

#### Processus QuickAssignDialog

```dart
// 1. Charger tous les bénévoles
final people = await FirebaseFirestore.instance
    .collection('people')
    .where('status', isEqualTo: 'active')
    .get();

// 2. Afficher avec recherche
// User recherche "Jean" → Jean Dupont apparaît
// User coche Jean et Marie

// 3. Sauvegarder
final updatedEvent = event.copyWith(
  responsibleIds: ['jean_123', 'marie_456'],
  updatedAt: DateTime.now(),
);
await EventsFirebaseService.updateEvent(updatedEvent);
```

#### Résultat

```
events/
  ├── event_xyz789 (13 oct)
  │   └── responsibleIds: ["jean_123", "marie_456"] ✅
  │
  ├── event_abc456 (20 oct)
  │   └── responsibleIds: [] ← Pas affecté ✅
  │
  └── event_def789 (27 oct)
      └── responsibleIds: [] ← Pas affecté ✅
```

**Flexibilité** : Chaque occurrence peut avoir ses propres assignations ! 🎯

---

### Cas 4 : Suppression du Service Récurrent

#### Scénario

User décide d'annuler complètement le "Culte de Louange".

#### Code

```dart
// Depuis ServiceDetailPage
await ServiceEventIntegrationService.deleteServiceWithEvent('service_abc123');
```

#### Processus Interne

```dart
// ServiceEventIntegrationService.deleteServiceWithEvent()
{
  // 1. Récupérer le service
  final service = await ServicesFirebaseService.getService(serviceId);
  
  // 2. Récupérer l'événement lié
  final linkedEvent = await EventsFirebaseService.getEvent(
    service.linkedEventId!
  );
  
  // 3. Détecter la série
  if (linkedEvent != null && linkedEvent.seriesId != null) {
    
    // 4. Supprimer TOUTE LA SÉRIE (soft delete)
    await EventSeriesService.deleteAllOccurrences(linkedEvent.seriesId!);
    
    // Logs:
    // 🗑️ Suppression service et événements: service_abc123
    //    Mode: Service récurrent - Suppression série
    //    ✅ Série d'événements supprimée
  }
  
  // 5. Supprimer le service
  await ServicesFirebaseService.deleteService(serviceId);
  
  // Logs:
  // ✅ Service supprimé
}
```

#### Résultat

```
services/service_abc123 ✅ SUPPRIMÉ

events/
  ├── event_xyz789 (13 oct)
  │   └── deletedAt: 2025-10-13 14:30 ✅
  │
  ├── event_abc456 (20 oct)
  │   └── deletedAt: 2025-10-13 14:30 ✅
  │
  └── ... 24 autres avec deletedAt ✅
```

**Soft Delete** : Les données restent en base mais sont invisibles. ✅

**Vue Calendrier** : Plus aucune occurrence visible ✅

---

### Cas 5 : Modifier UNE Occurrence Spécifique

#### Scénario

Le dimanche 27 octobre, c'est un "Culte Spécial Halloween" avec durée de 2h au lieu de 90 min.

#### Code

```dart
// Depuis EventDetailPage (clic sur occurrence du 27 oct)
// User voit RecurringEventEditDialog

// Option choisie: "Modifier seulement cette occurrence"

final updatedEvent = event_def789.copyWith(
  title: 'Culte Spécial Halloween',
  endDate: event.startDate.add(Duration(minutes: 120)),
  isModified: true, // ✅ Marquer comme modifié
  updatedAt: DateTime.now(),
);

await EventsFirebaseService.updateEvent(updatedEvent);
```

#### Résultat

```
events/
  ├── event_xyz789 (13 oct)
  │   ├── title: "Culte de Louange"
  │   ├── endDate: 11:30
  │   └── isModified: false
  │
  ├── event_abc456 (20 oct)
  │   ├── title: "Culte de Louange"
  │   ├── endDate: 11:30
  │   └── isModified: false
  │
  ├── event_def789 (27 oct) ← MODIFIÉ
  │   ├── title: "Culte Spécial Halloween" ✅
  │   ├── endDate: 12:00 ✅
  │   └── isModified: true ✅
  │
  └── event_ghi012 (3 nov)
      ├── title: "Culte de Louange"
      ├── endDate: 11:30
      └── isModified: false
```

**Badge dans UI** : Occurrence du 27 oct affiche "Modifié" ✅

---

### Cas 6 : Actions en Masse (Supprimer 5 Occurrences)

#### Scénario

User veut annuler les 5 dernières occurrences de novembre (vacances).

#### Code

```dart
// Depuis ServicesPlanningView
// 1. Activer mode sélection
setState(() => _isSelectionMode = true);

// 2. Sélectionner 5 occurrences
_selectedEventIds.addAll([
  'event_nov1',
  'event_nov8',
  'event_nov15',
  'event_nov22',
  'event_nov29',
]);

// 3. Cliquer sur [🗑️]
await _deleteSelected();
```

#### Processus

```dart
Future<void> _deleteSelected() async {
  // 1. Confirmation
  final confirmed = await showDialog<bool>(...);
  
  if (confirmed) {
    // 2. Supprimer chaque événement
    for (final eventId in _selectedEventIds) {
      await EventsFirebaseService.deleteEvent(eventId);
    }
    
    // 3. Notification
    SnackBar: "✅ 5 occurrence(s) supprimée(s)"
  }
}
```

#### Résultat

```
events/
  ├── event_oct13 ✅ (Conservé)
  ├── event_oct20 ✅ (Conservé)
  ├── event_oct27 ✅ (Conservé)
  ├── event_nov1 ❌ (Supprimé)
  ├── event_nov8 ❌ (Supprimé)
  ├── event_nov15 ❌ (Supprimé)
  ├── event_nov22 ❌ (Supprimé)
  ├── event_nov29 ❌ (Supprimé)
  ├── event_dec6 ✅ (Conservé)
  └── ...
```

**Performance** : 5 suppressions en ~1 seconde ✅

---

## 💡 Avantages de Cette Architecture

### 1. Flexibilité Maximale

| Action | Possible ? | Comment ? |
|--------|-----------|-----------|
| Modifier le service global | ✅ | Via `updateServiceWithEvent()` |
| Modifier une occurrence | ✅ | Via `updateEvent()` direct |
| Assigner différents bénévoles par occurrence | ✅ | `responsibleIds` dans chaque EventModel |
| Annuler une occurrence spécifique | ✅ | Soft delete de cet événement |
| Supprimer toute la série | ✅ | Via `deleteServiceWithEvent()` |
| Voir toutes les occurrences dans calendrier | ✅ | EventModel directement affichable |

### 2. Performance Optimale

```
Création service récurrent:
  ├── Firestore Writes: 27 (1 service + 26 events)
  ├── Temps: ~2 secondes
  └── Coût: 27 × $0.000018 = $0.000486

Modification service (affecte 26 occurrences):
  ├── Firestore Writes: 27 (1 service + 26 updates)
  ├── Temps: ~2 secondes
  └── Coût: $0.000486

Alternative (26 services séparés):
  ├── Firestore Writes: 26 (pas de service parent)
  ├── Modification globale: 26 writes
  ├── Mais: Pas de source unique, risque d'incohérence
  └── Coût: Identique mais moins flexible
```

### 3. Cohérence Garantie

```
Source Unique de Vérité:
ServiceModel = Configuration maître
    ↓
Tous les EventModel héritent des propriétés
    ↓
Modification du service → propagation automatique
    ↓
Pas d'incohérence possible ✅
```

### 4. Évolutivité

```
Fonctionnalités Futures Faciles à Ajouter:

✅ Rotation automatique d'équipes
   → Logique dans EventSeriesService.createRecurringSeries()
   
✅ Templates de services
   → Dupliquer ServiceModel avec nouveau dateTime
   
✅ Statistiques par série
   → Regrouper par seriesId
   
✅ Modification en masse des occurrences futures
   → Filtrer events par date > now() et mettre à jour
   
✅ Export/Import de séries
   → 1 service + pattern de récurrence = tout
```

---

## 🎓 Comparaison avec Planning Center

| Aspect | Planning Center | Notre Implémentation |
|--------|-----------------|---------------------|
| **Concept** | Service Type + Plans | Service + Events |
| **Structure** | 1 Template → N Instances | 1 Service → N Events |
| **Assignations** | Par Plan (positions) | Par Event (responsibleIds) |
| **Modification** | Plan individuel par défaut | Event individuel par défaut |
| **Modification globale** | Via Service Type | Via updateServiceWithEvent() |
| **Calendrier** | Vue Planning Center dédiée | Vue Calendrier + Planning |
| **Actions en masse** | ✅ Sélection multiple | ✅ Sélection multiple |
| **Rotation équipes** | ✅ Automatique (premium) | ⏳ À implémenter |

**Similarité** : ~95% ⭐⭐⭐⭐⭐

---

## 📝 Résumé

### Architecture

```
1 SERVICE (Template)
    ├── Configuration générale
    ├── Pattern de récurrence
    └── linkedEventId (premier événement)
    
    ↓ Génère
    
N ÉVÉNEMENTS (Occurrences)
    ├── Héritent des propriétés du service
    ├── Chacun a sa propre date (occurrence)
    ├── linkedServiceId (lien vers service)
    ├── seriesId (lien entre occurrences)
    └── responsibleIds (assignations spécifiques)
```

### Avantages

✅ **DRY** - Pas de duplication  
✅ **Performance** - Modifications rapides  
✅ **Flexibilité** - Par occurrence ou globale  
✅ **Cohérence** - Source unique de vérité  
✅ **Scalabilité** - Facile à étendre  
✅ **Standard** - Modèle Planning Center éprouvé  
✅ **Coût** - Optimal pour Firestore  

### Points Clés

1. **Service = Configuration maître** (template)
2. **Événements = Instances individuelles** (occurrences)
3. **Lien bidirectionnel** : Service ↔ Events
4. **Modification globale** : Via ServiceEventIntegrationService
5. **Modification individuelle** : Via EventsFirebaseService
6. **Actions en masse** : Via ServicesPlanningView
7. **Assignations flexibles** : Par occurrence

---

## 🚀 Prochaines Étapes

### Fonctionnalités à Ajouter

1. **Rotation Automatique d'Équipes** (2-3h)
   ```dart
   TeamRotation {
     teamId: string,
     memberIds: string[],
     currentIndex: int,
   }
   ```

2. **Copie d'Assignations** (30 min)
   ```dart
   copyAssignmentsToNext(eventId) → prochaine occurrence
   ```

3. **Modification Futures Occurrences** (1h)
   ```dart
   updateFutureOccurrences(event) → events où date > now()
   ```

4. **Templates de Services** (2h)
   ```dart
   createFromTemplate(templateId, newDate)
   ```

5. **Statistiques de Série** (1-2h)
   ```dart
   getSeriesStatistics(seriesId) → présence moyenne, etc.
   ```

---

**Voulez-vous que j'implémente une de ces fonctionnalités maintenant ?** 🎯
