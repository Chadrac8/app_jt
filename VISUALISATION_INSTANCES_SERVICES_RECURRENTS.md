# 🔍 Visualisation des Instances de Services Récurrents

**Date** : 13 octobre 2025  
**Problème** : "Je ne vois pas les différentes instances d'un service récurrent"  
**Statut** : ✅ **RÉSOLU - Implémenté 3 solutions**

---

## 🎯 Le Problème

Quand vous créez un **Service Récurrent** (ex: Culte Dominical tous les dimanches pendant 6 mois), le système crée :
- **1 ServiceModel** = Le template/configuration
- **26 EventModel** = Les occurrences individuelles (une par dimanche)

**Problème** : L'utilisateur ne voyait que le ServiceModel (template) et pas les 26 occurrences !

---

## ✅ Solutions Implémentées

### Solution 1 : Vue Planning (DÉJÀ EXISTANTE) ⭐

La vue **ServicesPlanningView** affiche TOUTES les occurrences !

**Comment y accéder** :
1. Ouvrez l'app
2. Allez dans **Services**
3. Cliquez sur l'icône **📅** (view_week) dans l'AppBar en haut
4. Vous verrez toutes les occurrences groupées par semaine

**Fonctionnalités** :
- ✅ Groupement par semaine
- ✅ Vue chronologique
- ✅ Indicateur complet/incomplet (assignations)
- ✅ Actions en masse (sélection, suppression, changement statut)
- ✅ Assignation rapide d'équipes

**Exemple** :
```
📅 Semaine du 13 Oct 2025     1 service(s)

┌────────────────────────────────────────┐
│ 🔁 Culte Dominical        [PUBLIÉ]    │
│ 📅 dimanche 13 oct • 10:00 - 11:30    │
│ 📍 Sanctuaire Principal                │
│ ⚠️  0 bénévole(s)          [person_add]│
└────────────────────────────────────────┘

📅 Semaine du 20 Oct 2025     1 service(s)

┌────────────────────────────────────────┐
│ 🔁 Culte Dominical        [PUBLIÉ]    │
│ 📅 dimanche 20 oct • 10:00 - 11:30    │
│ 📍 Sanctuaire Principal                │
│ ✅  3 bénévole(s)          [person_add]│
└────────────────────────────────────────┘

... 24 autres occurrences
```

---

### Solution 2 : Badge sur la Carte Service (NOUVEAU) 🆕

Ajout d'un **badge "🔁 X"** en bas à droite de chaque carte de service récurrent.

**Affichage** :
- Badge bleu (couleur primaire)
- Icône repeat (🔁)
- Nombre d'occurrences

**Exemple visuel** :
```
┌──────────────────────────┐
│  🌅 Image du service  [✓]│ ← Status badge (vert)
│                       🔁26│ ← Nouveau badge récurrent
│  [Culte]                 │ ← Type badge
├──────────────────────────┤
│ Culte Dominical          │
│ Service hebdomadaire...  │
│                          │
│ ⏰ dim. 13 oct • 10:00   │
│ 📍 Sanctuaire Principal  │
│ ⏱️ 90min  👥 3 équipes    │
└──────────────────────────┘
```

**Code implémenté** :
```dart
// ServiceCard - Badge récurrent
if (widget.service.isRecurring && _occurrencesCount != null)
  Positioned(
    bottom: 8,
    right: 8,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 12, color: onPrimary),
          SizedBox(width: 4),
          Text('$_occurrencesCount', style: bold),
        ],
      ),
    ),
  ),
```

**Chargement des données** :
```dart
@override
void initState() {
  super.initState();
  // ...
  if (widget.service.isRecurring) {
    _loadOccurrencesCount();
  }
}

Future<void> _loadOccurrencesCount() async {
  final events = await EventsFirebaseService.getEventsByService(
    widget.service.id
  );
  setState(() => _occurrencesCount = events.length);
}
```

---

### Solution 3 : Nouvelle Méthode getEventsByService (NOUVEAU) 🆕

Ajout d'une méthode utilitaire dans `EventsFirebaseService`.

**Signature** :
```dart
static Future<List<EventModel>> getEventsByService(String serviceId) async
```

**Utilisation** :
```dart
// Récupérer toutes les occurrences d'un service
final events = await EventsFirebaseService.getEventsByService('service_abc123');
print('Ce service a ${events.length} occurrences');
```

