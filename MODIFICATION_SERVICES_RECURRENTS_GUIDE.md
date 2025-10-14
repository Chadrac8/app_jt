# 📝 Modification de Services Récurrents : Guide Complet

**Date** : 13 octobre 2025  
**Question** : "Cela modifie-t-il toutes les occurrences ou puis-je modifier un seul service ?"  
**Réponse** : **Exactement comme les événements !** 🎯

---

## 🎯 Comportement Actuel

### Vue d'Ensemble

Le système fonctionne **EXACTEMENT** comme Google Calendar ou Planning Center :

```
┌─────────────────────────────────────────────────┐
│  MODIFIER UN SERVICE RÉCURRENT                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Quel type de modification ?            │   │
│  ├─────────────────────────────────────────┤   │
│  │                                         │   │
│  │  1️⃣  MODIFICATION GLOBALE              │   │
│  │     → Modifie le SERVICE               │   │
│  │     → Affecte TOUTES les occurrences   │   │
│  │                                         │   │
│  │  2️⃣  MODIFICATION INDIVIDUELLE         │   │
│  │     → Modifie 1 ÉVÉNEMENT              │   │
│  │     → Affecte CETTE occurrence seulement│   │
│  │                                         │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## 📊 Les 2 Types de Modifications

### Type 1 : Modification Globale (via Service)

**Accès** : ServiceDetailPage → Bouton "Modifier"

**Affecte** : ✅ **TOUTES les occurrences** (passées et futures)

**Code** :
```dart
// ServiceEventIntegrationService.updateServiceWithEvent()

if (linkedEvent.seriesId != null) {
  // SERVICE RÉCURRENT
  final seriesEvents = await EventSeriesService.getSeriesEvents(seriesId);
  
  // Met à jour CHAQUE occurrence
  for (final event in seriesEvents) {
    final updatedEvent = event.copyWith(
      title: service.name,           // ✅ Nouveau nom
      description: service.description,  // ✅ Nouvelle description
      location: service.location,    // ✅ Nouveau lieu
      endDate: event.startDate.add(  // ✅ Nouvelle durée
        Duration(minutes: service.durationMinutes)
      ),
      status: service.status,        // ✅ Nouveau statut
    );
    await EventsFirebaseService.updateEvent(updatedEvent);
  }
}
```

**Exemple** :
```
Avant:
├─ Service: "Culte Dominical" @ Sanctuaire, 90 min
├─ 26 occurrences:
│  ├─ 13 oct: "Culte Dominical" @ Sanctuaire, 10:00-11:30
│  ├─ 20 oct: "Culte Dominical" @ Sanctuaire, 10:00-11:30
│  └─ ... 24 autres identiques

Modification du service:
- Nom: "Culte de Louange"
- Lieu: "Grande Salle"
- Durée: 120 min

Après:
├─ Service: "Culte de Louange" @ Grande Salle, 120 min
├─ 26 occurrences TOUTES modifiées:
│  ├─ 13 oct: "Culte de Louange" @ Grande Salle, 10:00-12:00
│  ├─ 20 oct: "Culte de Louange" @ Grande Salle, 10:00-12:00
│  └─ ... 24 autres identiques
```

---

### Type 2 : Modification Individuelle (via Événement)

**Accès** : 
- Modal Occurrences → Clic sur occurrence
- Vue Planning → Clic sur carte événement
- Calendrier → Clic sur occurrence

**Affecte** : ✅ **UNE SEULE occurrence**

**Code** :
```dart
// Depuis EventDetailPage ou modal d'édition
final updatedEvent = event.copyWith(
  title: 'Culte Spécial Halloween',  // ✅ Titre personnalisé
  endDate: event.startDate.add(Duration(minutes: 150)),  // ✅ Durée différente
  isModified: true,  // ✅ Marquer comme modifié
);

