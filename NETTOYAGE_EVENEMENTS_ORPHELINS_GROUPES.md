# 🧹 Nettoyage des Événements Orphelins de Groupes

## 📋 Problème Identifié

Lorsqu'un groupe est supprimé, certains événements et meetings liés peuvent rester "orphelins" dans la base de données, c'est-à-dire liés à un groupe qui n'existe plus.

### Causes

1. **Suppression incomplète** : L'ancienne méthode `deleteGroupWithEvents()` ne supprimait que les événements avec `linkedEventSeriesId`, pas TOUS les événements avec `linkedGroupId`
2. **Suppressions directes** : Groupes supprimés via des chemins qui ne passent pas par le service d'intégration
3. **Erreurs de batch** : Échecs partiels lors de suppressions en batch

## ✅ Solutions Implémentées

### 1. Correction du Service de Suppression

**Fichier** : `lib/services/group_event_integration_service.dart`

#### Avant ❌
```dart
Future<void> deleteGroupWithEvents({...}) async {
  // Supprimait uniquement les événements avec linkedEventSeriesId
  if (group.linkedEventSeriesId != null) {
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('seriesId', isEqualTo: group.linkedEventSeriesId)
        .where('linkedGroupId', isEqualTo: groupId)
        .get();
    // ...
  }
}
```

**Problème** : Si un groupe avait des événements avec `linkedGroupId` mais sans `linkedEventSeriesId`, ces événements n'étaient PAS supprimés.

#### Après ✅
```dart
Future<void> deleteGroupWithEvents({...}) async {
  // Supprime TOUS les événements liés au groupe
  final eventsSnapshot = await _firestore
      .collection('events')
      .where('linkedGroupId', isEqualTo: groupId)
      .get();

  // Utilise plusieurs batches si > 500 opérations
  final batches = <WriteBatch>[];
  var currentBatch = _firestore.batch();
  var operationCount = 0;

  for (final eventDoc in eventsSnapshot.docs) {
    currentBatch.delete(eventDoc.reference);
    operationCount++;
    
    if (operationCount >= 500) {
      batches.add(currentBatch);
      currentBatch = _firestore.batch();
      operationCount = 0;
    }
  }

  // Supprime aussi meetings et membres
  // ...
}
```

**Améliorations** :
- ✅ Supprime TOUS les événements avec `linkedGroupId` (pas seulement ceux de la série)
- ✅ Supprime les meetings via `group_meetings` (pas subcollection)
- ✅ Supprime les membres du groupe
- ✅ Gère les grosses suppressions avec plusieurs batches (limite 500 ops/batch)
- ✅ Logs détaillés pour debugging

---

### 2. Service de Nettoyage Global

**Fichier** : `lib/services/group_cleanup_service.dart`

Service dédié pour détecter et nettoyer les orphelins.

#### Méthodes Principales

##### `cleanupOrphanedGroupContent({bool dryRun})`
Nettoie tous les événements et meetings orphelins.

```dart
// Mode analyse (sans suppression)
final result = await GroupCleanupService.cleanupOrphanedGroupContent(
  dryRun: true,
);

// Mode suppression
final result = await GroupCleanupService.cleanupOrphanedGroupContent(
  dryRun: false,
);

print('${result.eventsDeleted} événements supprimés');
print('${result.meetingsDeleted} meetings supprimés');
```

##### `getOrphanStats()`
Récupère les statistiques sans supprimer.

```dart
final stats = await GroupCleanupService.getOrphanStats();

print('Événements orphelins: ${stats.orphanEvents}');
print('Meetings orphelins: ${stats.orphanMeetings}');
print('Total: ${stats.totalOrphans}');
```

##### `cleanupGroupEvents(String groupId)`
Nettoie les événements d'un groupe spécifique.

```dart
final count = await GroupCleanupService.cleanupGroupEvents(groupId);
print('$count événements supprimés pour ce groupe');
```

#### Classes de Résultat

##### `CleanupResult`
```dart
class CleanupResult {
  int eventsDeleted;
  int meetingsDeleted;
  Map<String?, int> eventsBySeries;
  List<OrphanEventInfo> orphanEvents;
  
  int get totalDeleted => eventsDeleted + meetingsDeleted;
}
```

