# 🔍 ANALYSE COMPLÈTE DES INDEX FIREBASE MANQUANTS

## Collections et requêtes identifiées

### 1. MODULE PRIÈRES (prayers_firebase_service.dart)

**Collection : prayers**

Requêtes composites identifiées :
```dart
// Ligne 75-79: Filtrage prières approuvées non archivées
.where('isApproved', isEqualTo: true)
.where('isArchived', isEqualTo: false)
.orderBy('createdAt', descending: true)

// Ligne 334-335: Prières récentes publiques
.where('isApproved', isEqualTo: true)
.where('isArchived', isEqualTo: false)
.orderBy('createdAt', descending: true)

// Ligne 361-362: Prières publiques
.where('isApproved', isEqualTo: true)
.where('isArchived', isEqualTo: false)

// Ligne 385-386: Prières aléatoires
.where('isApproved', isEqualTo: true)
.where('isArchived', isEqualTo: false)
```

**Index manquants :**
- `prayers`: `isApproved` + `isArchived` + `createdAt`

### 2. MODULE FIREBASE SERVICE PRINCIPAL (firebase_service.dart)

**Collection : workflows**
```dart
// Ligne 419-420: Workflows par personne et statut
.where('personId', isEqualTo: personId)
.where('status', isEqualTo: status)

// Ligne 1030-1031: Workflows actifs par template
.where('workflowId', isEqualTo: workflowTemplate.id)
.where('status', whereIn: ['active', 'in_progress', 'pending'])
```

**Index manquants :**
- `workflows`: `personId` + `status`
- `workflows`: `workflowId` + `status`

### 3. MODULE SERMONS/PRÉDICATIONS (admin_branham_sermon_service.dart)

**Collection : branham_sermons**
```dart
// Ligne 32: Sermons actifs triés par date
.where('isActive', isEqualTo: true)
.orderBy('date', descending: true)

// Ligne 48: Sermons actifs avec limite
.where('isActive', isEqualTo: true)
.orderBy('date', descending: true)

// Ligne 141-142: Recherche par titre
.where('title', isGreaterThanOrEqualTo: query)
.where('title', isLessThanOrEqualTo: query + '\uf8ff')

// Ligne 148-149: Recherche par date
.where('date', isGreaterThanOrEqualTo: query)
.where('date', isLessThanOrEqualTo: query + '\uf8ff')
```

**Index manquants :**
- `branham_sermons`: `isActive` + `date`
- `branham_sermons`: `title` (range queries)
- `branham_sermons`: `date` (range queries)

### 4. MODULE ÉVÉNEMENTS (analysé précédemment)

**Collections : events, event_recurrences, event_instances**
- ✅ Déjà traité avec index ajoutés

### 5. MODULE GROUPES (groups_firebase_service.dart)

**Collections analysées :**
```dart
// Ligne 113-114: Membres de groupe actifs
.where('groupId', isEqualTo: groupId)
.where('status', isEqualTo: 'active')

// Ligne 335-336: Prochaines réunions
.where('groupId', isEqualTo: groupId)
.where('date', isGreaterThan: Timestamp.fromDate(now))
```

**Index manquants :**
- `group_members`: `groupId` + `status` ✅ (déjà ajouté)
- `group_meetings`: `groupId` + `date` ✅ (déjà ajouté)

## NOUVELLES COLLECTIONS À INDEXER

### 6. MODULE BLOG (blog_firebase_service.dart)

À analyser...

### 7. MODULE TÂCHES (tasks_firebase_service.dart)

Requêtes existantes vérifiées, index déjà présents.

### 8. MODULE NOTIFICATIONS

À analyser pour :
- `notifications`: `userId` + `isRead` + `createdAt`
- `notifications`: `targetType` + `targetId` + `createdAt`

### 9. MODULE FAMILLES

À analyser pour :
- `families`: `isActive` + `familyName`
- `family_members`: `familyId` + `isActive` + `role`

### 10. MODULE UTILISATEURS

À analyser pour :
- `users`: `isActive` + `role` + `lastName`
- `user_sessions`: `userId` + `isActive` + `lastActivity`

## COLLECTIONS SUPPLÉMENTAIRES IDENTIFIÉES

### 11. WORKFLOWS ET PROCESSUS
- `workflow_steps`: `workflowId` + `status` + `order`
- `workflow_assignments`: `assignedTo` + `status` + `dueDate`

### 12. CONFIGURATION ET LOGS
- `audit_logs`: `entityType` + `entityId` + `createdAt`
- `app_configurations`: `module` + `isActive`

### 13. COMMUNICATION
- `messages`: `recipientId` + `isRead` + `createdAt`
- `announcements`: `isPublished` + `targetAudience` + `publishDate`

## ANALYSE PRIORITAIRE

### Priorité 1 (Critique - erreurs actuelles) :
1. `prayers`: `isApproved` + `isArchived` + `createdAt`
2. `workflows`: `personId` + `status`
3. `branham_sermons`: `isActive` + `date`

### Priorité 2 (Performance) :
1. `workflows`: `workflowId` + `status`
2. `branham_sermons`: `title` (range)
3. Notifications et users

### Priorité 3 (Optimisation future) :
1. Logs et audit
2. Configuration
3. Messages et communication