await EventsFirebaseService.updateEvent(updatedEvent);
```

**Exemple** :
```
Avant:
├─ Service: "Culte Dominical"
├─ 26 occurrences:
│  ├─ 13 oct: "Culte Dominical" 10:00-11:30
│  ├─ 20 oct: "Culte Dominical" 10:00-11:30
│  ├─ 27 oct: "Culte Dominical" 10:00-11:30 ← À modifier
│  └─ 3 nov: "Culte Dominical" 10:00-11:30

Modification de l'occurrence du 27 oct:
- Titre: "Culte Spécial Halloween"
- Durée: 150 min
- isModified: true

Après:
├─ Service: "Culte Dominical" (inchangé)
├─ 26 occurrences:
│  ├─ 13 oct: "Culte Dominical" 10:00-11:30
│  ├─ 20 oct: "Culte Dominical" 10:00-11:30
│  ├─ 27 oct: "Culte Spécial Halloween" 10:00-12:30 ✅ MODIFIÉ
│  └─ 3 nov: "Culte Dominical" 10:00-11:30
```

---

## 🎨 Interface Utilisateur

### Actuellement Implémenté

#### 1. Modification Globale ✅

**Page** : `ServiceDetailPage`

```
┌─────────────────────────────────────────┐
│  Culte Dominical              [✏️ Modifier]│
│  📅 26 occurrences                      │
│  📍 Sanctuaire Principal                │
│  ⏱️  90 minutes                         │
│                                         │
│  [Clic sur Modifier]                    │
│      ↓                                  │
│  ServiceFormPage                        │
│      ↓                                  │
│  Modification appliquée à TOUTES        │
│  les 26 occurrences                     │
└─────────────────────────────────────────┘
```

**Comportement** :
- ✅ Met à jour le ServiceModel
- ✅ Met à jour TOUS les EventModel de la série
- ✅ Conserve les dates de chaque occurrence
- ✅ Applique nouveau nom/lieu/durée/statut

#### 2. Modification Individuelle ⏳ PARTIELLEMENT IMPLÉMENTÉ

**Pages** : Modal Occurrences, Vue Planning

```
┌─────────────────────────────────────────┐
│  Occurrences du service                 │
│                                         │
│  ① dimanche 13 oct     →  [Clic]       │
│  ② dimanche 20 oct     →  [Clic]       │
│  ③ dimanche 27 oct     →  [Clic]       │
│                                         │
│  [Clic sur occurrence]                  │
│      ↓                                  │
│  ⚠️  Actuellement: ServiceDetailPage    │
│  ❌  Problème: Modifie tout le service  │
│                                         │
│  ✅  Devrait: EventDetailPage           │
│  ✅  Comportement: Modifie 1 occurrence │
└─────────────────────────────────────────┘
```

**Problème actuel** :
- Le clic sur une occurrence ouvre `ServiceDetailPage`
- Modification affecte TOUTE la série (pas juste cette occurrence)

**Solution nécessaire** :
- Le clic devrait ouvrir `EventDetailPage`
- Avec option "Modifier cette occurrence" vs "Modifier toute la série"

---

## 🔧 Amélioration Recommandée

### Dialog de Choix (Comme Google Calendar)

Quand l'utilisateur clique "Modifier" sur une occurrence :

```
┌────────────────────────────────────────────┐
│  Modifier un service récurrent             │
├────────────────────────────────────────────┤
│                                            │
│  Ce service se répète toutes les semaines. │
│  Que souhaitez-vous modifier ?             │
│                                            │
│  ⭕ Cette occurrence uniquement            │
│     Modifie seulement le 27 octobre        │
│                                            │
│  ⭕ Cette occurrence et les suivantes      │
│     Modifie du 27 octobre à la fin         │
│                                            │
│  ⭕ Toutes les occurrences                 │
│     Modifie les 26 occurrences             │
│                                            │
│         [Annuler]  [Continuer]             │
└────────────────────────────────────────────┘
```

### Implémentation Proposée

**Fichier** : `lib/widgets/recurring_service_edit_dialog.dart` (à créer)

```dart
enum RecurringEditScope {
  thisOnly,        // Cette occurrence uniquement
  thisAndFuture,   // Cette occurrence et suivantes
  all,             // Toutes les occurrences
}