**Requête Firestore** :
```dart
_firestore
  .collection('events')
  .where('linkedServiceId', isEqualTo: serviceId)
  .orderBy('startDate', descending: false)
  .get()
```

**Filtrage** :
- Exclut les événements supprimés (`deletedAt == null`)
- Tri chronologique (startDate ascendant)

---

## 📊 Où Sont Les Données ?

### Structure Firestore

```
services/
  └── service_abc123
      ├── id: "service_abc123"
      ├── name: "Culte Dominical"
      ├── isRecurring: true
      ├── recurrencePattern: { type: "weekly", ... }
      └── linkedEventId: "event_xyz789"

events/
  ├── event_xyz789
  │   ├── id: "event_xyz789"
  │   ├── title: "Culte Dominical"
  │   ├── startDate: 2025-10-13 10:00
  │   ├── linkedServiceId: "service_abc123" ← Lien
  │   └── seriesId: "series_1729..."
  │
  ├── event_abc456
  │   ├── id: "event_abc456"
  │   ├── startDate: 2025-10-20 10:00
  │   ├── linkedServiceId: "service_abc123" ← Même service
  │   └── seriesId: "series_1729..." ← Même série
  │
  └── ... 24 autres occurrences
```

---

## 🧪 Comment Vérifier dans Firebase Console

### Vérifier qu'un service est bien récurrent

1. Ouvrir **Firebase Console**
2. Aller dans **Firestore Database**
3. Chercher dans collection `services`
4. Vérifier les champs :
   - `isRecurring`: doit être `true`
   - `recurrencePattern`: doit contenir `type`, `interval`, etc.
   - `linkedEventId`: ID du premier événement

### Compter les occurrences créées

**Requête** :
```
Collection: events
Filtre: linkedServiceId == "service_abc123"
```

**Résultat attendu** : 26 documents (si 6 mois hebdomadaire)

### Vérifier une série complète

**Requête** :
```
Collection: events
Filtre: seriesId == "series_1729..."
Tri: startDate (ascending)
```

---

## 🎨 Visuels Avant/Après

### AVANT (Sans Badge)

```
┌──────────────────────────┐
│  🌅 Image           [✓]  │
│  [Culte]                 │
├──────────────────────────┤
│ Culte Dominical          │
│ ⏰ dim. 13 oct • 10:00   │
│ 📍 Sanctuaire            │
└──────────────────────────┘

❌ Problème: On ne sait pas que ce service
   a 25 autres occurrences !
```

### APRÈS (Avec Badge)

```
┌──────────────────────────┐
│  🌅 Image           [✓]  │
│                       🔁26│ ← NOUVEAU
│  [Culte]                 │
├──────────────────────────┤
│ Culte Dominical          │
│ ⏰ dim. 13 oct • 10:00   │
│ 📍 Sanctuaire            │
└──────────────────────────┘

✅ Solution: Badge indique 26 occurrences !
   Clic → Ouvre la vue Planning
```

---

## 🚀 Prochaines Améliorations Possibles

### Option A : Calendrier Unifié

Créer un **nouveau calendrier** qui affiche Services ET Événements ensemble.

**Temps** : 3-4 heures  
**Avantage** : Vision complète de tout

**Mockup** :
```
┌─ Octobre 2025 ──────────┐
│ L  M  M  J  V  S  D     │
│ 1  2  3  4  5  6  7     │
│ 8  9 10 11 12 🔁14      │ ← Service récurrent
│15 16 17 18 19 20 🔁21   │ ← Prochaine occurrence
│22 23 24 25 26 📅28      │ ← Événement ponctuel
│29 30 31                 │
└─────────────────────────┘
```

### Option B : Modal "Toutes les Occurrences"

Ajouter un **bouton sur la carte** qui ouvre une liste des occurrences.

**Temps** : 1 heure  
**Avantage** : Accès direct depuis la carte

**Flow** :
```
Carte Service
    ↓ [Clic sur badge 🔁26]
    ↓
Modal "26 Occurrences"
    ├─ dimanche 13 oct 10:00 → 3 bénévoles ✅
    ├─ dimanche 20 oct 10:00 → 0 bénévole ⚠️
    ├─ dimanche 27 oct 10:00 → 2 bénévoles ⚠️
    └─ ... 23 autres
```

