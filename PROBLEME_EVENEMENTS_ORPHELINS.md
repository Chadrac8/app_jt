# 🚨 PROBLÈME : Événements Orphelins dans le Calendrier

## 📋 Situation Actuelle

**Symptôme rapporté** :
> "Les réunions de groupes déjà supprimées comme réunion ndndnd et réunion École du dimanche sont encore dans le calendrier de l'église!!!!"

## 🔍 Diagnostic

### Problème Identifié

Vous avez **2 types de données liées** :

1. **Meetings** (Réunions) → Collection `group_meetings`
2. **Events** (Événements du calendrier) → Collection `events`

Quand vous créez un groupe avec `generateEvents=true`, le système crée :
- ✅ Des **meetings** dans `group_meetings`  
- ✅ Des **événements** dans `events` (avec `linkedEventId`)

### Le Problème

Quand vous supprimez les réunions **depuis Firebase Console** ou manuellement, vous avez probablement supprimé :
- ✅ Les meetings de `group_meetings`  
- ❌ Mais PAS les events de `events`

**Résultat** : Les événements sont toujours là dans le calendrier = **Événements Orphelins** !

## 🔧 Solution Immédiate

### Option 1 : Utiliser la Méthode Correcte (RECOMMANDÉ)

Au lieu d'utiliser `deleteMeeting()`, utilisez **`deleteMeetingWithEvent()`** :

```dart
// ❌ MAUVAIS - Supprime seulement le meeting
await GroupsFirebaseService.deleteMeeting(meetingId);

// ✅ BON - Supprime meeting ET événement lié
await GroupsFirebaseService.deleteMeetingWithEvent(meetingId);
```

### Option 2 : Nettoyer les Événements Orphelins Existants

Puisque vous avez déjà des événements orphelins, il faut les nettoyer manuellement.

#### Script de Nettoyage Manuel (Firebase Console)

1. **Ouvrir Firebase Console**
   - Aller sur console.firebase.google.com
   - Sélectionner votre projet
   - Firestore Database

2. **Rechercher les événements des groupes**
   ```
   Collection: events
   Filtrer: linkedGroupId != null
   ```

3. **Identifier les orphelins**
   - Copier le `linkedGroupId` ou `linkedEventSeriesId`
   - Chercher dans `group_meetings` si une réunion correspondante existe
   - Si aucune réunion → C'est un orphelin

4. **Supprimer les orphelins**
   - Sélectionner chaque événement orphelin
   - Supprimer

#### OU : Utiliser un Script Dart

Créer un fichier temporaire dans votre app :

**Fichier** : `lib/temp_cleanup.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/groups_firebase_service.dart';

/// Nettoyage temporaire des événements orphelins
/// À SUPPRIMER après utilisation !
class TempOrphanCleanup {
  static Future<void> cleanupOrphanEvents() async {
    final firestore = FirebaseFirestore.instance;
    
    print('🔍 Recherche des événements orphelins...\n');
    
    // 1. Récupérer tous les événements liés à des groupes
    final eventsSnapshot = await firestore
        .collection('events')
        .where('linkedGroupId', isNotEqualTo: null)
        .get();
    
    print('📊 ${eventsSnapshot.docs.length} événements de groupes trouvés');
    
    final orphanIds = <String>[];
    final orphanTitles = <String>[];
    
    // 2. Vérifier chaque événement
    for (final eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final linkedEventId = eventDoc.id;
      
      // Chercher si une réunion correspondante existe
      final meetingsSnapshot = await firestore
          .collection('group_meetings')
          .where('linkedEventId', isEqualTo: linkedEventId)
          .limit(1)
          .get();
      
      // Si aucune réunion trouvée → Orphelin !
      if (meetingsSnapshot.docs.isEmpty) {
        orphanIds.add(eventDoc.id);
        orphanTitles.add(eventData['title'] as String? ?? 'Sans titre');
        
        print('⚠️  Orphelin trouvé: ${eventData['title']}');
      }
    }
    
    if (orphanIds.isEmpty) {
      print('\n✅ Aucun événement orphelin trouvé\n');
      return;
    }
    
    print('\n📋 ${orphanIds.length} événements orphelins détectés:');
    for (int i = 0; i < orphanTitles.length; i++) {
      print('   ${i + 1}. ${orphanTitles[i]}');
    }
    
    print('\n🗑️  Suppression en cours...\n');
    
    // 3. Supprimer les orphelins
    final batch = firestore.batch();
    for (final orphanId in orphanIds) {
      batch.delete(firestore.collection('events').doc(orphanId));
    }
    
    await batch.commit();
    
    print('✅ ${orphanIds.length} événements orphelins supprimés !\n');
  }
}

/// Fonction à appeler depuis un bouton admin
Future<void> runCleanup() async {
  try {
    await TempOrphanCleanup.cleanupOrphanEvents();
    print('🎉 Nettoyage terminé avec succès');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
```

#### Ajouter un Bouton Admin pour Lancer le Nettoyage

