# Configuration du système d'email pour les messages de contact

## 📧 Vue d'ensemble

Le système de contact a été amélioré pour envoyer automatiquement les messages par email en plus de les sauvegarder dans Firebase Firestore.

### ✨ Fonctionnalités

- **Sauvegarde Firebase** : Tous les messages sont sauvegardés dans Firestore
- **Notification email** : Email automatique envoyé à `contact@jubiletabernacle.org`
- **Interface d'administration** : Consultation et gestion des messages
- **Email formaté** : Template HTML professionnel avec toutes les informations

## 🛠️ Configuration

### 1. Prérequis

Assurez-vous d'avoir :
- Un compte Gmail configuré pour `contact@jubiletabernacle.org`
- La validation en 2 étapes activée sur ce compte
- Firebase CLI installé et connecté

### 2. Créer un mot de passe d'application Gmail

1. Allez sur [myaccount.google.com](https://myaccount.google.com)
2. Sécurité → Validation en 2 étapes
3. Mots de passe des applications
4. Sélectionnez "Autre" et tapez "Jubilé Tabernacle"
5. Copiez le mot de passe généré (16 caractères)

### 3. Configurer le secret Firebase

Exécutez le script de configuration :

```bash
./configure_email.sh
```

Ou manuellement :

```bash
firebase functions:secrets:set EMAIL_PASSWORD
```

### 4. Déployer les fonctions

```bash
firebase deploy --only functions
```

## 🔄 Fonctionnement

### Flux automatique

1. **Utilisateur** soumet le formulaire de contact
2. **Application** sauvegarde le message dans Firestore
3. **Firebase Function** se déclenche automatiquement
4. **Email** envoyé à `contact@jubiletabernacle.org`
5. **Notification** visible dans l'interface d'administration

### Template d'email

L'email contient :
- **En-tête** avec branding Jubilé Tabernacle
- **Informations de l'expéditeur** (nom, email)
- **Sujet** du message
- **Date et heure** de réception
- **Contenu** formaté du message
- **Call-to-action** vers l'interface d'administration
- **ID du message** pour traçabilité

## 🎯 Avantages

### Pour les utilisateurs
- ✅ Envoi direct sans ouvrir l'application mail
- ✅ Confirmation de réception dans l'app
- ✅ Interface moderne et intuitive

### Pour les administrateurs
- ✅ Notification email immédiate
- ✅ Interface web pour consulter tous les messages
- ✅ Gestion des messages (lu/non lu, suppression)
- ✅ Historique complet des contacts

## 🚀 Déploiement

### Étapes complètes

1. **Configurer l'email** :
   ```bash
   ./configure_email.sh
   ```

2. **Déployer les fonctions** :
   ```bash
   firebase deploy --only functions
   ```

3. **Vérifier le déploiement** :
   ```bash
   firebase functions:log
   ```

4. **Tester** en envoyant un message depuis l'app

## 🔍 Débogage

### Vérifier les logs

```bash
firebase functions:log --only onContactMessageCreated
```

### Tester localement

```bash
cd functions
firebase emulators:start --only functions,firestore
```

### Vérifier la configuration

```bash
firebase functions:secrets:list
```

## 📊 Monitoring

Les événements suivants sont loggés :
- ✅ Réception d'un nouveau message
- ✅ Envoi d'email réussi
- ❌ Erreurs d'envoi d'email
- 📧 Détails de l'email envoyé

## ⚡ Performance

- **Déclenchement** : Instantané (trigger Firestore)
- **Envoi email** : 1-3 secondes
- **Fiabilité** : Retry automatique Firebase
- **Coût** : Fonction gratuite dans les limites Firebase

## 🔒 Sécurité

- **Secrets** : Mot de passe stocké de façon sécurisée
- **Transport** : TLS/SSL pour l'envoi email
- **Données** : Pas de stockage des credentials dans le code
- **Accès** : Limité aux administrateurs Firebase

---

**✅ Le système est maintenant opérationnel !**

Les messages de contact sont automatiquement sauvegardés et envoyés par email.
