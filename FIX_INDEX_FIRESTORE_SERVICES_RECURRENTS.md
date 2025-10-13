# 🔧 Index Firestore pour Services Récurrents

**Date** : 13 octobre 2025  
**Problème** : `[cloud_firestore/failed-precondition] The query requires an index`  
**Statut** : ✅ **INDEX CRÉÉ ET EN COURS DE BUILD**

---

## 🎯 Problème Rencontré

### Erreur

```
Erreur lors de la récupération des événements du service: 
[cloud_firestore/failed-precondition] The query requires an index.
```

### Cause

La requête dans `EventsFirebaseService.getEventsByService()` utilise :
```dart
_firestore
  .collection('events')
  .where('linkedServiceId', isEqualTo: serviceId)  // ← Filtre 1
  .orderBy('startDate', descending: false)         // ← Tri
  .get()
```

Firestore nécessite un **index composite** pour les requêtes avec :
- 1+ filtres `where()`
- 1+ `orderBy()` sur un champ différent

---

## ✅ Solution Implémentée

### Index Ajouté

**Collection** : `events`  
**Champs** :
1. `linkedServiceId` (ASCENDING)
2. `startDate` (ASCENDING)
3. `__name__` (ASCENDING) - Ajouté automatiquement

### Configuration dans firestore.indexes.json

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "linkedServiceId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    ...
  ]
}
```

---

## 🚀 Déploiement

### Commande Exécutée

```bash
firebase deploy --only firestore:indexes
```

### Résultat

```
✔ firestore: deployed indexes in firestore.indexes.json 
  successfully for (default) database

