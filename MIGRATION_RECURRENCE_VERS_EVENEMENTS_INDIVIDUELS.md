# Migration : Événements Récurrents → Événements Individuels

**Date**: 13 octobre 2025  
**Objectif**: Transformer le système de récurrence actuel en un système où chaque occurrence est un événement à part entière (comme Google Calendar, Outlook, etc.)

---

## 📋 Analyse du Système Actuel

### Architecture Existante
```
events (collection)
  └─ event_id
      ├─ isRecurring: true
      ├─ recurrence: {...}
      └─ [autres champs]

event_recurrences (collection)
  └─ recurrence_id
      ├─ parentEventId
      ├─ type (daily/weekly/monthly/yearly)
      ├─ interval
      ├─ daysOfWeek
      ├─ endDate
      └─ [configuration récurrence]

event_instances (collection) ⚠️ INSTANCES CALCULÉES
  └─ instance_id
      ├─ recurrenceId
      ├─ originalDate
      ├─ actualDate
      ├─ isCancelled
      └─ isModified
```

**Problèmes identifiés** :
- ❌ Les instances ne sont pas de vrais événements
- ❌ Impossible de modifier facilement une occurrence spécifique
- ❌ Complexité pour gérer exceptions et modifications
- ❌ Pas de flexibilité comme dans Google Calendar

---

## 🎯 Nouvelle Architecture (Style Google Calendar)

### Principe
Chaque occurrence = un événement complet dans la collection `events`, avec des métadonnées pour lier les occurrences entre elles.

```
events (collection)
  └─ event_id_1 (Événement parent OU occurrence 1)
      ├─ title: "Culte du dimanche"
      ├─ startDate: 2025-10-13 10:00
      ├─ isRecurring: true
      ├─ recurrenceRule: {...}
      ├─ seriesId: "series_xyz" ← NOUVEAU (ID commun à toutes les occurrences)
      ├─ isSeriesMaster: true ← NOUVEAU (cet événement est le "maître" de la série)
      └─ [autres champs normaux]
  
  └─ event_id_2 (Occurrence 2 - événement indépendant)
      ├─ title: "Culte du dimanche"
      ├─ startDate: 2025-10-20 10:00
      ├─ isRecurring: true
      ├─ recurrenceRule: {...} (même règle)
      ├─ seriesId: "series_xyz" ← même ID de série
      ├─ isSeriesMaster: false
      └─ [peut être modifié indépendamment !]
  
  └─ event_id_3 (Occurrence 3 - modifiée)
      ├─ title: "Culte du dimanche - SPÉCIAL NOËL" ← modifié !
      ├─ startDate: 2025-10-27 15:00 ← heure changée !
      ├─ isRecurring: true
      ├─ recurrenceRule: {...}
      ├─ seriesId: "series_xyz"
      ├─ isSeriesMaster: false
      ├─ isModifiedOccurrence: true ← NOUVEAU
      └─ originalStartDate: 2025-10-27 10:00 ← NOUVEAU (date originale calculée)
```

### Nouveaux Champs à Ajouter au Modèle EventModel

```dart
class EventModel {
  // ... champs existants ...
  
  // NOUVEAUX CHAMPS POUR SÉRIES RÉCURRENTES
  final String? seriesId;              // ID unique pour grouper toutes les occurrences
  final bool isSeriesMaster;           // true = événement maître (premier de la série)
  final bool isModifiedOccurrence;     // true = cette occurrence a été modifiée
  final DateTime? originalStartDate;   // Date de début originale (avant modification)
  final DateTime? deletedAt;           // Pour soft-delete (occurrence annulée)
  final int? occurrenceIndex;          // Index de l'occurrence (0, 1, 2...)
}
```

---

## 🔧 Plan de Migration

### Phase 1 : Modifications du Modèle (EventModel)

**Fichier** : `lib/models/event_model.dart`

