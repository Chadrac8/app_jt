# Système de Réservation de Chants Spéciaux

## Vue d'ensemble

Le système de réservation de chants spéciaux permet aux membres de l'église de réserver un dimanche spécifique pour présenter un chant spécial pendant le culte. Le système inclut des contraintes de réservation et un calendrier visuel pour une meilleure expérience utilisateur.

## Fonctionnalités principales

### 1. Calendrier de réservation
- **Affichage mensuel** : Seuls les dimanches du mois courant sont disponibles
- **Visualisation claire** : Dimanches disponibles (vert), réservés (rouge), passés (gris)
- **Interface intuitive** : Sélection simple en cliquant sur un dimanche disponible

### 2. Contraintes de réservation
- **Une réservation par dimanche** : Un seul chant spécial par culte
- **Une réservation par personne par mois** : Évite la monopolisation
- **Réservation mensuelle** : Le calendrier se réinitialise chaque mois
- **Pas de réservation rétroactive** : Impossible de réserver dans le passé

### 3. Formulaire dynamique
- **Auto-remplissage** : Récupération automatique des informations du profil utilisateur
- **Champs requis** : Nom, prénom, email, téléphone, titre du chant
- **Champ optionnel** : Lien pour les musiciens (YouTube, Spotify, partition PDF)
- **Validation** : Vérification des formats et de la cohérence des données

### 4. Interface d'administration
- **Vue mensuelle** : Gestion des réservations du mois courant
- **Historique complet** : Accès à toutes les réservations
- **Statistiques** : Métriques sur l'utilisation du système
- **Actions administratives** : Annulation de réservations si nécessaire

## Architecture technique

### Modèles de données

#### SpecialSongReservationModel
```dart
class SpecialSongReservationModel {
  final String id;
  final String personId;
  final String fullName;
  final String email;
  final String phone;
  final String songTitle;
  final String? musicianLink;
  final DateTime reservedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'active', 'cancelled', 'completed'
}
```

#### MonthlyReservationStats
```dart
class MonthlyReservationStats {
  final int year;
  final int month;
  final List<SpecialSongReservationModel> reservations;
  final List<DateTime> availableSundays;
  final List<DateTime> reservedSundays;
}
```

### Services

#### SpecialSongReservationService
- **createReservation()** : Crée une nouvelle réservation avec validation
- **getCurrentMonthReservations()** : Récupère les réservations du mois
- **getMonthlyStats()** : Calcule les statistiques mensuelles
- **isDateAvailable()** : Vérifie la disponibilité d'une date
- **canPersonReserve()** : Vérifie si une personne peut réserver

### Interface utilisateur

#### SpecialSongReservationPage
- Calendrier interactif des dimanches
- Formulaire de réservation dynamique
- Gestion des erreurs et validations
- Animations et feedback utilisateur

#### SundayCalendarWidget
- Affichage visuel du calendrier mensuel
- Légende claire des statuts
- Interaction tactile pour sélection

#### SpecialSongAdminPage
- Interface d'administration complète
- Onglets pour différentes vues
- Actions de gestion des réservations

## Base de données

### Collection: special_song_reservations

**Indexes requis :**
```javascript
// Index composé pour les requêtes mensuelles
{
  "reservedDate": 1,
  "status": 1
}

// Index pour les requêtes par personne
{
  "personId": 1,
  "reservedDate": -1
}

// Index pour les requêtes par mois
{
  "reservedDate": 1
}
```

**Règles de sécurité Firestore :**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /special_song_reservations/{reservationId} {
      // Lecture : utilisateurs connectés
      allow read: if request.auth != null;
      
      // Création : utilisateur connecté, réservation pour soi-même
      allow create: if request.auth != null 
        && request.auth.uid == resource.data.personId
        && isValidReservation(request.resource.data);
      
      // Mise à jour : propriétaire ou admin
      allow update: if request.auth != null 
        && (request.auth.uid == resource.data.personId 
            || hasAdminRole(request.auth.uid));
      
      // Suppression : admin seulement
      allow delete: if request.auth != null 
        && hasAdminRole(request.auth.uid);
    }
  }
  
  function isValidReservation(data) {
    return data.reservedDate is timestamp
      && data.reservedDate > request.time
      && data.songTitle is string
      && data.fullName is string
      && data.email is string;
  }
  
  function hasAdminRole(userId) {
    return get(/databases/$(database)/documents/users/$(userId)).data.role == 'admin';
  }
}
```

## Intégration

### Navigation depuis "Pour vous"
Le système est intégré à l'onglet "Pour vous" du module Vie de l'église. L'action "Chant spécial" redirige directement vers `SpecialSongReservationPage` au lieu du système de formulaires standard.

### Accès administrateur
Les administrateurs peuvent accéder à `SpecialSongAdminPage` depuis :
- Le module d'administration
- Le menu de gestion des formulaires
- Un lien direct dans l'interface admin

## Installation et configuration

### 1. Fichiers créés
- `lib/models/special_song_reservation_model.dart`
- `lib/services/special_song_reservation_service.dart`
- `lib/widgets/sunday_calendar_widget.dart`
- `lib/pages/special_song_reservation_page.dart`
- `lib/pages/special_song_admin_page.dart`

### 2. Modifications des fichiers existants
- `lib/modules/vie_eglise/widgets/pour_vous_tab.dart` : Redirection vers le système de réservation

### 3. Dépendances
Aucune dépendance supplémentaire requise. Le système utilise :
- `cloud_firestore` : Base de données
- `firebase_auth` : Authentification
- `intl` : Formatage des dates
- `flutter/material.dart` : Interface utilisateur

### 4. Configuration Firebase
1. Créer la collection `special_song_reservations`
2. Appliquer les index recommandés
3. Configurer les règles de sécurité

## Utilisation

### Pour les membres
1. Accéder à "Vie de l'église" > "Pour vous" > "Chant spécial"
2. Sélectionner un dimanche disponible dans le calendrier
3. Remplir le formulaire de réservation
4. Confirmer la réservation

### Pour les administrateurs
1. Accéder à l'interface d'administration
2. Consulter les réservations du mois
3. Voir l'historique complet
4. Analyser les statistiques d'utilisation
5. Annuler une réservation si nécessaire

## Maintenance

### Réinitialisation mensuelle
Le système se réinitialise automatiquement chaque mois :
- Les contraintes de réservation par personne sont levées
- Seuls les dimanches du nouveau mois sont disponibles
- L'historique reste accessible en mode lecture

### Surveillance
- Surveiller les tentatives de réservation multiples
- Vérifier la cohérence des données
- Analyser les statistiques d'utilisation mensuelle

## Évolutions possibles

### Fonctionnalités additionnelles
- **Notifications** : Rappel automatique avant la date
- **Workflow d'approbation** : Validation par responsable louange
- **Intégration calendrier** : Export vers Google Calendar/Outlook
- **Historique utilisateur** : Page de suivi personnel des réservations
- **Templates de chants** : Suggestions basées sur l'historique

### Améliorations techniques
- **Cache** : Mise en cache des statistiques mensuelles
- **Optimisation** : Pagination pour l'historique complet
- **Analytics** : Métriques détaillées d'utilisation
- **Backup** : Sauvegarde automatique des réservations

## Support

Pour toute question ou problème :
1. Vérifier les logs Firebase pour les erreurs
2. Contrôler les règles de sécurité Firestore
3. Tester la connectivité utilisateur
4. Examiner les contraintes de validation

Le système est conçu pour être robuste et auto-géré, minimisant les interventions administratives nécessaires.