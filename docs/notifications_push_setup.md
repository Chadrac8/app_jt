# Configuration des Notifications Push - Guide Complet

## Vue d'ensemble

Le système de notifications push a été intégré dans l'application DreamFlow en utilisant Firebase Cloud Messaging (FCM). Ce système permet d'envoyer des notifications en temps réel aux utilisateurs pour les événements importants.

## Architecture

### 1. Services Flutter
- **`PushNotificationService`** : Service principal de gestion des notifications
- **`NotificationIntegrationService`** : Service d'intégration avec les autres modules
- **`AuthListenerService`** : Gestion des tokens lors de la connexion/déconnexion

### 2. Firebase Cloud Functions
- **`sendPushNotification`** : Envoie une notification à un utilisateur
- **`sendMulticastNotification`** : Envoie des notifications à plusieurs utilisateurs
- **`onAppointmentCreated`** : Notification automatique pour les nouveaux rendez-vous
- **`onAppointmentUpdated`** : Notification lors de la mise à jour des rendez-vous
- **`sendAppointmentReminders`** : Rappels automatiques (1h et 24h avant)
- **`cleanupInactiveTokens`** : Nettoyage des tokens inactifs

### 3. Collections Firestore
- **`fcm_tokens`** : Stockage des tokens FCM par utilisateur
- **`push_notifications`** : Historique des notifications reçues
- **`pending_notifications`** : Notifications en attente de traitement

## Configuration

### 1. Dépendances ajoutées

```yaml
dependencies:
  firebase_messaging: '>=15.1.3'
  cloud_functions: '>=5.1.3'
```

### 2. Configuration Android

#### AndroidManifest.xml
```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />

<!-- Service Firebase Messaging -->
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 3. Configuration iOS

#### Info.plist
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Utilisation

### 1. Initialisation

Le service s'initialise automatiquement au démarrage de l'application :

```dart
// Dans main.dart
await PushNotificationService.initialize();
```

### 2. Envoi de notifications

#### Notification à un utilisateur
```dart
await PushNotificationService.sendNotificationToUser(
  userId: 'user_id',
  title: 'Titre de la notification',
  body: 'Contenu de la notification',
  data: {
    'type': 'appointment',
    'action': 'new',
    // autres données...
  },
);
```

#### Notification à plusieurs utilisateurs
```dart
await PushNotificationService.sendNotificationToUsers(
  userIds: ['user1', 'user2', 'user3'],
  title: 'Titre de la notification',
  body: 'Contenu de la notification',
  data: {'type': 'event'},
);
```

### 3. Intégration avec les modules existants

#### Rendez-vous
```dart
// Nouveau rendez-vous
await NotificationIntegrationService.notifyNewAppointment(
  responsableId: 'responsable_id',
  membreName: 'Nom du membre',
  dateTime: DateTime.now(),
  motif: 'Motif du rendez-vous',
);

// Confirmation de rendez-vous
await NotificationIntegrationService.notifyAppointmentConfirmed(
  membreId: 'membre_id',
  dateTime: DateTime.now(),
  responsableName: 'Nom du responsable',
);
```

#### Études bibliques
```dart
await NotificationIntegrationService.notifyNewBibleStudy(
  userIds: ['user1', 'user2'],
  title: 'Titre de l\'étude',
  description: 'Description',
  authorName: 'Auteur',
);
```

## Interface utilisateur

### 1. Widget d'affichage des notifications
```dart
// Affichage des notifications
PushNotificationsWidget()

// Badge de notifications non lues
NotificationBadgeWidget(
  child: Icon(Icons.notifications),
)
```

### 2. Page des notifications
```dart
// Navigation vers la page des notifications
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PushNotificationsPage()),
);
```

## Types de notifications supportés

### 1. Rendez-vous
- `appointment` : Nouvelles demandes, confirmations, annulations, rappels

### 2. Services
- `service` : Nouveaux services, rappels de service

### 3. Événements
- `event` : Nouveaux événements, rappels

### 4. Bible
- `bible_study` : Nouvelles études bibliques
- `bible_article` : Nouveaux articles bibliques

### 5. Blog
- `blog` : Nouveaux articles de blog

### 6. Spéciaux
- `urgent` : Messages urgents
- `welcome` : Bienvenue aux nouveaux membres
- `birthday` : Anniversaires
- `form` : Rappels de formulaires

## Gestion des états

### 1. Permissions
Le service demande automatiquement les permissions nécessaires lors de l'initialisation.

### 2. États des notifications
- **Reçues** : Stockées dans Firestore avec statut `isRead: false`
- **Lues** : Marquées avec `isRead: true`
- **Navigation** : Redirection automatique selon le type

### 3. Gestion des erreurs
- Fallback automatique en cas d'échec des Cloud Functions
- Notifications mises en attente pour traitement ultérieur
- Nettoyage automatique des tokens inactifs

## Déploiement

### 1. Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Configuration Firebase
- Activer Firebase Cloud Messaging dans la console Firebase
- Configurer les certificats APNs pour iOS
- Ajouter les SHA-1/SHA-256 pour Android

### 3. Test
```bash
# Test en émulateur
firebase emulators:start --only functions

# Test de notification
# Utiliser l'interface admin ou les tests unitaires
```

## Sécurité

### 1. Permissions
- Seuls les utilisateurs authentifiés peuvent envoyer des notifications
- Validation des tokens côté serveur
- Nettoyage automatique des tokens inactifs

### 2. Données
- Chiffrement automatique par Firebase
- Validation des données d'entrée
- Limitation du taux d'envoi

## Monitoring

### 1. Logs
- Logs automatiques dans Firebase Functions
- Débuggage activé en mode développement
- Suivi des erreurs d'envoi

### 2. Métriques
- Nombre de notifications envoyées
- Taux de livraison
- Tokens actifs/inactifs

## Dépannage

### 1. Notifications non reçues
- Vérifier les permissions de l'appareil
- Contrôler la validité du token FCM
- Vérifier les logs des Cloud Functions

### 2. Erreurs d'envoi
- Tokens expirés ou invalides
- Problème de configuration Firebase
- Limites de quota dépassées

### 3. Performance
- Utiliser l'envoi multicast pour les groupes
- Optimiser la fréquence des notifications
- Nettoyer régulièrement les tokens inactifs

## Roadmap

### 1. Améliorations prévues
- [ ] Notifications locales programmées
- [ ] Catégories de notifications personnalisables
- [ ] Interface admin pour l'envoi de notifications
- [ ] Analytics avancées
- [ ] Notifications riches (images, actions)

### 2. Intégrations futures
- [ ] Notifications par email en backup
- [ ] Notifications SMS pour les urgences
- [ ] Intégration avec les systèmes externes
- [ ] API REST pour les applications tierces

## Support

Pour toute question ou problème :
1. Consulter les logs Firebase Functions
2. Vérifier la configuration dans la console Firebase
3. Tester avec l'émulateur local
4. Consulter la documentation Firebase officielle