##### `CleanupStats`
```dart
class CleanupStats {
  int totalEventsWithGroup;
  int validEvents;
  int orphanEvents;
  
  int totalMeetings;
  int validMeetings;
  int orphanMeetings;
  
  bool get hasOrphans => orphanEvents > 0 || orphanMeetings > 0;
  int get totalOrphans => orphanEvents + orphanMeetings;
}
```

---

### 3. Page d'Administration

**Fichier** : `lib/pages/group_cleanup_admin_page.dart`

Interface utilisateur pour gérer le nettoyage.

#### Fonctionnalités

1. **Statistiques en temps réel**
   - Nombre d'événements orphelins
   - Nombre de meetings orphelins
   - Total et pourcentages
   - Indicateurs visuels (rouge/vert)

2. **Actions disponibles**
   - 🔍 **Analyser** : Mode dry-run qui liste sans supprimer
   - 🗑️ **Supprimer** : Suppression définitive avec confirmation
   - 🔄 **Actualiser** : Recharger les statistiques

3. **Affichage des résultats**
   - Détails du dernier nettoyage
   - Liste des événements orphelins trouvés
   - Répartition par série

#### Captures d'écran (layout)

```
┌────────────────────────────────────────┐
│  Nettoyage Groupes           [refresh] │
├────────────────────────────────────────┤
│                                        │
│  ⚠️  Éléments orphelins détectés       │
│  Des événements/meetings sont liés     │
│  à des groupes supprimés               │
│                                        │
│  ┌─────────────┐  ┌─────────────┐    │
│  │ Événements  │  │  Meetings   │    │
│  │     12      │  │      5      │    │
│  │ sur 150     │  │  sur 80     │    │
│  │ ▓▓▓▓░░░░░  │  │ ▓▓▓░░░░░░  │    │
│  └─────────────┘  └─────────────┘    │
│                                        │
│  🗑️ Total: 17 éléments orphelins      │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │     🔍 Analyser (Dry Run)       │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  🗑️ Supprimer les orphelins     │ │
│  └──────────────────────────────────┘ │
│  ⚠️ La suppression est irréversible   │
│                                        │
└────────────────────────────────────────┘
```

#### Navigation

Pour accéder à la page :

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const GroupCleanupAdminPage(),
  ),
);
```

---

### 4. Script Autonome (Optionnel)

**Fichier** : `scripts/cleanup_orphan_group_events.dart`

Script autonome pour exécution hors application.

#### Usage

```dart
final cleanup = OrphanGroupEventsCleanup();

// Mode analyse
await cleanup.dryRun();

// Mode suppression
await cleanup.run();
```

#### Fonctionnalités

- ✅ Détection des événements orphelins
- ✅ Détection des meetings orphelins
- ✅ Regroupement par série
- ✅ Logs détaillés
- ✅ Gestion des gros volumes (batches de 500)

---

## 🔧 Intégration dans le Workflow

### À la Suppression d'un Groupe

Le service d'intégration est automatiquement appelé :

```dart
// Dans GroupsFirebaseService.deleteGroup()
if (group != null && group.generateEvents) {
  await _integrationService.deleteGroupWithEvents(
    groupId: groupId,
    userId: userId,
  );
}
```

### Nettoyage Périodique Recommandé

Il est recommandé d'effectuer un nettoyage périodique :

1. **Manuel** : Via la page d'administration
2. **Automatique** : Tâche cron ou Cloud Function

```dart
// Cloud Function Firebase (exemple)
exports.cleanupOrphans = functions.pubsub
  .schedule('every sunday 03:00')
  .onRun(async (context) => {
    // Appeler cleanupOrphanedGroupContent()
  });
```

---

## 📊 Requêtes Firestore Utilisées

### Événements Orphelins

```dart
// Tous les événements liés à des groupes
final events = await _firestore
    .collection('events')
    .where('linkedGroupId', isNotEqualTo: null)
    .get();

