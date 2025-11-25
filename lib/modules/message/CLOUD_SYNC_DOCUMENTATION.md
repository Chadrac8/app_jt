# Synchronisation Cloud - Module Search

## Vue d'ensemble

Le module Search dispose d'une synchronisation cloud complète pour les notes et surlignements des sermons William Branham. Cette fonctionnalité permet aux utilisateurs de :

- ✅ Sauvegarder automatiquement leurs notes et surlignements dans Firestore
- ✅ Synchroniser leurs données entre plusieurs appareils
- ✅ Travailler en mode offline avec synchronisation automatique lors de la reconnexion
- ✅ Résoudre automatiquement les conflits (la version la plus récente gagne)
- ✅ Exporter/importer leurs données en JSON

## Architecture

### 1. Service Cloud (`NotesHighlightsCloudService`)

**Collections Firestore :**
```
wb_sermon_notes/
  {noteId}/
    id: string
    sermonId: string
    title: string
    content: string
    pageNumber: int?
    referenceText: string?
    tags: array
    createdAt: timestamp
    updatedAt: timestamp?
    userId: string (ajouté automatiquement)
    syncedAt: timestamp (ajouté automatiquement)

wb_sermon_highlights/
  {highlightId}/
    id: string
    sermonId: string
    text: string
    color: string?
    startPosition: int?
    endPosition: int?
    pageNumber: int?
    createdAt: timestamp
    updatedAt: timestamp?
    userId: string (ajouté automatiquement)
    syncedAt: timestamp (ajouté automatiquement)
```

**Méthodes principales :**

#### Upload
```dart
// Upload une note
await NotesHighlightsCloudService.uploadNote(note);

// Upload plusieurs notes en batch
await NotesHighlightsCloudService.uploadNotes(notesList);

// Upload un surlignement
await NotesHighlightsCloudService.uploadHighlight(highlight);

// Upload plusieurs surlignements
await NotesHighlightsCloudService.uploadHighlights(highlightsList);
```

#### Download
```dart
// Télécharger toutes les notes
List<SermonNote> notes = await NotesHighlightsCloudService.downloadNotes();

// Télécharger tous les surlignements
List<SermonHighlight> highlights = await NotesHighlightsCloudService.downloadHighlights();
```

#### Synchronisation
```dart
// Sync vers le cloud (upload local → cloud)
await NotesHighlightsCloudService.syncToCloud(
  localNotes: notes,
  localHighlights: highlights,
);

// Sync depuis le cloud (download cloud → local)
final data = await NotesHighlightsCloudService.syncFromCloud();
// data.notes et data.highlights contiennent les données

// Sync bidirectionnelle avec fusion intelligente
final merged = await NotesHighlightsCloudService.syncBidirectional(
  localNotes: localNotes,
  localHighlights: localHighlights,
);
// merged.notes et merged.highlights contiennent les données fusionnées
```

#### Streams temps réel
```dart
// Écouter les notes en temps réel
Stream<List<SermonNote>> notesStream = NotesHighlightsCloudService.streamNotes();

// Écouter les surlignements en temps réel
Stream<List<SermonHighlight>> highlightsStream = NotesHighlightsCloudService.streamHighlights();
```

### 2. Provider (`NotesHighlightsProvider`)

Le provider intègre la synchronisation cloud de manière transparente :

**Propriétés de synchronisation :**
```dart
bool isSyncing;              // Synchronisation en cours
DateTime? lastSyncTime;       // Heure de la dernière sync
String? syncError;            // Dernière erreur de sync
bool autoSyncEnabled;         // Auto-sync activé/désactivé
bool isCloudAvailable;        // Utilisateur connecté
```

**Synchronisation automatique :**
- Lors de la sauvegarde d'une note → upload automatique si `autoSyncEnabled`
- Lors de la sauvegarde d'un surlignement → upload automatique si `autoSyncEnabled`
- Lors de la connexion de l'utilisateur → sync automatique depuis le cloud
- Lors de la suppression → suppression cloud automatique

**Méthodes publiques :**
```dart
// Activer/désactiver la synchronisation automatique
provider.setAutoSync(true/false);

// Synchroniser vers le cloud
await provider.syncToCloud();

// Synchroniser depuis le cloud
await provider.syncFromCloud();

// Synchronisation bidirectionnelle (recommandé)
await provider.syncBidirectional();

// Obtenir les statistiques
Map<String, dynamic> stats = await provider.getSyncStats();

// Supprimer toutes les données cloud
await provider.clearCloudData();
```

### 3. Interface utilisateur

