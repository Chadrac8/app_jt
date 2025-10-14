# 🏗️ Architecture Intégration Groupes ↔ Événements avec Récurrence

**Date**: 13 octobre 2025  
**Inspiration**: Planning Center Online Groups  
**Status**: 📝 Spécification complète

---

## 🎯 Vision générale

### Concept Planning Center Online

Dans Planning Center Online Groups, **chaque réunion de groupe crée automatiquement un événement** dans le calendrier:

```
Groupe "Jeunes Adultes"
  ├─ Récurrence: Tous les vendredis à 19h30
  ├─ Lieu: Salle de jeunesse
  │
  └─ Génère automatiquement:
       ├─ Événement 18 oct 2025 19h30
       ├─ Événement 25 oct 2025 19h30
       ├─ Événement 01 nov 2025 19h30
       └─ ... (26 événements pour 6 mois)
```

### Avantages

1. **Calendrier unifié** : Toutes les réunions de groupes dans le calendrier principal
2. **Visibilité globale** : Les membres voient les réunions de leurs groupes dans "Mes événements"
3. **Gestion des présences** : Via le système d'événements existant
4. **Notifications automatiques** : Rappels avant chaque réunion
5. **Rapports centralisés** : Statistiques de participation unifiées

---

## 📊 Modèle de données

### GroupModel (Existant - Extended)

```dart
class GroupModel {
  // ... Champs existants ...
  
  // 🆕 NOUVEAUX CHAMPS pour intégration événements
  final bool generateEvents;        // Créer automatiquement des événements
  final String? linkedEventSeriesId; // ID de la série d'événements générés
  final Map<String, dynamic>? recurrenceConfig; // Configuration récurrence
  final DateTime? recurrenceStartDate; // Date début génération
  final DateTime? recurrenceEndDate;   // Date fin génération (optionnel)
  final int? maxOccurrences;           // Nombre max d'occurrences (optionnel)
}
```

### GroupMeetingModel (Existant - Extended)

```dart
class GroupMeetingModel {
  // ... Champs existants ...
  
  // 🆕 NOUVEAUX CHAMPS pour intégration événements
  final String? linkedEventId;  // ID de l'événement correspondant
  final bool isRecurring;       // Fait partie d'une série récurrente
  final String? seriesId;       // ID de la série (groupé avec linkedEventSeriesId)
  final bool isModified;        // Occurrence modifiée individuellement
}
```

### RecurrenceConfig

```dart
{
  "frequency": "weekly",  // daily, weekly, monthly, yearly
  "interval": 1,          // Tous les X jours/semaines/mois
  "dayOfWeek": 5,         // 1=Lundi, 7=Dimanche
  "time": "19:30",        // Heure de la réunion
  "duration": 120,        // Durée en minutes
  "excludeDates": [       // Dates à exclure (vacances, etc.)
    "2025-12-25",
    "2026-01-01"
  ],
  "timezone": "Europe/Paris"
}
```

---

## 🔄 Flux de création : Groupe → Événements

### Scénario 1 : Nouveau groupe avec récurrence

```
Utilisateur crée "Groupe Jeunes Adultes"
  ├─ Nom: "Groupe Jeunes Adultes"
  ├─ Fréquence: "Hebdomadaire"
  ├─ Jour: Vendredi
  ├─ Heure: 19h30
  ├─ Durée: 2h
  ├─ Lieu: "Salle de jeunesse"
  ├─ generateEvents: true ✅
  │
  ↓ GroupEventIntegrationService.createGroupWithEvents()
  │
  ├─ 1. Créer GroupModel
  │    └─ ID: group_abc123
  │
  ├─ 2. Générer série d'événements (via EventSeriesService)
  │    ├─ seriesId: series_xyz789
  │    ├─ 26 EventModel (6 mois, tous les vendredis)
  │    │   ├─ Event 18 oct 2025 19h30-21h30
  │    │   │   └─ linkedGroupId: group_abc123
  │    │   ├─ Event 25 oct 2025 19h30-21h30
  │    │   └─ ...
  │    └─ linkedEventSeriesId: series_xyz789
  │
  └─ 3. Créer GroupMeetingModel pour chaque événement
       ├─ Meeting 18 oct → linkedEventId: event_001
       ├─ Meeting 25 oct → linkedEventId: event_002
       └─ ...
```

### Scénario 2 : Ajout de récurrence à un groupe existant