Dans votre page admin, ajoutez temporairement :

```dart
import 'temp_cleanup.dart';

// Dans votre interface admin
ElevatedButton(
  onPressed: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nettoyer les événements orphelins'),
        content: Text(
          'Cette action va supprimer tous les événements du calendrier '
          'dont les réunions ont été supprimées.\n\n'
          'Continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Nettoyer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Afficher un spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        await runCleanup();
        Navigator.pop(context); // Fermer spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Nettoyage terminé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Fermer spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
  ),
  child: Text('🧹 Nettoyer Événements Orphelins'),
)
```

---

## 🛡️ Prévention Future

### 1. Ajouter Option de Suppression dans l'UI

Actuellement, **il n'y a PAS de bouton "Supprimer"** dans le menu des réunions !

Modifiez `lib/widgets/group_meetings_list.dart` ligne ~280 :

```dart
PopupMenuButton<String>(
  onSelected: (value) async {
    switch (value) {
      case 'edit':
        await _editMeeting(meeting);
        break;
      case 'attendance':
        await _takeAttendance(meeting);
        break;
      case 'report':
        await _addReport(meeting);
        break;
      case 'delete': // 🆕 NOUVEAU
        await _deleteMeeting(meeting);
        break;
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'edit',
      child: Row(
        children: [
          Icon(Icons.edit, size: 20),
          SizedBox(width: 12),
          Text('Modifier'),
        ],
      ),
    ),
    if (!meeting.isCompleted)
      const PopupMenuItem(
        value: 'attendance',
        child: Row(
          children: [
            Icon(Icons.how_to_reg, size: 20),
            SizedBox(width: 12),
            Text('Prendre les présences'),
          ],
        ),
      ),
    const PopupMenuItem(
      value: 'report',
      child: Row(
        children: [
          Icon(Icons.note_add, size: 20),
          SizedBox(width: 12),
          Text('Ajouter un rapport'),
        ],
      ),
    ),
    // 🆕 NOUVEAU : Option de suppression
    const PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete, size: 20, color: Colors.red),
          SizedBox(width: 12),
          Text('Supprimer', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  ],
)
```

### 2. Implémenter la Méthode de Suppression

Toujours dans `group_meetings_list.dart`, ajoutez :

```dart
Future<void> _deleteMeeting(GroupMeetingModel meeting) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Supprimer la réunion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Êtes-vous sûr de vouloir supprimer "${meeting.title}" ?'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ce qui sera supprimé :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• La réunion'),
                if (meeting.linkedEventId != null)
                  Text('• L\'événement du calendrier'),
                Text('• Les présences enregistrées'),
                Text('• Les rapports'),
              ],
            ),
          ),
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
            backgroundColor: Colors.red,
          ),
          child: Text('Supprimer'),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  try {
    // ✅ Utiliser la bonne méthode qui supprime aussi l'événement
    if (meeting.linkedEventId != null) {
      await GroupsFirebaseService.deleteMeetingWithEvent(meeting.id);
    } else {
      await GroupsFirebaseService.deleteMeeting(meeting.id);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Réunion supprimée avec succès'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }
}
```

---

## 📊 Résumé

### Problème Actuel
```
┌──────────────────────────────────────────┐
│  SITUATION ACTUELLE                      │
├──────────────────────────────────────────┤
│                                          │
│  ✅ Meetings supprimés de Firestore     │
│  ❌ Events toujours dans le calendrier   │
│                                          │
│  = ÉVÉNEMENTS ORPHELINS                 │
│                                          │
└──────────────────────────────────────────┘
```

### Solution
```
┌──────────────────────────────────────────┐
│  ACTIONS À FAIRE                         │
├──────────────────────────────────────────┤
│                                          │
│  1. Nettoyer les orphelins existants    │
│     → Script de nettoyage               │
│                                          │
│  2. Ajouter bouton "Supprimer" dans UI  │
│     → Menu des réunions                 │
│                                          │
│  3. Utiliser deleteMeetingWithEvent()   │
│     → Suppression complète              │
│                                          │
└──────────────────────────────────────────┘
```

---

## ✅ Checklist d'Actions

- [ ] **Nettoyer les événements orphelins existants**
  - [ ] Créer `lib/temp_cleanup.dart`
  - [ ] Ajouter bouton admin de nettoyage
  - [ ] Exécuter le nettoyage
  - [ ] Vérifier que le calendrier est propre
  - [ ] Supprimer `temp_cleanup.dart`

- [ ] **Ajouter suppression dans l'UI**
  - [ ] Modifier `group_meetings_list.dart`
  - [ ] Ajouter option "Supprimer" dans PopupMenu
  - [ ] Implémenter `_deleteMeeting()`
  - [ ] Tester avec une réunion de test

- [ ] **Documenter la procédure**
  - [ ] Former les administrateurs
  - [ ] Ajouter dans le guide utilisateur

---

**Date** : 14 octobre 2025  
**Priorité** : 🔴 URGENTE  
**Statut** : En attente d'action