✔ Deploy complete!
```

---

## ⏱️ Temps de Création

### Estimation

| Nombre de documents | Temps de build |
|---------------------|----------------|
| < 100 documents     | ~30 secondes   |
| 100-1000 documents  | 1-2 minutes    |
| 1000-10000 documents| 3-5 minutes    |
| > 10000 documents   | 5-15 minutes   |

### Vérifier le Statut

**Option 1 : Console Firebase**
1. Ouvrir : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes
2. Chercher l'index `events` avec `linkedServiceId` + `startDate`
3. Statut :
   - 🟡 **Building** : En cours de création
   - 🟢 **Enabled** : Prêt à l'emploi
   - 🔴 **Error** : Erreur (rare)

**Option 2 : Dans l'App**
1. Attendez 2-3 minutes
2. Relancez l'app : `flutter run`
3. Ouvrez Services
4. Cliquez sur badge 🔁 d'un service récurrent
5. Si le modal s'ouvre → Index OK ✅
6. Si erreur persiste → Attendez encore 1-2 minutes

---

## 🧪 Tests Post-Déploiement

### Test 1 : Badge Occurrences

**Étapes** :
1. Ouvrir Services
2. Trouver un service récurrent
3. Observer le badge 🔁 X

**Résultat attendu** :
- ✅ Badge affiche le nombre d'occurrences
- ✅ Pas d'erreur dans les logs

### Test 2 : Modal Occurrences

**Étapes** :
1. Cliquer sur le badge 🔁 X
2. Observer le modal

**Résultat attendu** :
- ✅ Modal s'ouvre
- ✅ Stats affichées (Total, Complets, Incomplets)
- ✅ Liste des occurrences visible
- ✅ Dates formatées correctement

### Test 3 : Vue Planning

**Étapes** :
1. Cliquer sur icône 📅 (view_week)
2. Observer la vue Planning

**Résultat attendu** :
- ✅ Occurrences groupées par semaine
- ✅ Toutes les occurrences visibles
- ✅ Pas d'erreur

---

## 📊 Requêtes Utilisant cet Index

### 1. getEventsByService()

**Fichier** : `lib/services/events_firebase_service.dart`

```dart
static Future<List<EventModel>> getEventsByService(String serviceId) async {
  final snapshot = await _firestore
      .collection('events')
      .where('linkedServiceId', isEqualTo: serviceId)  // ← Index requis
      .orderBy('startDate', descending: false)          // ← Index requis
      .get();
  
  return snapshot.docs
      .map((doc) => EventModel.fromFirestore(doc))
      .where((event) => event.deletedAt == null)
      .toList();
}
```

**Utilisé par** :
- `ServiceCard._loadOccurrencesCount()` - Badge 🔁
- `ServiceOccurrencesDialog._loadOccurrences()` - Modal

### 2. ServicesPlanningView

**Fichier** : `lib/modules/services/views/services_planning_view.dart`

```dart
StreamBuilder<List<EventModel>>(
  stream: EventsFirebaseService.getEventsStream(
    startDate: _startDate,
    endDate: _endDate,
  ),
  builder: (context, snapshot) {
    final serviceEvents = allEvents.where((event) {
      return event.linkedServiceId != null;  // ← Filtre client-side
    }).toList();
    ...
  },
)
```

**Note** : Cette requête utilise des index différents (`startDate` range), mais bénéficie aussi de l'index composite.

---

## 🔍 Autres Index Potentiellement Nécessaires

### Index Supplémentaires Recommandés

#### 1. events + seriesId + startDate

**Utilité** : Récupérer toutes les occurrences d'une série récurrente

```json
{
  "collectionGroup": "events",
  "fields": [
    {"fieldPath": "seriesId", "order": "ASCENDING"},
    {"fieldPath": "startDate", "order": "ASCENDING"}
  ]
}
```

**Utilisé par** : `EventSeriesService.getSeriesEvents()`

#### 2. events + status + linkedServiceId + startDate

**Utilité** : Filtrer occurrences par statut ET service

```json
{
  "collectionGroup": "events",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "linkedServiceId", "order": "ASCENDING"},
    {"fieldPath": "startDate", "order": "ASCENDING"}
  ]
}
```

**Utilisé par** : Futures fonctionnalités de filtrage

---

## 💡 Bonnes Pratiques Index Firestore

### 1. Index Composite vs Simple

**Index Simple** (automatique) :
- 1 champ only
- Pas de `orderBy()` ou `orderBy()` sur le même champ

**Index Composite** (manuel requis) :
- 2+ champs
- `where()` + `orderBy()` sur champs différents

### 2. Ordre des Champs

Ordre recommandé dans l'index :
1. **Champs d'égalité** (`where('field', isEqualTo: value)`)
2. **Champs de tri** (`orderBy('field')`)
3. **__name__** (automatique)

**Exemple** :
```
linkedServiceId (égalité) → startDate (tri) → __name__
```

### 3. Coût des Index

- **Writes** : Chaque write met à jour tous les index
- **Storage** : Chaque index utilise du stockage
- **Performance** : Plus d'index = reads plus rapides

**Recommandation** : Créer index seulement quand nécessaire.

---

## 📝 Historique

### 13 octobre 2025

**Actions** :
1. ✅ Erreur détectée lors du test badge 🔁
2. ✅ Index ajouté dans `firestore.indexes.json`
3. ✅ Déployé avec `firebase deploy --only firestore:indexes`
4. ⏳ En attente de la fin du build (~2-3 minutes)

**Status** : 🟡 Building

---

## 🎯 Prochaines Étapes

### Immédiat (Après build index)

1. **Attendre 2-3 minutes**
2. **Tester le badge** :
   ```
   flutter run
   → Ouvrir Services
   → Cliquer badge 🔁
   → Vérifier modal s'ouvre
   ```
3. **Confirmer succès** ✅

### Si l'index ne fonctionne pas

**Vérifications** :
1. Console Firebase → Index status = "Enabled"
2. Logs Firestore : Pas d'erreur
3. Code : Requête correspond à l'index

**Solutions** :
1. Attendre quelques minutes supplémentaires
2. Recréer l'index via console Firebase
3. Vérifier permissions Firestore Rules

---

## 🔗 Liens Utiles

- **Console Firestore Indexes** : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes
- **Documentation Indexes** : https://firebase.google.com/docs/firestore/query-data/indexing
- **Exemples Indexes** : https://firebase.google.com/docs/firestore/query-data/index-overview

---

**L'index sera prêt dans 2-3 minutes ! ⏱️**

Ensuite, le badge 🔁 et le modal fonctionneront parfaitement ! 🎉