```
Groupe existant "Bible Study"
  ↓
Utilisateur active "Générer événements"
  ↓
GroupEventIntegrationService.enableEventsForGroup()
  ├─ Analyser meetings existants
  ├─ Créer événements rétroactifs
  ├─ Lier meetings ↔ events
  └─ Générer événements futurs
```

---

## 🔗 Synchronisation bidirectionnelle

### Groupe → Événements

| Action sur Groupe | Impact sur Événements |
|-------------------|----------------------|
| Modifier lieu | ✅ Met à jour tous les événements de la série |
| Modifier heure | ✅ Met à jour startDate/endDate de tous les événements |
| Modifier durée | ✅ Met à jour endDate de tous les événements |
| Désactiver groupe | ✅ Annule tous les événements futurs (status: 'cancelled') |
| Supprimer groupe | ⚠️ Choix: Supprimer événements OU orphelins |

### Événements → Groupe

| Action sur Événement | Impact sur Groupe/Meeting |
|---------------------|--------------------------|
| Modifier titre | ✅ Met à jour GroupMeetingModel.title |
| Modifier lieu | ⚠️ Choix: Cette occurrence OU toute la série |
| Annuler événement | ✅ Marque meeting comme cancelled |
| Supprimer événement | ✅ Supprime le GroupMeetingModel correspondant |

---

## 🎨 Interface utilisateur

### 1. Page GroupDetailPage - Section Événements

```
┌─────────────────────────────────────────────┐
│ Groupe Jeunes Adultes                       │
├─────────────────────────────────────────────┤
│                                             │
│ 📅 ÉVÉNEMENTS AUTOMATIQUES                 │
│                                             │
│ [✓] Créer automatiquement des événements   │
│     dans le calendrier                      │
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ Récurrence                              ││
│ │ ○ Unique     ○ Quotidien               ││
│ │ ● Hebdomadaire  ○ Mensuel              ││
│ │                                         ││
│ │ Tous les [1] [semaine(s)]              ││
│ │ Le [Vendredi ▼]                        ││
│ │ À [19:30]                               ││
│ │ Durée: [2h00]                          ││
│ │                                         ││
│ │ Début: [18/10/2025]                    ││
│ │ ○ Pas de date de fin                   ││
│ │ ● Jusqu'au [18/04/2026]               ││
│ │ ○ Après [26] occurrences              ││
│ │                                         ││
│ │ 📊 26 réunions seront créées           ││
│ └─────────────────────────────────────────┘│
│                                             │
│ [📅 Voir dans le calendrier]               │
│                                             │
└─────────────────────────────────────────────┘
```

### 2. Onglet Réunions - Indicateurs

```
┌─────────────────────────────────────────────┐
│ RÉUNIONS (26)                               │
├─────────────────────────────────────────────┤
│                                             │
│ 📅 Octobre 2025                            │
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 🔗 Vendredi 18 oct · 19h30-21h30       ││
│ │    Salle de jeunesse                    ││
│ │    ✓ Lié à l'événement                 ││
│ │    👥 12/15 confirmés                   ││
│ │    [Voir événement →]                   ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 🔗 Vendredi 25 oct · 19h30-21h30       ││
│ │    Salle de jeunesse                    ││
│ │    ✓ Lié à l'événement                 ││
│ │    👥 14/15 confirmés                   ││
│ │    [Voir événement →]                   ││
│ └─────────────────────────────────────────┘│
│                                             │
└─────────────────────────────────────────────┘
```

### 3. EventDetailPage - Lien vers groupe

```
┌─────────────────────────────────────────────┐
│ Réunion Jeunes Adultes                      │
│ Vendredi 18 octobre 2025 · 19h30-21h30     │
├─────────────────────────────────────────────┤
│                                             │
│ 👥 GROUPE                                  │
│ ┌─────────────────────────────────────────┐│
│ │ 🔗 Groupe Jeunes Adultes               ││
│ │    Réunion hebdomadaire récurrente      ││
│ │    [Voir le groupe →]                   ││
│ └─────────────────────────────────────────┘│
│                                             │
│ 📅 SÉRIE                                   │
│ Événement 3/26 de la série                 │
│ [Voir toutes les occurrences]              │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🛠️ Services à créer

### 1. GroupEventIntegrationService

```dart
class GroupEventIntegrationService {
  // Création
  static Future<String> createGroupWithEvents({
    required GroupModel group,
    required bool generateEvents,
    RecurrenceConfig? recurrenceConfig,
  });
  