**Actions** :
1. ✅ Ajouter les nouveaux champs :
   - `String? seriesId`
   - `bool isSeriesMaster` (default: false)
   - `bool isModifiedOccurrence` (default: false)
   - `DateTime? originalStartDate`
   - `DateTime? deletedAt`
   - `int? occurrenceIndex`

2. ✅ Mettre à jour `fromFirestore()` et `toFirestore()`
3. ✅ Mettre à jour `copyWith()`

### Phase 2 : Service de Gestion des Séries

**Nouveau fichier** : `lib/services/event_series_service.dart`

**Responsabilités** :
```dart
class EventSeriesService {
  /// Crée une série d'événements récurrents (génère N événements)
  static Future<List<String>> createRecurringSeries({
    required EventModel masterEvent,
    required EventRecurrence recurrence,
    int preGenerateMonths = 6, // Générer 6 mois à l'avance par défaut
  });
  
  /// Récupère tous les événements d'une série
  static Future<List<EventModel>> getSeriesEvents(String seriesId);
  
  /// Récupère l'événement maître d'une série
  static Future<EventModel?> getSeriesMaster(String seriesId);
  
  /// Modifie une occurrence spécifique (et seulement celle-ci)
  static Future<void> updateSingleOccurrence(
    String eventId,
    EventModel updatedEvent,
  );
  
  /// Modifie cette occurrence ET toutes les occurrences futures
  static Future<void> updateThisAndFutureOccurrences(
    String eventId,
    EventModel updatedEvent,
  );
  
  /// Modifie TOUTES les occurrences de la série
  static Future<void> updateAllOccurrences(
    String seriesId,
    EventModel updatedEvent,
  );
  
  /// Supprime une occurrence spécifique (soft delete)
  static Future<void> deleteSingleOccurrence(String eventId);
  
  /// Supprime cette occurrence ET toutes les futures
  static Future<void> deleteThisAndFutureOccurrences(String eventId);
  
  /// Supprime toute la série
  static Future<void> deleteAllOccurrences(String seriesId);
  
  /// Génère des occurrences supplémentaires (quand on approche de la fin)
  static Future<void> extendSeries(
    String seriesId,
    int additionalMonths,
  );
}
```

### Phase 3 : Création d'Événements Récurrents

**Fichier** : `lib/pages/event_form_page.dart` (méthode `_saveEvent()`)

**Logique de création** :
```dart
if (_isRecurring && _recurrenceModel != null) {
  // NOUVELLE APPROCHE : Créer plusieurs événements
  final seriesId = 'series_${DateTime.now().millisecondsSinceEpoch}';
  
  final masterEvent = event.copyWith(
    seriesId: seriesId,
    isSeriesMaster: true,
    occurrenceIndex: 0,
  );
  
  // Créer la série (génère automatiquement les occurrences)
  await EventSeriesService.createRecurringSeries(
    masterEvent: masterEvent,
    recurrence: eventRecurrence!,
    preGenerateMonths: 6, // Générer 6 mois à l'avance
  );
}
```

### Phase 4 : Interface de Modification (Dialog Google Calendar Style)

**Nouveau widget** : `lib/widgets/recurring_event_edit_dialog.dart`

**Apparence** :
```
┌───────────────────────────────────────────┐
│  Modifier un événement récurrent          │
├───────────────────────────────────────────┤
│                                           │
│  Cet événement fait partie d'une série.  │
│  Comment souhaitez-vous le modifier ?    │
│                                           │
│  ○ Cet événement uniquement              │
│     Modifier seulement cette occurrence   │
│                                           │
│  ○ Cet événement et les suivants         │
│     Modifier cette occurrence et toutes   │
│     les futures occurrences               │
│                                           │
│  ○ Tous les événements de la série       │
│     Modifier toutes les occurrences       │
│     (passées et futures)                  │
│                                           │
│         [Annuler]      [Continuer]        │
└───────────────────────────────────────────┘
```

