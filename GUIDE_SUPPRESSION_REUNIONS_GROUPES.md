# 🗑️ Guide : Comment Supprimer les Réunions des Groupes

## 📋 Table des Matières

1. [Options de Suppression](#options-de-suppression)
2. [Suppression Manuelle (Interface Utilisateur)](#suppression-manuelle-interface-utilisateur)
3. [Suppression Programmatique (Code)](#suppression-programmatique-code)
4. [Suppression en Masse](#suppression-en-masse)
5. [Suppression Automatique lors de la Suppression du Groupe](#suppression-automatique-groupe)
6. [Précautions et Bonnes Pratiques](#précautions-et-bonnes-pratiques)

---

## 🎯 Options de Suppression

Vous avez **4 façons** de supprimer des réunions de groupes :

| Méthode | Usage | Portée |
|---------|-------|--------|
| **1. Suppression Manuelle** | Via l'interface utilisateur | 1 réunion à la fois |
| **2. Suppression Programmatique** | Via appel de service | 1 ou plusieurs réunions |
| **3. Suppression en Masse** | Script ou admin | Toutes les réunions d'un groupe |
| **4. Suppression Automatique** | Lors de la suppression du groupe | Toutes les réunions + événements |

---

## 🖱️ Suppression Manuelle (Interface Utilisateur)

### Méthode 1 : Depuis la Page du Groupe

#### Étapes :
1. **Ouvrir la page du groupe**
   - Admin → Groupes → Cliquer sur un groupe

2. **Aller dans l'onglet "Réunions"**
   - Vous verrez la liste chronologique des réunions

3. **Cliquer sur la réunion à supprimer**
   - Accès à la page de détail de la réunion

4. **Menu "⋮" → "Supprimer la réunion"**
   - Un dialog de confirmation apparaît

5. **Confirmer la suppression**
   - La réunion est supprimée immédiatement

#### Code Impliqué :
```dart
// Dans group_meetings_list.dart (ligne ~520)
Future<void> _deleteMeeting(GroupMeetingModel meeting) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Supprimer la réunion'),
      content: Text('Êtes-vous sûr de vouloir supprimer "${meeting.title}" ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.redStandard,
          ),
          child: Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await GroupsFirebaseService.deleteMeeting(meeting.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réunion supprimée avec succès'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }
}
```

---

### Méthode 2 : Depuis la Page de Détail de la Réunion

#### Étapes :
1. **Ouvrir une réunion spécifique**
   - Depuis la timeline des réunions → Cliquer sur une carte

2. **Utiliser le bouton "Supprimer"**
   - En bas ou dans le menu de la page

3. **Confirmer**

#### Code Impliqué :
```dart
// Dans group_meeting_page.dart
Future<void> _deleteMeeting() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Supprimer cette réunion ?'),
      content: Text('Cette action est irréversible.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.redStandard,
          ),
          child: Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await GroupsFirebaseService.deleteMeeting(widget.meeting.id);
      if (mounted) {
        Navigator.pop(context, true); // Retour avec succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }
}
```

---

## 💻 Suppression Programmatique (Code)

### Service : `GroupsFirebaseService`

Actuellement, le service **ne possède PAS** de méthode `deleteMeeting()` explicite. Vous devez l'ajouter.

### ✅ Ajout de la Méthode de Suppression

**Fichier** : `lib/services/groups_firebase_service.dart`

**Ajouter après la ligne ~360** (après `updateMeeting`) :

```dart
/// Supprime une réunion de groupe
/// 
/// Paramètres:
/// - [meetingId]: ID de la réunion à supprimer
/// 
/// Note: Si la réunion est liée à un événement (linkedEventId),
/// vous pouvez aussi supprimer l'événement correspondant
static Future<void> deleteMeeting(String meetingId) async {
  try {
    final meetingDoc = await _firestore
        .collection(groupMeetingsCollection)
        .doc(meetingId)
        .get();
    
    if (!meetingDoc.exists) {
      throw Exception('Réunion non trouvée: $meetingId');
    }
    
    final meetingData = meetingDoc.data() as Map<String, dynamic>;
    final groupId = meetingData['groupId'] as String;
    
    // Supprimer la réunion
    await _firestore.collection(groupMeetingsCollection).doc(meetingId).delete();
    
    // Log de l'activité
    await _logGroupActivity(groupId, 'meeting_deleted', {
      'meetingId': meetingId,
      'title': meetingData['title'],
    });
    
    print('✅ Réunion supprimée: $meetingId');
  } catch (e) {
    throw Exception('Erreur lors de la suppression de la réunion: $e');
  }
}

/// Supprime une réunion ET son événement lié (si existant)
/// 
/// Paramètres:
/// - [meetingId]: ID de la réunion
/// 
/// Utile pour les réunions générées automatiquement avec événements
static Future<void> deleteMeetingWithEvent(String meetingId) async {
  try {
    final meetingDoc = await _firestore
        .collection(groupMeetingsCollection)
        .doc(meetingId)
        .get();
    
    if (!meetingDoc.exists) {
      throw Exception('Réunion non trouvée: $meetingId');
    }
    
    final meetingData = meetingDoc.data() as Map<String, dynamic>;
    final linkedEventId = meetingData['linkedEventId'] as String?;
    
    final batch = _firestore.batch();
    
    // Supprimer la réunion
    batch.delete(meetingDoc.reference);
    
    // Supprimer l'événement lié s'il existe
    if (linkedEventId != null) {
      final eventRef = _firestore.collection('events').doc(linkedEventId);
      batch.delete(eventRef);
      print('   🔗 Événement lié supprimé: $linkedEventId');
    }
    
    await batch.commit();
    
    print('✅ Réunion (+ événement) supprimée: $meetingId');
  } catch (e) {
    throw Exception('Erreur lors de la suppression: $e');
  }
}
```

### Usage dans votre Code

```dart
// Suppression simple d'une réunion
await GroupsFirebaseService.deleteMeeting('meeting_abc123');

// Suppression réunion + événement lié
await GroupsFirebaseService.deleteMeetingWithEvent('meeting_abc123');
```

---

## 🔥 Suppression en Masse

### Cas d'Usage :
- Supprimer **toutes les réunions** d'un groupe spécifique
- Nettoyage administratif
- Réinitialisation d'un calendrier

### Option 1 : Via Service (Ajouter cette Méthode)

**Fichier** : `lib/services/groups_firebase_service.dart`

```dart
/// Supprime TOUTES les réunions d'un groupe
/// 
/// Paramètres:
/// - [groupId]: ID du groupe
/// - [includeEvents]: Si true, supprime aussi les événements liés
/// 
/// Retourne: Nombre de réunions supprimées
static Future<int> deleteAllGroupMeetings(
  String groupId, {
  bool includeEvents = false,
}) async {
  try {
    print('🗑️ Suppression de toutes les réunions du groupe $groupId');
    
    // Récupérer toutes les réunions du groupe
    final meetingsSnapshot = await _firestore
        .collection(groupMeetingsCollection)
        .where('groupId', isEqualTo: groupId)
        .get();
    
    final meetingCount = meetingsSnapshot.docs.length;
    print('   📊 ${meetingCount} réunions trouvées');
    
    if (meetingCount == 0) {
      print('   ⚠️ Aucune réunion à supprimer');
      return 0;
    }
    
    // Utiliser plusieurs batches si nécessaire (max 500 opérations)
    final batches = <WriteBatch>[];
    var currentBatch = _firestore.batch();
    var operationCount = 0;
    
    for (final meetingDoc in meetingsSnapshot.docs) {
      // Supprimer la réunion
      currentBatch.delete(meetingDoc.reference);
      operationCount++;
      
      // Si includeEvents, supprimer l'événement lié
      if (includeEvents) {
        final meetingData = meetingDoc.data();
        final linkedEventId = meetingData['linkedEventId'] as String?;
        
        if (linkedEventId != null) {
          final eventRef = _firestore.collection('events').doc(linkedEventId);
          currentBatch.delete(eventRef);
          operationCount++;
        }
      }
      
      // Nouveau batch si limite atteinte
      if (operationCount >= 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }
    
    // Ajouter le dernier batch
    if (operationCount > 0) {
      batches.add(currentBatch);
    }
    
    // Commit tous les batches
    print('   💾 Commit de ${batches.length} batch(es)...');
    for (int i = 0; i < batches.length; i++) {
      await batches[i].commit();
      print('      ✅ Batch ${i + 1}/${batches.length} committed');
    }
    
    await _logGroupActivity(groupId, 'all_meetings_deleted', {
      'count': meetingCount,
      'includeEvents': includeEvents,
    });
    
    print('✅ $meetingCount réunions supprimées');
    return meetingCount;
  } catch (e) {
    throw Exception('Erreur lors de la suppression des réunions: $e');
  }
}
```

### Usage

```dart
// Supprimer toutes les réunions (garder les événements)
final count = await GroupsFirebaseService.deleteAllGroupMeetings('group_xyz');
print('$count réunions supprimées');

// Supprimer réunions + événements liés
final count = await GroupsFirebaseService.deleteAllGroupMeetings(
  'group_xyz',
  includeEvents: true,
);
```

---

### Option 2 : Script Standalone

**Fichier** : `scripts/delete_group_meetings.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour supprimer toutes les réunions d'un groupe
/// 
/// Usage:
/// dart scripts/delete_group_meetings.dart <groupId> [--include-events]
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart delete_group_meetings.dart <groupId> [--include-events]');
    return;
  }
  
  final groupId = args[0];
  final includeEvents = args.contains('--include-events');
  
  print('🔥 Suppression réunions du groupe: $groupId');
  if (includeEvents) {
    print('   🔗 Événements liés seront aussi supprimés');
  }
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  // Récupérer les réunions
  final snapshot = await firestore
      .collection('group_meetings')
      .where('groupId', isEqualTo: groupId)
      .get();
  
  print('📊 ${snapshot.docs.length} réunions trouvées');
  
  if (snapshot.docs.isEmpty) {
    print('✅ Aucune réunion à supprimer');
    return;
  }
  
  // Confirmation
  print('⚠️  Cette action est IRRÉVERSIBLE !');
  print('   Tapez "CONFIRMER" pour continuer:');
  final confirmation = stdin.readLineSync();
  
  if (confirmation != 'CONFIRMER') {
    print('❌ Annulé');
    return;
  }
  
  // Suppression
  int deletedCount = 0;
  final batch = firestore.batch();
  
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
    deletedCount++;
    
    if (includeEvents) {
      final data = doc.data();
      final linkedEventId = data['linkedEventId'] as String?;
      if (linkedEventId != null) {
        batch.delete(firestore.collection('events').doc(linkedEventId));
      }
    }
  }
  
  await batch.commit();
  
  print('✅ $deletedCount réunions supprimées avec succès');
}
```

**Exécution** :
```bash
# Supprimer réunions seulement
dart scripts/delete_group_meetings.dart group_xyz

# Supprimer réunions + événements
dart scripts/delete_group_meetings.dart group_xyz --include-events
```

---

## 🔗 Suppression Automatique lors de la Suppression du Groupe

Quand vous supprimez un groupe, **toutes ses réunions sont automatiquement supprimées**.

### Code Existant (Déjà Implémenté) ✅

**Fichier** : `lib/services/group_event_integration_service.dart` (lignes 561-660)

```dart
Future<void> deleteGroupWithEvents({
  required String groupId,
  required String userId,
}) async {
  print('🗑️ Suppression groupe $groupId avec tous ses événements/meetings');
  
  // ... code de récupération du groupe ...
  
  // Supprimer tous les événements liés
  final eventsSnapshot = await _firestore
      .collection('events')
      .where('linkedGroupId', isEqualTo: groupId)
      .get();
  
  // Supprimer meetings (collection group_meetings) ✅
  final meetingsSnapshot = await _firestore
      .collection('group_meetings')
      .where('groupId', isEqualTo: groupId)
      .get();
  
  // Supprimer membres du groupe
  final membersSnapshot = await _firestore
      .collection('group_members')
      .where('groupId', isEqualTo: groupId)
      .get();
  
  // Utilise plusieurs batches (max 500 opérations)
  // ... batch operations ...
  
  print('✅ Groupe supprimé avec:');
  print('   - ${eventsSnapshot.docs.length} événements');
  print('   - ${meetingsSnapshot.docs.length} meetings'); // ← RÉUNIONS SUPPRIMÉES
  print('   - ${membersSnapshot.docs.length} membres');
}
```

### Comment Déclencher

**Interface Utilisateur** :
1. Admin → Groupes → Sélectionner un groupe
2. Menu "⋮" → "Supprimer le groupe"
3. Dialog de confirmation
4. ✅ Groupe + Réunions + Événements + Membres supprimés

**Code** :
```dart
// Via le service principal
await GroupsFirebaseService.deleteGroup('group_xyz');

// Le service appelle automatiquement deleteGroupWithEvents()
// si le groupe a generateEvents = true
```

---

## ⚠️ Précautions et Bonnes Pratiques

### 1. **Vérifier les Dépendances**

Avant de supprimer des réunions, vérifiez :
- ✅ Présences enregistrées (table `group_attendance`)
- ✅ Rapports de réunion (`reportNotes`)
- ✅ Événements liés (`linkedEventId`)

### 2. **Soft Delete (Recommandé)**

Au lieu de supprimer définitivement, marquez comme supprimé :

```dart
static Future<void> softDeleteMeeting(String meetingId) async {
  await _firestore.collection(groupMeetingsCollection).doc(meetingId).update({
    'isDeleted': true,
    'deletedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

**Avantages** :
- Possibilité de restaurer
- Historique conservé
- Présences gardées

### 3. **Logs et Audit**

Toujours logger les suppressions :

```dart
await _logGroupActivity(groupId, 'meeting_deleted', {
  'meetingId': meetingId,
  'title': meeting.title,
  'deletedBy': userId,
  'deletedAt': DateTime.now().toIso8601String(),
});
```

### 4. **Confirmation Utilisateur**

**TOUJOURS** demander confirmation avant suppression :

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Supprimer la réunion ?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cette action est irréversible.'),
        SizedBox(height: 8),
        Text('Informations qui seront perdues:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('• Présences enregistrées'),
        Text('• Rapports de réunion'),
        Text('• Notes et fichiers'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Annuler'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.redStandard,
        ),
        child: Text('Supprimer'),
      ),
    ],
  ),
);
```

### 5. **Backup Avant Suppression Massive**

Si vous supprimez plus de 10 réunions :

```dart
// Exporter avant suppression
final meetings = await GroupsFirebaseService.getGroupMeetingsStream(groupId).first;
final backup = meetings.map((m) => m.toFirestore()).toList();

// Sauvegarder JSON
final file = File('backup_meetings_${DateTime.now().millisecondsSinceEpoch}.json');
await file.writeAsString(jsonEncode(backup));

print('✅ Backup créé: ${file.path}');

// Maintenant supprimer
await GroupsFirebaseService.deleteAllGroupMeetings(groupId);
```

---

## 📊 Tableau Récapitulatif

| Action | Commande / Méthode | Portée | Réversible |
|--------|-------------------|--------|------------|
| Supprimer 1 réunion (UI) | Menu → Supprimer | 1 réunion | ❌ Non |
| Supprimer 1 réunion (code) | `deleteMeeting(id)` | 1 réunion | ❌ Non |
| Supprimer réunion + événement | `deleteMeetingWithEvent(id)` | 1 réunion + 1 événement | ❌ Non |
| Supprimer toutes réunions groupe | `deleteAllGroupMeetings(groupId)` | Toutes réunions 1 groupe | ❌ Non |
| Supprimer groupe complet | `deleteGroupWithEvents()` | Groupe + Réunions + Événements + Membres | ❌ Non |
| Soft delete | `softDeleteMeeting(id)` | 1 réunion (masquée) | ✅ Oui |

---

## 🎯 Exemples Pratiques

### Exemple 1 : Supprimer Réunions Passées d'un Groupe

```dart
Future<void> deleteOldMeetings(String groupId, {int daysAgo = 90}) async {
  final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo));
  
  final snapshot = await FirebaseFirestore.instance
      .collection('group_meetings')
      .where('groupId', isEqualTo: groupId)
      .where('date', isLessThan: Timestamp.fromDate(cutoffDate))
      .get();
  
  print('📊 ${snapshot.docs.length} réunions trouvées (> $daysAgo jours)');
  
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  
  await batch.commit();
  print('✅ Réunions passées supprimées');
}
```

### Exemple 2 : Supprimer Réunions Non Complétées

```dart
Future<void> deleteIncompleteMeetings(String groupId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('group_meetings')
      .where('groupId', isEqualTo: groupId)
      .where('isCompleted', isEqualTo: false)
      .get();
  
  print('📊 ${snapshot.docs.length} réunions non complétées');
  
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  
  await batch.commit();
}
```

### Exemple 3 : Archiver au Lieu de Supprimer

```dart
Future<void> archiveMeeting(String meetingId) async {
  final meetingDoc = await FirebaseFirestore.instance
      .collection('group_meetings')
      .doc(meetingId)
      .get();
  
  if (!meetingDoc.exists) return;
  
  // Copier vers collection archives
  await FirebaseFirestore.instance
      .collection('archived_meetings')
      .doc(meetingId)
      .set({
    ...meetingDoc.data()!,
    'archivedAt': FieldValue.serverTimestamp(),
  });
  
  // Supprimer l'original
  await meetingDoc.reference.delete();
  
  print('✅ Réunion archivée: $meetingId');
}
```

---

## 🔧 Checklist de Suppression

Avant de supprimer des réunions, vérifiez :

- [ ] **Backup créé** (si suppression massive)
- [ ] **Confirmation utilisateur** obtenue
- [ ] **Logs activés** pour tracer l'action
- [ ] **Vérification des dépendances** (présences, rapports)
- [ ] **Alternative soft-delete** considérée
- [ ] **Événements liés** identifiés
- [ ] **Permissions utilisateur** vérifiées
- [ ] **Tests effectués** en environnement dev

---

## 📞 Support

Si vous avez des questions ou besoin d'aide :

1. Consultez les logs Firebase Console
2. Vérifiez les règles de sécurité Firestore
3. Testez d'abord en environnement de développement
4. Contactez l'équipe technique si problème persiste

---

**Date de Création** : 14 octobre 2025  
**Version** : 1.0  
**Auteur** : Équipe Technique App Jubilé Tabernacle  
**Statut** : ✅ Document Complet
