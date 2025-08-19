# GUIDE DE DÉPLOIEMENT PRODUCTION - NOTIFICATIONS PUSH

**Date :** 12 Juillet 2025  
**Application :** ChurchFlow - Notifications Push  
**Objectif :** Déploiement complet en production Firebase

---

## 🎯 ÉTAPE 1 : CONFIGURATION PERMISSIONS IAM FIREBASE

### 📋 Prérequis Administrateur Projet

L'**administrateur du projet Firebase** doit configurer les permissions suivantes :

#### 1.1 Rôles IAM Requis

```bash
# Se connecter à Google Cloud Console
gcloud auth login

# Définir le projet
gcloud config set project VOTRE_PROJECT_ID

# Attribuer les rôles nécessaires au service account
gcloud projects add-iam-policy-binding VOTRE_PROJECT_ID \
  --member="serviceAccount:firebase-adminsdk-xxxxx@VOTRE_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudmessaging.serviceAgent"

gcloud projects add-iam-policy-binding VOTRE_PROJECT_ID \
  --member="serviceAccount:firebase-adminsdk-xxxxx@VOTRE_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/firestore.serviceAgent"
```

#### 1.2 Permissions Firebase Console

Dans la **Firebase Console** → **Paramètres du projet** → **Comptes de service** :

✅ **Cloud Messaging API** : Activé  
✅ **Firestore API** : Activé  
✅ **Cloud Functions API** : Activé  
✅ **Cloud Build API** : Activé

#### 1.3 Vérification des Autorisations

```bash
# Vérifier les permissions du service account
gcloud projects get-iam-policy VOTRE_PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:firebase-adminsdk*"
```

---

## 🚀 ÉTAPE 2 : DÉPLOIEMENT FIREBASE FUNCTIONS

### 2.1 Préparation du Déploiement

```bash
# Naviguer vers le dossier du projet
cd "/Users/chadracntsouassouani/Downloads/perfect 12"

# Vérifier la configuration Firebase
firebase projects:list

# S'assurer d'être connecté au bon projet
firebase use --add
```

### 2.2 Installation des Dépendances

```bash
# Installer les dépendances Firebase Functions
cd functions
npm install

# Revenir au dossier racine
cd ..
```

### 2.3 Déploiement des Functions

```bash
# Déployer uniquement les fonctions (recommandé)
firebase deploy --only functions

# Alternative : déploiement avec force en cas de conflit
firebase deploy --only functions --force

# Déploiement d'une fonction spécifique (optionnel)
firebase deploy --only functions:sendNotificationToUser
```

### 2.4 Vérification du Déploiement

```bash
# Lister les fonctions déployées
firebase functions:list

# Vérifier les logs de déploiement
firebase functions:log --only sendNotificationToUser --limit 10
```

---

## 🧪 ÉTAPE 3 : TESTS EN PRODUCTION

### 3.1 Tests de Base

#### Test 1 : Envoi via Interface Admin
```
1. Ouvrir l'application
2. Se connecter en tant qu'administrateur
3. Menu Admin → Plus → Envoyer notifications
4. Choisir type "Test" 
5. Message : "Test production - [TIMESTAMP]"
6. Destinataire : Vous-même
7. Envoyer et vérifier réception
```

#### Test 2 : Déclenchement Automatique
```
1. Créer un nouvel événement dans l'agenda
2. Vérifier réception notification automatique
3. Modifier un événement existant
4. Vérifier notification de modification
```

### 3.2 Tests Avancés

#### Test de Performance
```bash
# Test de charge avec plusieurs notifications simultanées
# (À exécuter depuis la console Firebase Functions)

# Tester envoi groupé à tous les utilisateurs
# Surveiller les métriques de performance
```

#### Test Multi-Plateforme
```
✅ Test sur iOS (si déployé)
✅ Test sur Android (si déployé)  
✅ Test sur Web (Chrome/Safari/Firefox)
✅ Test notifications en arrière-plan
✅ Test notifications avec app fermée
```

---