// Pour chaque événement, vérifier si le groupe existe
for (final eventDoc in events.docs) {
  final linkedGroupId = eventDoc.data()['linkedGroupId'];
  final groupDoc = await _firestore
      .collection('groups')
      .doc(linkedGroupId)
      .get();
  
  if (!groupDoc.exists) {
    // Événement orphelin
  }
}
```

### Meetings Orphelins

```dart
// Tous les meetings
final meetings = await _firestore
    .collection('group_meetings')
    .get();

// Vérifier l'existence du groupe pour chaque meeting
for (final meetingDoc in meetings.docs) {
  final groupId = meetingDoc.data()['groupId'];
  final groupDoc = await _firestore
      .collection('groups')
      .doc(groupId)
      .get();
  
  if (!groupDoc.exists) {
    // Meeting orphelin
  }
}
```

---

## ⚠️ Considérations Importantes

### Performance

- **Nombre de lectures** : O(n) où n = nombre d'événements/meetings avec groupe
- **Optimisation** : Utiliser des batches pour les suppressions (max 500/batch)
- **Coût Firebase** : Attention aux lectures pour gros volumes

### Sécurité

- ✅ Confirmation obligatoire avant suppression
- ✅ Mode dry-run pour prévisualisation
- ✅ Logs détaillés de toutes les opérations
- ✅ Pas de suppression accidentelle (double confirmation)

### Cas Particuliers

1. **Événements de séries** : Supprimés avec leur série
2. **Événements individuels** : Supprimés individuellement
3. **Meetings sans événement lié** : Supprimés si groupe inexistant
4. **Inscriptions aux événements** : À gérer séparément si nécessaire

---

## 🧪 Tests

### Test Manuel

1. Créer un groupe avec événements
2. Supprimer le groupe via interface
3. Vérifier que tous les événements sont supprimés
4. Vérifier qu'aucun orphelin n'apparaît dans les stats

### Test de Nettoyage

1. Créer manuellement des orphelins (supprimer groupe en base)
2. Ouvrir la page d'administration
3. Vérifier que les orphelins sont détectés
4. Lancer l'analyse (dry run)
5. Confirmer les statistiques
6. Lancer la suppression
7. Vérifier que les stats = 0

### Commandes de Test

```dart
// Dans un test widget
testWidgets('Cleanup page shows orphans', (tester) async {
  // Setup: Créer orphelins en base
  
  await tester.pumpWidget(const GroupCleanupAdminPage());
  await tester.pumpAndSettle();
  
  // Vérifier affichage stats
  expect(find.text('12'), findsOneWidget); // orphan count
  
  // Tester bouton analyse
  await tester.tap(find.text('Analyser (Dry Run)'));
  await tester.pumpAndSettle();
  
  // Vérifier résultat
  expect(find.text('Analyse terminée'), findsOneWidget);
});
```

---

## 📝 Checklist de Déploiement

- [x] Service `group_cleanup_service.dart` créé
- [x] Page admin `group_cleanup_admin_page.dart` créée
- [x] Méthode `deleteGroupWithEvents()` corrigée
- [x] Tests manuels effectués
- [ ] Ajouter route vers page admin dans navigation
- [ ] Tester avec gros volumes (>1000 événements)
- [ ] Configurer Cloud Function pour nettoyage automatique
- [ ] Former les admins à l'utilisation de l'outil
- [ ] Documenter dans guide utilisateur

---

## 🎯 Prochaines Améliorations

1. **Suppression en arrière-plan** : Task queue pour gros volumes
2. **Historique des nettoyages** : Logs en base de données
3. **Notifications** : Alerter admins si orphelins détectés
4. **Export CSV** : Liste des orphelins pour audit
5. **Restauration** : Soft delete avec possibilité de restaurer
6. **Règles de sécurité** : Permissions spécifiques pour cette fonctionnalité

---

## 📞 Support

Pour toute question ou problème :
- Vérifier les logs Console (`flutter: 🧹 ...`)
- Consulter Firebase Console pour état de la base
- Utiliser le mode dry-run avant toute suppression
- Contacter l'équipe de développement si doute

---

**Date de création** : 14 octobre 2025  
**Version** : 1.0  
**Statut** : ✅ Implémenté et testé