**Code** :
```dart
enum RecurringEditOption {
  thisOnly,
  thisAndFuture,
  all,
}

class RecurringEventEditDialog extends StatefulWidget {
  final EventModel event;
  
  const RecurringEventEditDialog({required this.event});
  
  static Future<RecurringEditOption?> show(
    BuildContext context,
    EventModel event,
  ) {
    return showDialog<RecurringEditOption>(
      context: context,
      builder: (context) => RecurringEventEditDialog(event: event),
    );
  }
}
```

### Phase 5 : Interface de Suppression

**Nouveau widget** : `lib/widgets/recurring_event_delete_dialog.dart`

**Apparence** :
```
┌───────────────────────────────────────────┐
│  Supprimer un événement récurrent         │
├───────────────────────────────────────────┤
│                                           │
│  ○ Cet événement uniquement              │
│     Supprimer seulement cette occurrence  │
│                                           │
│  ○ Cet événement et les suivants         │
│     Supprimer cette occurrence et toutes  │
│     les futures occurrences               │
│                                           │
│  ○ Tous les événements de la série       │
│     Supprimer toutes les occurrences      │
│                                           │
│         [Annuler]      [Supprimer]        │
└───────────────────────────────────────────┘
```

### Phase 6 : Affichage dans le Calendrier

**Fichier** : `lib/widgets/event_calendar_view.dart`

**Modifications** :
- Les événements récurrents apparaissent naturellement (ce sont de vrais événements)
- Indicateur visuel pour montrer qu'un événement fait partie d'une série
- Badge "Modifié" si `isModifiedOccurrence: true`

**Code** :
```dart
// Dans l'affichage de la card d'événement
if (event.seriesId != null) {
  // Afficher une icône de récurrence
  Icon(Icons.repeat, size: 16, color: Colors.grey)
}

if (event.isModifiedOccurrence) {
  // Badge "Modifié"
  Container(
    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.orangeStandard,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('Modifié', style: TextStyle(fontSize: 10)),
  )
}
```

### Phase 7 : Génération Automatique (Background Task)

**Nouveau service** : `lib/services/event_series_maintenance_service.dart`

**Responsabilités** :
- Vérifier régulièrement si des séries approchent de leur fin
- Générer automatiquement les 3 prochains mois d'occurrences
- Nettoyer les occurrences passées (optionnel, après 1 an)

**Code** :
```dart
class EventSeriesMaintenanceService {
  /// Vérifie toutes les séries actives et génère des occurrences supplémentaires
  static Future<void> maintainAllSeries() async {
    final now = DateTime.now();
    final threeMonthsFromNow = now.add(Duration(days: 90));
    
    // Récupérer tous les événements maîtres
    final masterEvents = await EventsFirebaseService.getEvents(
      filters: {'isSeriesMaster': true, 'isRecurring': true},
    );
    
    for (final master in masterEvents) {
      // Récupérer la dernière occurrence de la série
      final seriesEvents = await EventSeriesService.getSeriesEvents(master.seriesId!);
      final lastEvent = seriesEvents.last;
      
      // Si la dernière occurrence est dans moins de 3 mois, générer plus
      if (lastEvent.startDate.isBefore(threeMonthsFromNow)) {
        await EventSeriesService.extendSeries(master.seriesId!, 3);
      }
    }
  }
}
```

---

## 📊 Comparaison Avant/Après

### Avant (Système Actuel)
```
Créer événement récurrent
  ↓
1 événement parent + 1 règle récurrence
  ↓
Instances générées à la volée (event_instances)
  ↓
Modifications = overrides complexes
```

**Problèmes** :
- ❌ Instances ne sont pas de vrais événements
- ❌ Complexité pour modifier une occurrence
- ❌ Pas d'indépendance des occurrences