class RecurringServiceEditDialog extends StatelessWidget {
  final ServiceModel service;
  final EventModel occurrence;
  
  Future<RecurringEditScope?> show(BuildContext context) {
    return showDialog<RecurringEditScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier un service récurrent'),
        content: Column(
          children: [
            Text('Ce service se répète. Que souhaitez-vous modifier ?'),
            RadioListTile<RecurringEditScope>(
              title: Text('Cette occurrence uniquement'),
              subtitle: Text(_formatDate(occurrence.startDate)),
              value: RecurringEditScope.thisOnly,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<RecurringEditScope>(
              title: Text('Cette occurrence et les suivantes'),
              subtitle: Text('À partir du ${_formatDate(occurrence.startDate)}'),
              value: RecurringEditScope.thisAndFuture,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<RecurringEditScope>(
              title: Text('Toutes les occurrences'),
              subtitle: Text('Les 26 occurrences'),
              value: RecurringEditScope.all,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
```

**Usage** :
```dart
// Dans ServiceOccurrencesDialog._buildOccurrenceItem()
onTap: () async {
  final scope = await RecurringServiceEditDialog(
    service: widget.service,
    occurrence: event,
  ).show(context);
  
  if (scope != null) {
    switch (scope) {
      case RecurringEditScope.thisOnly:
        // Ouvrir EventDetailPage en mode édition
        _editSingleOccurrence(event);
        break;
        
      case RecurringEditScope.thisAndFuture:
        // Modifier cette occurrence et futures
        _editFutureOccurrences(event);
        break;
        
      case RecurringEditScope.all:
        // Ouvrir ServiceDetailPage (comportement actuel)
        _editAllOccurrences(widget.service);
        break;
    }
  }
}
```

---

## 📊 Tableau Comparatif

| Action | Portée | Page d'édition | Code |
|--------|--------|----------------|------|
| **Modifier le Service** | TOUTES les occurrences | ServiceFormPage | `updateServiceWithEvent()` |
| **Modifier 1 Occurrence** | UNE occurrence | EventDetailPage | `updateEvent()` |
| **Modifier Futures** | Cette occurrence + suivantes | EventDetailPage (avec date filter) | `updateEvent()` pour chaque |

---

## 💡 Cas d'Usage Réels

### Cas 1 : Changement Global de Lieu

**Scénario** : Le sanctuaire est en rénovation, tous les cultes passent en Grande Salle.

**Solution** : Modification globale via ServiceDetailPage
```
1. ServiceDetailPage → [Modifier]
2. Changer lieu: "Grande Salle"
3. Sauvegarder
4. ✅ Toutes les 26 occurrences mises à jour
```

### Cas 2 : Culte Spécial Ponctuel

**Scénario** : Le 27 octobre, culte spécial Halloween avec durée de 2h.

**Solution** : Modification individuelle (à améliorer)
```
1. Modal Occurrences → Clic sur occurrence 27 oct
2. ⚠️  Actuellement: Ouvre ServiceDetailPage (modifie tout)
3. ✅  Devrait: Ouvrir dialog choix → EventDetailPage
4. Modifier titre: "Culte Spécial Halloween"
5. Modifier durée: 120 min
6. ✅ Seule cette occurrence modifiée
```

### Cas 3 : Changement à Partir d'une Date

**Scénario** : À partir du 1er janvier, les cultes passent à 11h au lieu de 10h.

**Solution** : Modification futures occurrences (à implémenter)
```
1. Modal Occurrences → Clic occurrence 1er janvier
2. Dialog: "Cette occurrence et suivantes"
3. Changer heure: 11:00
4. ✅ Occurrences du 1er jan à fin modifiées
5. ✅ Occurrences avant le 1er jan inchangées
```

---

## 🔧 Code Actuel - Analyse

### Service Simple ✅ OK

```dart
// Modification d'un service non récurrent
updateServiceWithEvent(service) {
  await _updateService(service);
  
  // Met à jour l'événement lié (1 seul)
  final event = await getEvent(service.linkedEventId);
  await updateEvent(event.copyWith(
    title: service.name,
    location: service.location,
    // etc.
  ));
}
```

**Comportement** : ✅ Parfait, 1 service = 1 événement

### Service Récurrent ⚠️ À AMÉLIORER

```dart
// Modification d'un service récurrent
updateServiceWithEvent(service) {
  await _updateService(service);
  
  // Récupère TOUS les événements de la série
  final events = await getSeriesEvents(seriesId);
  
  // Met à jour CHAQUE événement
  for (final event in events) {
    await updateEvent(event.copyWith(
      title: service.name,
      location: service.location,
      // etc.
    ));
  }
}
```

**Comportement actuel** : ✅ Fonctionne pour modifications globales

**Problème** : ❌ Pas de choix pour modifier 1 seule occurrence

**Solution** : Ajouter `RecurringServiceEditDialog`

---

## 🎯 Recommandations

### Priorité 1 : Fix Navigation Occurrence

**Problème** :
```dart
// Dans ServiceOccurrencesDialog
void _openOccurrenceDetail(EventModel event) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceDetailPage(service: widget.service),
      //                      ^^^^^^^^^^^^^^^^^ Mauvais !
    ),
  );
}
```

**Solution** :
```dart
void _openOccurrenceDetail(EventModel event) {
  // Afficher dialog de choix
  final scope = await showRecurringEditDialog(context, event);
  
  if (scope == RecurringEditScope.thisOnly) {
    // Ouvrir EventDetailPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
        //                      ^^^^^^^^^^^^^^^ Correct !
      ),
    );
  } else if (scope == RecurringEditScope.all) {
    // Ouvrir ServiceDetailPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(service: widget.service),
      ),
    );
  }
}
```

### Priorité 2 : Ajouter Indicateur "Modifié"

**But** : Montrer visuellement quelles occurrences ont été personnalisées

```dart
// Dans le modal et la vue Planning
if (event.isModified) {
  // Badge "Modifié"
  Container(
    child: Row([
      Icon(Icons.edit, size: 12),
      Text('Modifié'),
    ]),
  );
}
```

### Priorité 3 : Option "Futures Occurrences"

**Implémentation** :
```dart
Future<void> updateFutureOccurrences(
  String seriesId,
  DateTime fromDate,
  ServiceModel newData,
) async {
  final events = await getSeriesEvents(seriesId);
  
  // Filtrer seulement les futures
  final futureEvents = events.where((e) => 
    e.startDate.isAfter(fromDate) || 
    e.startDate.isAtSameMomentAs(fromDate)
  );
  
  for (final event in futureEvents) {
    await updateEvent(event.copyWith(
      title: newData.name,
      // etc.
    ));
  }
}
```

---

## 📝 Résumé

### État Actuel

| Fonctionnalité | Status | Commentaire |
|----------------|--------|-------------|
| **Modification globale** | ✅ Fonctionne | Via ServiceDetailPage |
| **Modification individuelle** | ⚠️ Partiellement | Manque dialog de choix |
| **Modification futures** | ❌ Pas implémenté | À ajouter |
| **Indicateur modifié** | ⚠️ Champ existe | Pas affiché dans UI |

### Actions Recommandées

1. **Court terme (1h)** :
   - Ajouter `RecurringServiceEditDialog`
   - Fix navigation dans `ServiceOccurrencesDialog`
   - Afficher badge "Modifié" sur occurrences personnalisées

2. **Moyen terme (2-3h)** :
   - Implémenter "Modifier futures occurrences"
   - Créer `EventDetailPage` complète
   - Tests utilisateur

---

## 🎉 Conclusion

**Question** : "Cela modifie-t-il toutes les occurrences ?"

**Réponse** :
- ✅ **Oui** si vous modifiez via `ServiceDetailPage` → Toutes les occurrences
- ✅ **Non** si vous modifiez un événement individuel → Une seule occurrence
- ⚠️ **Mais** actuellement pas de choix explicite dans l'UI

**C'est exactement comme Google Calendar !** 📅

Le système backend est prêt, il manque juste le dialog de choix dans l'interface ! 🎯