  // Activation événements pour groupe existant
  static Future<void> enableEventsForGroup({
    required String groupId,
    required RecurrenceConfig recurrenceConfig,
  });
  
  // Mise à jour groupe → événements
  static Future<void> updateGroupWithEvents({
    required GroupModel group,
    required GroupEditScope scope, // thisOnly, all
  });
  
  // Synchronisation meeting ↔ event
  static Future<void> syncMeetingWithEvent({
    required GroupMeetingModel meeting,
    required EventModel event,
  });
  
  // Génération événements
  static Future<List<EventModel>> generateEventsForGroup({
    required GroupModel group,
    required RecurrenceConfig config,
  });
  
  // Suppression
  static Future<void> deleteGroupWithEvents({
    required String groupId,
    required bool deleteEvents, // true = supprimer events, false = orphelins
  });
}
```

### 2. Enum GroupEditScope

```dart
enum GroupEditScope {
  /// Modifier uniquement cette occurrence
  thisOccurrenceOnly,
  
  /// Modifier cette occurrence et les suivantes
  thisAndFutureOccurrences,
  
  /// Modifier toutes les occurrences
  allOccurrences,
}
```

---

## 📋 Checklist d'implémentation

### Phase 1 : Modèles et services de base (2h)

- [ ] Étendre `GroupModel` avec champs intégration
- [ ] Étendre `GroupMeetingModel` avec champs intégration
- [ ] Créer `RecurrenceConfig` model
- [ ] Créer `GroupEventIntegrationService`
- [ ] Créer `GroupEditScope` enum

### Phase 2 : Création et génération (3h)

- [ ] Implémenter `createGroupWithEvents()`
- [ ] Implémenter `generateEventsForGroup()`
- [ ] Créer événements avec `linkedGroupId`
- [ ] Créer meetings avec `linkedEventId`
- [ ] Lier série via `seriesId`

### Phase 3 : Synchronisation bidirectionnelle (3h)

- [ ] Implémenter `updateGroupWithEvents()`
- [ ] Implémenter `syncMeetingWithEvent()`
- [ ] Gérer modifications groupe → événements
- [ ] Gérer modifications événement → meetings
- [ ] Dialog de choix portée modification

### Phase 4 : Interface utilisateur (4h)

- [ ] Section "Événements automatiques" dans `GroupDetailPage`
- [ ] Formulaire récurrence groupes
- [ ] Indicateurs `🔗 Lié à l'événement` dans liste meetings
- [ ] Boutons navigation meeting ↔ event
- [ ] Badge "Groupe" dans `EventDetailPage`

### Phase 5 : Gestion avancée (2h)

- [ ] Exclusion de dates (vacances)
- [ ] Modification occurrence individuelle
- [ ] Annulation en cascade
- [ ] Suppression avec choix events
- [ ] Gestion timezone

### Phase 6 : Index Firestore (30min)

- [ ] Index `events.linkedGroupId + startDate`
- [ ] Index `group_meetings.linkedEventId`
- [ ] Déployer index

### Phase 7 : Tests et documentation (1h)

- [ ] Tests création groupe avec événements
- [ ] Tests synchronisation
- [ ] Tests modification portée
- [ ] Documentation complète
- [ ] Guide utilisateur

---

## 🎯 Cas d'usage détaillés

### Cas 1 : Créer groupe avec événements récurrents

```dart
// 1. Créer le groupe
final group = GroupModel(
  id: '',
  name: 'Jeunes Adultes',
  description: 'Groupe pour les 18-30 ans',
  type: 'bible_study',
  frequency: 'weekly',
  location: 'Salle de jeunesse',
  dayOfWeek: 5, // Vendredi
  time: '19:30',
  generateEvents: true, // ← Active création événements
  recurrenceConfig: {
    'frequency': 'weekly',
    'interval': 1,
    'dayOfWeek': 5,
    'time': '19:30',
    'duration': 120,
    'startDate': '2025-10-18',
    'endDate': '2026-04-18',
  },
  // ...
);

// 2. Créer avec événements
final groupId = await GroupEventIntegrationService.createGroupWithEvents(
  group: group,
  generateEvents: true,
  recurrenceConfig: RecurrenceConfig.fromMap(group.recurrenceConfig!),
);

// Résultat:
// ✅ 1 GroupModel créé
// ✅ 26 EventModel créés (tous les vendredis pendant 6 mois)
// ✅ 26 GroupMeetingModel créés (liés aux events)
// ✅ seriesId commun pour tous les events
```

### Cas 2 : Modifier lieu du groupe