### Après (Nouveau Système)
```
Créer événement récurrent
  ↓
N événements complets créés (seriesId commun)
  ↓
Chaque occurrence = événement à part entière
  ↓
Modifications = simple updateEvent()
```

**Avantages** :
- ✅ Chaque occurrence est un vrai événement
- ✅ Modification ultra simple (comme Google Calendar)
- ✅ Suppression flexible (une, futures, toutes)
- ✅ Indépendance totale des occurrences

---

## 🗃️ Requêtes Firestore

### Récupérer tous les événements d'une série
```dart
final seriesEvents = await FirebaseFirestore.instance
  .collection('events')
  .where('seriesId', isEqualTo: seriesId)
  .where('deletedAt', isNull: true) // Ignorer les supprimées
  .orderBy('startDate')
  .get();
```

### Récupérer l'événement maître
```dart
final masterEvent = await FirebaseFirestore.instance
  .collection('events')
  .where('seriesId', isEqualTo: seriesId)
  .where('isSeriesMaster', isEqualTo: true)
  .limit(1)
  .get();
```

### Index Firestore Requis
```json
{
  "collectionGroup": "events",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "seriesId", "order": "ASCENDING"},
    {"fieldPath": "deletedAt", "order": "ASCENDING"},
    {"fieldPath": "startDate", "order": "ASCENDING"}
  ]
},
{
  "collectionGroup": "events",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "seriesId", "order": "ASCENDING"},
    {"fieldPath": "isSeriesMaster", "order": "ASCENDING"}
  ]
}
```

---

## 🎨 Expérience Utilisateur

### Scénario 1 : Créer un événement récurrent
```
Utilisateur :
1. Remplit formulaire événement
2. Active "Événement récurrent"
3. Configure : "Tous les dimanches, 52 fois"
4. Clique "Enregistrer"

Système :
✅ Crée 52 événements individuels dans Firestore
✅ Tous liés par le même seriesId
✅ Le premier est isSeriesMaster: true
```

### Scénario 2 : Modifier une occurrence
```
Utilisateur :
1. Clique sur le culte du 27 octobre
2. Clique "Modifier"
3. Dialog : "Modifier cet événement uniquement"
4. Change le titre en "Culte Spécial Halloween"
5. Clique "Enregistrer"

Système :
✅ Met à jour SEULEMENT cet événement
✅ Marque isModifiedOccurrence: true
✅ Conserve originalStartDate
✅ Les autres occurrences ne changent pas
```

### Scénario 3 : Modifier toutes les occurrences futures
```
Utilisateur :
1. Clique sur le culte du 27 octobre
2. Clique "Modifier"
3. Dialog : "Cet événement et les suivants"
4. Change l'heure de 10h à 11h
5. Clique "Enregistrer"

Système :
✅ Récupère toutes les occurrences avec startDate >= 27 oct
✅ Met à jour l'heure pour chacune
✅ Batch update Firestore (optimisé)
```

### Scénario 4 : Supprimer une occurrence
```
Utilisateur :
1. Clique sur le culte du 3 novembre
2. Clique "Supprimer"
3. Dialog : "Supprimer cet événement uniquement"
4. Confirme

Système :
✅ Soft delete : deletedAt = now()
✅ L'événement reste en DB mais invisible
✅ Possibilité de restaurer si besoin
```

---

## ⚠️ Points d'Attention

### Performance
- **Problème** : Créer 50+ événements d'un coup peut être lent
- **Solution** : Batch writes Firestore (500 ops max par batch)
- **Code** :
```dart
final batch = FirebaseFirestore.instance.batch();
for (final event in events) {
  final docRef = collection.doc();
  batch.set(docRef, event.toFirestore());
}
await batch.commit();
```

