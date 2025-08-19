# Module Bénévolat

## Description
Le module Bénévolat permet aux membres de l'église de s'engager activement dans la vie communautaire en gérant des tâches, en participant à des services et en collaborant sur des projets.

## Fonctionnalités principales

### 🎯 Vue d'ensemble
- **Progression générale** : Affichage du pourcentage de tâches terminées avec indicateur circulaire
- **Statistiques en temps réel** : Tâches terminées, à venir, en retard, et services disponibles
- **Tâches urgentes** : Affichage prioritaire des tâches nécessitant une attention immédiate
- **Services à venir** : Aperçu des prochains événements et services de l'église
- **Opportunités bénévoles** : Suggestions de nouvelles tâches disponibles

### 📋 Gestion des tâches personnelles
- **Mes tâches** : Liste complète des tâches assignées à l'utilisateur
- **Recherche et filtres avancés** : Par statut, priorité, date d'échéance
- **Création de tâches** : Interface complète pour créer de nouvelles tâches
- **Suivi du progrès** : Mise à jour en temps réel du statut des tâches

### 🆕 Tâches disponibles
- **Découverte** : Parcourir les tâches ouvertes à la communauté
- **Adhésion rapide** : Rejoindre des projets en un clic
- **Filtrage intelligent** : Affichage uniquement des tâches non assignées à l'utilisateur

### 🎪 Services et événements
- **Calendrier des services** : Vue d'ensemble des événements à venir
- **Inscription en ligne** : S'inscrire directement aux services
- **Gestion des bénévoles** : Suivi du nombre de participants requis

## Architecture technique

### Composants principaux

#### `BenevolatTab`
- Widget principal avec 4 onglets
- Gestion d'état avec `TickerProviderStateMixin`
- Intégration Firebase en temps réel
- Animations et transitions fluides

#### `TaskModel`
- Modèle de données pour les tâches
- Intégration Firestore native
- Propriétés : titre, description, statut, priorité, échéance, assignés, tags
- Méthodes utilitaires pour le calcul d'urgence et de progression

#### `Service`
- Modèle pour les services et événements
- Support des services récurrents
- Gestion des inscriptions et des rôles requis

#### Composants UI
- `TaskSearchFilterBar` : Barre de recherche et filtres avancés
- `TaskCreateEditModal` : Modal de création/édition de tâches
- `TaskDetailView` : Vue détaillée d'une tâche
- `ServicesMemberView` : Interface des services pour les membres

### Intégrations Firebase

#### Firestore Collections
```
/tasks
  - assigneeIds: Array<string>
  - title: string
  - description: string
  - status: 'todo' | 'in_progress' | 'completed'
  - priority: 'low' | 'medium' | 'high'
  - dueDate: Timestamp (optionnel)
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - createdBy: string
  - tags: Array<string>
  - category: string (optionnel)
  - isPublic: boolean
  - estimatedHours: number (optionnel)
  - location: string (optionnel)

/services
  - name: string
  - description: string
  - type: string
  - startDate: Timestamp
  - endDate: Timestamp (optionnel)
  - location: string
  - requiredRoles: Array<string>
  - assignedVolunteers: Array<string>
  - maxVolunteers: number
  - isRecurring: boolean
  - status: 'draft' | 'published' | 'completed' | 'cancelled'
```

#### Firebase Auth
- Authentification des utilisateurs
- Gestion des permissions et des rôles
- Filtrage des données par utilisateur

## Utilisation

### Intégration dans l'application
```dart
import 'package:votre_app/modules/benevolat/index.dart';

// Dans votre route ou navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BenevolatModule(),
  ),
);
```

### Intégration dans un onglet
```dart
import 'package:votre_app/modules/benevolat/index.dart';

// Dans un TabBarView
const BenevolatTab()
```

## Dépendances requises

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  intl: ^0.18.1
```

## Configuration requise

1. **Firebase Configuration**
   - Projet Firebase configuré
   - Firestore activé avec les règles appropriées
   - Firebase Auth configuré

2. **Règles Firestore recommandées**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règles pour les tâches
    match /tasks/{taskId} {
      allow read, write: if request.auth != null;
    }
    
    // Règles pour les services
    match /services/{serviceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.createdBy == request.auth.uid);
    }
  }
}
```

## Fonctionnalités avancées

### Notifications en temps réel
- Mise à jour automatique des listes de tâches
- Notifications pour les tâches en retard
- Alertes pour les nouveaux services disponibles

### Statistiques et analytiques
- Suivi des performances individuelles
- Calcul automatique des pourcentages de progression
- Métriques d'engagement communautaire

### Interface adaptive
- Support des thèmes sombre/clair
- Interface responsive pour tablettes
- Animations et transitions fluides

## Évolutions futures

- [ ] Système de points et récompenses
- [ ] Chat intégré pour les équipes
- [ ] Calendrier synchronisé avec les services externes
- [ ] Notifications push pour les tâches critiques
- [ ] Rapports d'activité détaillés
- [ ] Intégration avec les calendriers externes (Google Calendar, Outlook)
- [ ] Mode hors ligne avec synchronisation

## Support et maintenance

Le module est conçu pour être :
- **Maintenable** : Code bien structuré et documenté
- **Extensible** : Architecture modulaire permettant l'ajout de fonctionnalités
- **Performant** : Optimisations pour les grandes listes et les mises à jour en temps réel
- **Accessible** : Support des technologies d'assistance et navigation au clavier