**Indicateur de synchronisation dans l'AppBar :**
- 🔄 Animation circulaire : Synchronisation en cours
- ☁️ Icône grise : Non connecté
- ✅ Icône verte : Synchronisé récemment (< 1h)
- 🟠 Icône orange : Synchronisé il y a longtemps (> 1h)
- ☁️ Icône bleue : Jamais synchronisé

**Menu Actions :**
- **Synchroniser maintenant** : Lance une sync bidirectionnelle manuelle
- **Statistiques cloud** : Affiche le nombre de notes/highlights dans le cloud vs local
- **Exporter mes données** : Export JSON local
- **Importer des données** : Import JSON local
- **Vider le cache** : Supprime les données locales

**Dialog d'information de sync :**
Cliquer sur l'icône cloud affiche :
- État de connexion
- Heure de dernière synchronisation
- État de l'auto-sync
- Erreurs éventuelles
- Boutons : Synchroniser, Activer/Désactiver auto-sync

## Gestion des conflits

La stratégie de résolution de conflits est **"Last Write Wins"** (la plus récente gagne) :

1. **Lors de la sync bidirectionnelle :**
   - Télécharger les données cloud
   - Pour chaque élément (note/highlight) :
     - Si l'ID existe localement et dans le cloud :
       - Comparer `updatedAt` (ou `createdAt` si pas de `updatedAt`)
       - Conserver la version la plus récente
     - Si l'ID n'existe que localement : conserver
     - Si l'ID n'existe que dans le cloud : conserver
   - Uploader les données fusionnées vers le cloud
   - Sauvegarder localement

2. **Exemple de fusion :**
```dart
// Note locale créée le 1er janvier à 10h, modifiée le 2 janvier à 14h
// Note cloud créée le 1er janvier à 10h, modifiée le 2 janvier à 16h
// → Version cloud gardée (plus récente : 16h > 14h)
```

## Mode Offline

Le module fonctionne **offline-first** :

### Comportement offline
1. Toutes les opérations CRUD fonctionnent localement (SharedPreferences)
2. Les tentatives de sync cloud échouent silencieusement (pas de blocage)
3. L'indicateur cloud affiche "Non connecté"
4. Les données locales sont préservées

### Reconnexion
1. Détection automatique via `FirebaseAuth.authStateChanges()`
2. Si `autoSyncEnabled`, lancement automatique de `syncFromCloud()`
3. Fusion des données locales (créées offline) avec les données cloud
4. Mise à jour de l'interface

### Stratégie recommandée
```dart
// Au lancement de l'app (si utilisateur connecté)
await provider.syncBidirectional(); // Fusion intelligente

// Pendant l'utilisation
// → Auto-sync activé : sauvegarde automatique vers cloud
// → Auto-sync désactivé : sauvegardes uniquement locales

// Lors du passage offline → online
// → Auto-sync détecte la reconnexion et synchronise automatiquement
```

## Règles de sécurité Firestore

**À ajouter dans `firestore.rules` :**

```javascript
// Rules pour wb_sermon_notes
match /wb_sermon_notes/{noteId} {
  // Lecture : uniquement ses propres notes
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  
  // Création : utilisateur authentifié, avec son userId
  allow create: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
  
  // Modification/Suppression : uniquement ses propres notes
  allow update, delete: if request.auth != null && 
                         resource.data.userId == request.auth.uid;
}

// Rules pour wb_sermon_highlights
match /wb_sermon_highlights/{highlightId} {
  // Lecture : uniquement ses propres surlignements
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  
  // Création : utilisateur authentifié, avec son userId
  allow create: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
  
  // Modification/Suppression : uniquement ses propres surlignements
  allow update, delete: if request.auth != null && 
                         resource.data.userId == request.auth.uid;
}
```

## Index Firestore recommandés

**À ajouter dans `firestore.indexes.json` :**

```json
{
  "indexes": [
    {
      "collectionGroup": "wb_sermon_notes",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "wb_sermon_notes",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "sermonId", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "wb_sermon_highlights",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "wb_sermon_highlights",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "sermonId", "order": "ASCENDING"}
      ]
    }
  ]
}
```

## Utilisation avancée

### Synchronisation sélective

```dart
// Synchroniser uniquement les notes d'un sermon spécifique
final notesToSync = provider.allNotes
    .where((note) => note.sermonId == 'sermon-123')
    .toList();

await NotesHighlightsCloudService.uploadNotes(notesToSync);
```

### Écouter les changements en temps réel