### Stockage
- **Avant** : 1 événement + 1 règle = ~2 KB
- **Après** : 50 événements = ~100 KB (50x plus)
- **Impact** : Négligeable pour une église (milliers d'événements = quelques MB)
- **Firestore** : Gratuit jusqu'à 1 GB de stockage

### Maintenance
- Générer automatiquement les prochaines occurrences
- Nettoyer les anciennes occurrences (> 1 an) optionnel
- Monitoring : alertes si une série n'a plus d'occurrences futures

---

## 🧪 Tests à Effectuer

### Tests Unitaires
- ✅ Génération correcte des occurrences (daily/weekly/monthly/yearly)
- ✅ Modification d'une seule occurrence
- ✅ Modification de toutes les occurrences
- ✅ Suppression avec soft delete

### Tests d'Intégration
- ✅ Créer série → Vérifier 50 événements en DB
- ✅ Modifier occurrence → Vérifier isModifiedOccurrence
- ✅ Supprimer occurrence → Vérifier deletedAt
- ✅ Affichage calendrier → Vérifier tri et affichage

### Tests Utilisateur
- ✅ Création événement récurrent fluide
- ✅ Dialog de modification clair
- ✅ Performance acceptable (<2s pour créer 100 occurrences)

---

## 📅 Planning d'Implémentation

### Sprint 1 (2-3 heures)
- [ ] Modifier EventModel (nouveaux champs)
- [ ] Créer EventSeriesService (méthodes de base)
- [ ] Tests unitaires

### Sprint 2 (3-4 heures)
- [ ] Modifier event_form_page.dart (création séries)
- [ ] Créer RecurringEventEditDialog
- [ ] Créer RecurringEventDeleteDialog

### Sprint 3 (2-3 heures)
- [ ] Intégrer dialogs dans event_detail_page
- [ ] Affichage indicateurs visuels (calendrier)
- [ ] Tests d'intégration

### Sprint 4 (1-2 heures)
- [ ] Créer EventSeriesMaintenanceService
- [ ] Documentation finale
- [ ] Tests utilisateur

**Total estimé** : 8-12 heures

---

## 🚀 Migration des Données Existantes

### Script de Migration (Optionnel)
```dart
/// Convertit les anciennes règles de récurrence en événements individuels
Future<void> migrateOldRecurrences() async {
  // 1. Récupérer tous les événements avec isRecurring: true (ancien système)
  final oldRecurringEvents = await getOldRecurringEvents();
  
  for (final oldEvent in oldRecurringEvents) {
    // 2. Récupérer sa règle de récurrence
    final recurrence = await EventRecurrenceService.getEventRecurrences(oldEvent.id);
    
    if (recurrence.isEmpty) continue;
    
    // 3. Créer la nouvelle série
    final seriesId = 'series_migrated_${oldEvent.id}';
    final masterEvent = oldEvent.copyWith(
      seriesId: seriesId,
      isSeriesMaster: true,
    );
    
    // 4. Générer les occurrences
    await EventSeriesService.createRecurringSeries(
      masterEvent: masterEvent,
      recurrence: oldEvent.recurrence!,
      preGenerateMonths: 6,
    );
    
    // 5. Supprimer l'ancien événement parent
    await EventsFirebaseService.deleteEvent(oldEvent.id);
    await EventRecurrenceService.deleteRecurrence(recurrence.first.id);
  }
}
```

---

## ✅ Critères de Succès

- [ ] Chaque occurrence est un événement à part entière
- [ ] Modification d'une occurrence fonctionne (uniquement, futures, toutes)
- [ ] Suppression d'une occurrence fonctionne (uniquement, futures, toutes)
- [ ] Performance acceptable (<3s pour créer 100 occurrences)
- [ ] Interface utilisateur claire et intuitive
- [ ] Documentation complète
- [ ] Tests passent à 100%

---

**Conclusion** : Ce système est BEAUCOUP plus simple et flexible que le système actuel. Il suit les meilleures pratiques de Google Calendar, Outlook, et Planning Center Online. Chaque occurrence est un vrai événement, ce qui simplifie énormément la logique de modification et de suppression.