```dart
// Utilisateur modifie lieu du groupe
final updatedGroup = group.copyWith(
  location: 'Grande Salle', // Changement
  updatedAt: DateTime.now(),
);

// Afficher dialog de choix
final scope = await GroupEditScopeDialog.show(
  context,
  groupName: group.name,
  nextMeetingDate: nextMeeting.date,
);

// Mettre à jour selon portée
await GroupEventIntegrationService.updateGroupWithEvents(
  group: updatedGroup,
  scope: scope, // allOccurrences
);

// Résultat:
// ✅ GroupModel mis à jour
// ✅ TOUS les 26 EventModel mis à jour (location: 'Grande Salle')
// ✅ TOUS les 26 GroupMeetingModel mis à jour
```

### Cas 3 : Modifier une occurrence spécifique

```dart
// Utilisateur clique sur réunion du 25 octobre
// → Veut changer uniquement cette occurrence

final scope = await GroupEditScopeDialog.show(
  context,
  groupName: group.name,
  meetingDate: meeting.date,
);

if (scope == GroupEditScope.thisOccurrenceOnly) {
  // Modifier uniquement ce meeting
  final updatedMeeting = meeting.copyWith(
    location: 'Salle B',
    isModified: true, // ← Marquer comme modifié
  );
  
  await GroupsFirebaseService.updateMeeting(updatedMeeting);
  
  // Synchroniser avec événement correspondant
  if (meeting.linkedEventId != null) {
    final event = await EventsFirebaseService.getEvent(meeting.linkedEventId!);
    final updatedEvent = event.copyWith(
      location: 'Salle B',
      isModified: true,
    );
    await EventsFirebaseService.updateEvent(updatedEvent);
  }
}

// Résultat:
// ✅ Seul meeting du 25 oct modifié
// ✅ Event correspondant modifié
// ✅ Badge "Modified" affiché
// ✅ Autres occurrences inchangées
```

### Cas 4 : Calendrier unifié - Vue membre

```dart
// Membre Jean-Pierre ouvre "Mes événements"

final myEvents = await EventsFirebaseService.getEventsForUser(userId);

// Résultat affiché:
// ┌─────────────────────────────────────┐
// │ MES ÉVÉNEMENTS                      │
// ├─────────────────────────────────────┤
// │ Vendredi 18 oct · 19h30            │
// │ 👥 Groupe Jeunes Adultes           │
// │ 📍 Salle de jeunesse               │
// ├─────────────────────────────────────┤
// │ Dimanche 20 oct · 10h00            │
// │ ⛪ Culte Dominical                 │
// │ 📍 Sanctuaire                      │
// ├─────────────────────────────────────┤
// │ Vendredi 25 oct · 19h30            │
// │ 👥 Groupe Jeunes Adultes           │
// │ 📍 Salle de jeunesse               │
// └─────────────────────────────────────┘
```

---

## 🎨 Composants UI à créer

### 1. GroupRecurrenceFormWidget

```dart
class GroupRecurrenceFormWidget extends StatefulWidget {
  final RecurrenceConfig? initialConfig;
  final Function(RecurrenceConfig) onChanged;
  
  // Formulaire complet pour configurer récurrence
  // - Fréquence (daily, weekly, monthly)
  // - Interval
  // - Jour de la semaine
  // - Heure
  // - Durée
  // - Date début/fin
  // - Nombre d'occurrences
}
```

### 2. GroupEditScopeDialog

```dart
class GroupEditScopeDialog extends StatefulWidget {
  final String groupName;
  final DateTime meetingDate;
  
  // Dialog de choix portée modification
  // ○ Cette occurrence uniquement
  // ○ Cette occurrence et les suivantes
  // ○ Toutes les occurrences
  
  static Future<GroupEditScope?> show(
    BuildContext context, {
    required String groupName,
    required DateTime meetingDate,
  });
}
```

### 3. MeetingEventLinkBadge

```dart
class MeetingEventLinkBadge extends StatelessWidget {
  final GroupMeetingModel meeting;
  final VoidCallback onTap;
  
  // Badge: "🔗 Lié à l'événement"
  // Cliquable → Navigue vers EventDetailPage
}
```

### 4. EventGroupLinkBadge

```dart
class EventGroupLinkBadge extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  
  // Badge: "👥 Groupe: Jeunes Adultes"
  // Cliquable → Navigue vers GroupDetailPage
}
```

---

## 📊 Statistiques et rapports