## 📊 ÉTAPE 4 : MONITORING ET LOGS FIREBASE

### 4.1 Accès aux Logs Firebase Console

**URL :** https://console.firebase.google.com/project/VOTRE_PROJECT_ID/functions/logs

#### Navigation :
```
Firebase Console → Fonctions → Journaux
OU
Firebase Console → Analytics → DebugView
```

### 4.2 Commandes de Monitoring

```bash
# Logs en temps réel
firebase functions:log --follow

# Logs d'une fonction spécifique
firebase functions:log --only sendNotificationToUser

# Logs avec filtre d'erreur
firebase functions:log --only sendNotificationToUser | grep ERROR

# Logs des dernières 24h
firebase functions:log --since 24h
```

### 4.3 Métriques à Surveiller

#### 🔍 Métriques Clés
```
✅ Taux de succès envoi : >95%
✅ Latence moyenne : <2s
✅ Erreurs 4xx/5xx : <5%
✅ Tokens FCM valides : >90%
✅ Quota API respecté : <80%
```

#### 📈 Dashboard de Monitoring

**Firebase Console → Analytics → Custom Events :**

- `notification_sent` (succès)
- `notification_failed` (échecs)
- `notification_opened` (ouvertures)
- `fcm_token_refreshed` (renouvellements tokens)

### 4.4 Alertes et Notifications

#### Configuration Alertes Cloud Monitoring

```bash
# Créer une alerte pour taux d'erreur élevé
gcloud alpha monitoring policies create \
  --notification-channels=$NOTIFICATION_CHANNEL \
  --display-name="High Error Rate - Push Notifications" \
  --condition-filter='resource.type="cloud_function"' \
  --condition-comparison="COMPARISON_GREATER_THAN" \
  --condition-threshold-value=0.05
```

---

## 🛠️ RÉSOLUTION DE PROBLÈMES COURANTS

### Erreur : "Insufficient permissions"
```bash
# Solution : Vérifier les rôles IAM
gcloud projects get-iam-policy VOTRE_PROJECT_ID
```

### Erreur : "Function deployment failed"
```bash
# Solution : Nettoyer et redéployer
firebase functions:delete --force sendNotificationToUser
firebase deploy --only functions
```

### Erreur : "FCM token not found"
```bash
# Solution : Nettoyer les tokens obsolètes
# La fonction cleanupInvalidTokens s'en charge automatiquement
```

---

## ✅ CHECKLIST DE VALIDATION PRODUCTION

### Avant Déploiement
- [ ] Permissions IAM configurées
- [ ] APIs Firebase activées  
- [ ] Dépendances installées
- [ ] Configuration validée en émulateur

### Après Déploiement
- [ ] Toutes les fonctions déployées avec succès
- [ ] Tests manuels passés
- [ ] Logs sans erreur critique
- [ ] Monitoring configuré
- [ ] Alertes en place

### Validation Utilisateur Final
- [ ] Interface admin fonctionnelle
- [ ] Notifications reçues sur tous appareils
- [ ] Badge temps réel opérationnel
- [ ] Performance satisfaisante

---

## 🎯 COMMANDES RAPIDES DE MAINTENANCE

```bash
# Vérification santé du système
firebase functions:log --limit 5

# Redémarrage fonction en cas de problème
firebase functions:delete sendNotificationToUser --force
firebase deploy --only functions:sendNotificationToUser

# Nettoyage tokens FCM obsolètes
# (Automatique via cleanupInvalidTokens, mais peut être déclenché manuellement)

# Monitoring en continu
firebase functions:log --follow | grep -E "(ERROR|SUCCESS|notification)"
```

---

## 📞 SUPPORT ET RESSOURCES

- **Documentation Firebase :** https://firebase.google.com/docs/functions
- **Console Firebase :** https://console.firebase.google.com
- **Cloud Console :** https://console.cloud.google.com
- **Status Firebase :** https://status.firebase.google.com

**🎉 Avec ce guide, votre système de notifications push sera opérationnel en production !**