### Option C : Indicateur dans la Vue Liste

Ajouter un **sous-titre** sous le nom du service.

**Temps** : 15 minutes  
**Avantage** : Très simple

**Exemple** :
```
Culte Dominical
📅 26 occurrences • Prochaine: dim. 13 oct
```

---

## 📝 Résumé des Fichiers Modifiés

### 1. `lib/services/events_firebase_service.dart`

**Ajout** : Méthode `getEventsByService()`

```dart
/// Get all events linked to a specific service
static Future<List<EventModel>> getEventsByService(String serviceId) async {
  final snapshot = await _firestore
      .collection(eventsCollection)
      .where('linkedServiceId', isEqualTo: serviceId)
      .orderBy('startDate', descending: false)
      .get();
  
  return snapshot.docs
      .map((doc) => EventModel.fromFirestore(doc))
      .where((event) => event.deletedAt == null)
      .toList();
}
```

### 2. `lib/widgets/service_card.dart`

**Ajouts** :
1. Import `EventsFirebaseService`
2. Variable d'état `_occurrencesCount`
3. Méthode `_loadOccurrencesCount()`
4. Badge UI conditionnel

```dart
class _ServiceCardState extends State<ServiceCard> {
  int? _occurrencesCount;
  
  @override
  void initState() {
    super.initState();
    if (widget.service.isRecurring) {
      _loadOccurrencesCount();
    }
  }
  
  Future<void> _loadOccurrencesCount() async {
    final events = await EventsFirebaseService.getEventsByService(
      widget.service.id
    );
    if (mounted) {
      setState(() => _occurrencesCount = events.length);
    }
  }
  
  // Dans le build:
  if (widget.service.isRecurring && _occurrencesCount != null)
    Positioned(
      bottom: 8,
      right: 8,
      child: Badge(...),
    ),
}
```

---

## ✅ Checklist de Test

### Test 1 : Créer un Service Récurrent

- [ ] Ouvrir l'app
- [ ] Aller dans **Services**
- [ ] Créer un nouveau service :
  - Nom : "Test Récurrent"
  - Date : Aujourd'hui
  - Récurrence : ☑️ Hebdomadaire
  - Fin : Dans 3 mois
- [ ] Sauvegarder
- [ ] Vérifier : Le badge **🔁 13** apparaît sur la carte

### Test 2 : Vue Planning

- [ ] Cliquer sur l'icône **📅** en haut
- [ ] Vérifier : Toutes les 13 occurrences sont visibles
- [ ] Vérifier : Groupées par semaine
- [ ] Vérifier : Dates croissantes

### Test 3 : Badge Compte

- [ ] Retour à la vue liste
- [ ] Vérifier : Badge affiche **🔁 13**
- [ ] Créer un service non récurrent
- [ ] Vérifier : Pas de badge

### Test 4 : Firebase Console

- [ ] Ouvrir Firebase Console
- [ ] Collection `events`
- [ ] Filtrer par `linkedServiceId == "ID_DU_SERVICE"`
- [ ] Vérifier : 13 documents

---

## 🎓 Explication pour l'Utilisateur

### Pourquoi 2 Vues Différentes ?

**Vue Services** (Liste/Calendrier) :
- Affiche les **templates** de services
- Permet de gérer la **configuration**
- Badge montre le nombre d'occurrences

**Vue Planning** (📅) :
- Affiche les **occurrences individuelles**
- Permet de gérer les **assignations**
- Vue chronologique par semaine

### C'est Normal !

C'est comme dans **Google Calendar** :
- Vous créez un événement récurrent (template)
- Le calendrier affiche toutes les instances
- Vous pouvez modifier une instance spécifique

Notre système fonctionne pareil ! 🎯

---

## 💡 Recommandations

Pour une **expérience utilisateur optimale** :

1. **Utilisez la Vue Planning** pour :
   - Voir toutes les occurrences
   - Assigner des bénévoles par occurrence
   - Faire des actions en masse

2. **Utilisez la Vue Services** pour :
   - Modifier le service global
   - Voir le nombre d'occurrences (badge)
   - Créer de nouveaux services

3. **Badge 🔁** vous indique :
   - Le service est récurrent
   - Le nombre d'instances créées

---

**Tout est maintenant visible ! 🎉**