### Dashboard Groupes - Participation

```
┌─────────────────────────────────────────────┐
│ TAUX DE PARTICIPATION                       │
├─────────────────────────────────────────────┤
│                                             │
│ Groupe Jeunes Adultes                       │
│ ████████████████░░░░ 82% (26 réunions)     │
│                                             │
│ Groupe Bible Study                          │
│ ███████████████████░ 95% (12 réunions)     │
│                                             │
│ Groupe Prière                               │
│ ██████████░░░░░░░░░░ 65% (8 réunions)      │
│                                             │
└─────────────────────────────────────────────┘
```

### Intégration avec EventsFirebaseService

```dart
// Statistiques combinées
final stats = await GroupEventIntegrationService.getGroupStatistics(groupId);

print(stats.toMap());
// {
//   'totalMeetings': 26,
//   'completedMeetings': 18,
//   'upcomingMeetings': 8,
//   'averageAttendance': 12.5,
//   'attendanceRate': 0.82,
//   'totalEventsGenerated': 26,
//   'eventsAttended': 15,
//   'eventsCancelled': 2,
// }
```

---

## 🔐 Permissions et sécurité

### Firestore Rules

```javascript
// Lecture événements de groupe
match /events/{eventId} {
  allow read: if resource.data.linkedGroupId != null 
    && isGroupMember(resource.data.linkedGroupId);
}

// Modification événements de groupe
match /events/{eventId} {
  allow update: if resource.data.linkedGroupId != null
    && isGroupLeader(resource.data.linkedGroupId);
}

// Helpers
function isGroupMember(groupId) {
  return exists(/databases/$(database)/documents/group_members/$(groupId + '_' + request.auth.uid));
}

function isGroupLeader(groupId) {
  let member = get(/databases/$(database)/documents/group_members/$(groupId + '_' + request.auth.uid));
  return member.data.role in ['leader', 'co-leader'];
}
```

---

## 🚀 Migration - Groupes existants

### Script de migration

```dart
Future<void> migrateExistingGroupsToEvents() async {
  final groups = await GroupsFirebaseService.getAllGroups();
  
  for (final group in groups) {
    if (!group.isActive) continue;
    
    print('Migration groupe: ${group.name}');
    
    // 1. Créer config récurrence depuis groupe existant
    final recurrenceConfig = RecurrenceConfig(
      frequency: group.frequency,
      interval: 1,
      dayOfWeek: group.dayOfWeek,
      time: group.time,
      duration: 120, // Défaut 2h
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 180)), // 6 mois
    );
    
    // 2. Générer événements
    await GroupEventIntegrationService.enableEventsForGroup(
      groupId: group.id,
      recurrenceConfig: recurrenceConfig,
    );
    
    print('✅ ${group.name}: Événements générés');
  }
  
  print('🎉 Migration terminée!');
}
```

---

## 📚 Documentation utilisateur

### Guide rapide

```markdown
# Créer un groupe avec événements automatiques

1. **Créer le groupe**
   - Nom, description, type
   
2. **Configurer la récurrence**
   - ✓ Cocher "Créer automatiquement des événements"
   - Choisir fréquence (Hebdomadaire recommandé)
   - Sélectionner jour et heure
   - Définir durée
   
3. **Définir la période**
   - Date de début
   - Date de fin OU nombre d'occurrences
   
4. **Sauvegarder**
   - ✅ Le groupe ET les événements sont créés
   - Les membres verront les réunions dans "Mes événements"

## Modifier une réunion

**Pour une seule occurrence** :
- Cliquer sur la réunion
- Modifier les détails
- Choisir "Cette occurrence uniquement"

**Pour toute la série** :
- Aller dans les détails du groupe
- Modifier les informations
- Choisir "Toutes les occurrences"
```

---

## ✅ Résumé

| Fonctionnalité | Status | Temps estimé |
|----------------|--------|--------------|
| Modèles étendus | 📝 À faire | 1h |
| Services d'intégration | 📝 À faire | 3h |
| Génération événements | 📝 À faire | 2h |
| Synchronisation bidirectionnelle | 📝 À faire | 3h |
| Interface utilisateur | 📝 À faire | 4h |
| Dialog de choix portée | 📝 À faire | 1h |
| Index Firestore | 📝 À faire | 30min |
| Tests et documentation | 📝 À faire | 1h |
| **TOTAL** | | **~15h30** |

---

**Prochaine étape** : Commencer l'implémentation Phase 1 (Modèles et services de base)