```dart
// Dans un StatefulWidget
StreamSubscription? _notesSubscription;

@override
void initState() {
  super.initState();
  
  if (NotesHighlightsCloudService.isAuthenticated) {
    _notesSubscription = NotesHighlightsCloudService.streamNotes()
        .listen((cloudNotes) {
      // Mettre à jour l'interface avec les nouvelles données
      setState(() {
        // Fusionner avec les notes locales si nécessaire
      });
    });
  }
}

@override
void dispose() {
  _notesSubscription?.cancel();
  super.dispose();
}
```

### Statistiques détaillées

```dart
final stats = await provider.getSyncStats();

print('Utilisateur connecté: ${stats['authenticated']}');
print('User ID: ${stats['userId']}');
print('Notes cloud: ${stats['notesCount']}');
print('Highlights cloud: ${stats['highlightsCount']}');
```

## Tests recommandés

### 1. Test de synchronisation basique
1. ✅ Créer une note sur l'appareil A
2. ✅ Vérifier qu'elle apparaît dans Firestore
3. ✅ Synchroniser sur l'appareil B
4. ✅ Vérifier que la note apparaît sur B

### 2. Test de résolution de conflits
1. ✅ Créer une note identique sur A et B (offline)
2. ✅ Modifier la note sur A à 10h
3. ✅ Modifier la note sur B à 11h
4. ✅ Synchroniser A puis B
5. ✅ Vérifier que la version de 11h (B) est conservée

### 3. Test mode offline
1. ✅ Désactiver la connexion internet
2. ✅ Créer plusieurs notes/highlights
3. ✅ Vérifier qu'elles sont sauvegardées localement
4. ✅ Réactiver la connexion
5. ✅ Vérifier la synchronisation automatique

### 4. Test de performance
1. ✅ Créer 100 notes
2. ✅ Mesurer le temps de sync vers cloud
3. ✅ Mesurer le temps de sync depuis cloud
4. ✅ Vérifier l'utilisation mémoire

### 5. Test multi-utilisateurs
1. ✅ Se connecter avec utilisateur A
2. ✅ Créer des notes
3. ✅ Se déconnecter et connecter avec utilisateur B
4. ✅ Vérifier qu'il ne voit pas les notes de A
5. ✅ Créer des notes pour B
6. ✅ Vérifier l'isolation des données

## Bonnes pratiques

### DO ✅
- Utiliser `syncBidirectional()` pour la synchronisation manuelle
- Activer `autoSyncEnabled` pour une expérience utilisateur fluide
- Gérer les erreurs de sync avec try-catch
- Afficher l'état de synchronisation à l'utilisateur
- Tester en conditions réelles (offline → online)

### DON'T ❌
- Ne pas appeler `syncToCloud()` puis `syncFromCloud()` séparément (utiliser `syncBidirectional()`)
- Ne pas synchroniser trop fréquemment (coût Firestore)
- Ne pas bloquer l'interface pendant la sync (utiliser des indicateurs visuels)
- Ne pas oublier les règles de sécurité Firestore
- Ne pas supposer que l'utilisateur est toujours connecté

## Limites et considérations

### Limites Firestore
- **Lectures** : 50,000 par jour (gratuit), puis $0.06 / 100,000
- **Écritures** : 20,000 par jour (gratuit), puis $0.18 / 100,000
- **Taille document** : 1 MB maximum
- **Taille batch** : 500 opérations maximum

### Optimisations possibles
1. **Sync incrémentale** : Ne synchroniser que les changements depuis la dernière sync
2. **Compression** : Compresser les notes volumineuses avant upload
3. **Pagination** : Charger les notes par lots de 50
4. **Cache intelligent** : Utiliser des timestamps pour invalider le cache

## Dépannage

### "Utilisateur non authentifié"
→ Vérifier que l'utilisateur est connecté avec Firebase Auth

### "Permission denied"
→ Vérifier les règles Firestore et que `userId` est correctement défini

### Synchronisation lente
→ Vérifier la connexion internet, utiliser des batchs pour les uploads massifs

### Données non synchronisées
→ Vérifier `autoSyncEnabled`, forcer une sync manuelle, consulter les logs

### Conflits non résolus
→ La logique "Last Write Wins" devrait toujours résoudre. Vérifier les timestamps

## Support

Pour toute question ou problème :
1. Consulter les logs dans la console Flutter
2. Vérifier la console Firestore pour les erreurs
3. Tester avec `getSyncStats()` pour diagnostiquer
4. Activer les logs debug dans le service cloud

## Changelog

### Version 1.0 (23 novembre 2025)
- ✅ Implémentation initiale de la synchronisation cloud
- ✅ Support offline-first avec SharedPreferences
- ✅ Synchronisation bidirectionnelle avec résolution de conflits
- ✅ Interface utilisateur avec indicateurs de sync
- ✅ Auto-sync configurable
- ✅ Export/Import JSON complémentaire
