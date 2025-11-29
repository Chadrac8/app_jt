# ⚠️ KEYSTORE ANDROID - SAUVEGARDE CRITIQUE

## 🚨 IMPORTANCE ABSOLUE

Le fichier `android/upload-keystore.jks` est **CRITIQUE** pour votre application Android.

**Si vous perdez ce fichier, vous ne pourrez PLUS JAMAIS publier de mise à jour de votre application sur le Google Play Store.**

Vous seriez obligé de :
1. Créer une nouvelle application avec un nouveau package
2. Perdre tous vos utilisateurs existants
3. Perdre toutes vos évaluations et notes
4. Recommencer à zéro

---

## 🔐 Fichiers à Sauvegarder

### Fichiers Critiques

1. **android/upload-keystore.jks**
   - Clé de signature de l'application
   - Impossible à régénérer

2. **android/key.properties**
   - Contient les mots de passe
   - `storePassword=jubile2024`
   - `keyPassword=jubile2024`
   - `keyAlias=upload`

### Informations du Keystore

```
Fichier : android/upload-keystore.jks
Alias : upload
Store Password : jubile2024
Key Password : jubile2024
Algorithme : RSA 2048 bits
Validité : 10,000 jours (27 ans)
Date de création : 29 novembre 2024
```

---

## 💾 Où Sauvegarder

### Option 1 : Cloud Sécurisé (Recommandé)
- **iCloud** (Mac/iOS) avec chiffrement
- **Google Drive** avec authentification 2FA
- **Dropbox** avec authentification 2FA
- **OneDrive** avec chiffrement

⚠️ **Ne PAS stocker dans un dépôt Git public !**

### Option 2 : Stockage Physique
- **Disque dur externe** chiffré
- **Clé USB** dans un coffre-fort
- **Copie papier** des mots de passe dans un lieu sûr

### Option 3 : Service de Gestion de Secrets
- **1Password**
- **LastPass**
- **Bitwarden**
- **AWS Secrets Manager**
- **Azure Key Vault**

---

## 📋 Checklist de Sauvegarde

Cochez chaque étape après l'avoir complétée :

### Sauvegarde Immédiate (Maintenant)
- [ ] Copier `android/upload-keystore.jks` vers iCloud/Google Drive
- [ ] Copier `android/key.properties` vers iCloud/Google Drive
- [ ] Noter les mots de passe dans un gestionnaire de mots de passe
- [ ] Créer un fichier texte avec toutes les informations :
  ```
  Application : Jubilé Tabernacle
  Package : org.jubiletabernacle.app
  Keystore : upload-keystore.jks
  Alias : upload
  Store Password : jubile2024
  Key Password : jubile2024
  Date création : 29 novembre 2024
  ```

### Sauvegardes Supplémentaires (Recommandé)
- [ ] Copie sur disque dur externe
- [ ] Copie sur clé USB
- [ ] Envoi par email sécurisé à vous-même
- [ ] Partage chiffré avec un co-administrateur de confiance

### Documentation
- [ ] Créer un document "Accès Keystore Android"
- [ ] Lister tous les emplacements de sauvegarde
- [ ] Documenter la procédure de récupération
- [ ] Partager avec l'équipe technique

---

## 🔄 Commandes de Sauvegarde

### Sauvegarde Locale

```bash
# Créer un dossier de backup
mkdir -p ~/Backups/JubileTabernacle/Android

# Copier les fichiers critiques
cp android/upload-keystore.jks ~/Backups/JubileTabernacle/Android/
cp android/key.properties ~/Backups/JubileTabernacle/Android/

# Créer une archive chiffrée (optionnel)
zip -e ~/Backups/JubileTabernacle/Android/keystore-backup.zip \
  android/upload-keystore.jks \
  android/key.properties

# Le système demandera un mot de passe pour l'archive
```

### Sauvegarde Cloud (iCloud - Mac)

```bash
# Copier vers iCloud Drive
cp android/upload-keystore.jks ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backups/JubileTabernacle/
cp android/key.properties ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backups/JubileTabernacle/
```

### Sauvegarde Cloud (Google Drive - avec rclone)

```bash
# Si rclone est configuré
rclone copy android/upload-keystore.jks gdrive:Backups/JubileTabernacle/
rclone copy android/key.properties gdrive:Backups/JubileTabernacle/
```

---

## 🛡️ Vérification de la Sauvegarde

### Test de Restauration

1. **Créer un dossier de test** :
   ```bash
   mkdir -p ~/test-restore
   ```

2. **Copier depuis la sauvegarde** :
   ```bash
   cp ~/Backups/JubileTabernacle/Android/upload-keystore.jks ~/test-restore/
   ```

3. **Vérifier l'intégrité** :
   ```bash
   keytool -list -v -keystore ~/test-restore/upload-keystore.jks
   # Entrer le mot de passe : jubile2024
   ```

4. **Vérifier la sortie** :
   ```
   Alias name: upload
   Creation date: 29 nov. 2024
   Entry type: PrivateKeyEntry
   Certificate chain length: 1
   Certificate[1]:
   Owner: CN=Jubile Tabernacle, OU=Jubile Tabernacle, O=Jubile Tabernacle, L=Paris, ST=Ile-de-France, C=FR
   ```

5. **Nettoyer** :
   ```bash
   rm -rf ~/test-restore
   ```

---

## 🔄 Procédure de Récupération

### En Cas de Perte du Fichier Local

1. **Localiser la sauvegarde** :
   - Vérifier iCloud/Google Drive
   - Vérifier disque externe
   - Vérifier gestionnaire de mots de passe

2. **Restaurer le fichier** :
   ```bash
   # Depuis iCloud (Mac)
   cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backups/JubileTabernacle/upload-keystore.jks android/
   cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backups/JubileTabernacle/key.properties android/
   ```

3. **Vérifier la restauration** :
   ```bash
   # Tester la signature
   flutter build appbundle --release
   ```

4. **Si succès** :
   - Le build se termine sans erreur
   - Le fichier .aab est créé
   - Vous pouvez publier des mises à jour

---

## 📱 Partage Sécurisé avec l'Équipe

### Option 1 : Google Drive avec Lien Sécurisé
1. Uploader sur Google Drive
2. Partager uniquement avec emails spécifiques
3. Activer l'expiration du lien (optionnel)

### Option 2 : Service de Partage Chiffré
- **WeTransfer** (avec mot de passe)
- **Firefox Send**
- **Tresorit**

### Option 3 : Coffre-Fort d'Équipe
- **1Password Teams**
- **LastPass Enterprise**
- **Bitwarden Organizations**

---

## ⚠️ Ce Qu'il NE FAUT PAS Faire

### ❌ NE JAMAIS
- Commiter dans Git (déjà protégé par .gitignore)
- Partager sur Slack/Discord/email non chiffré
- Stocker sur un serveur non sécurisé
- Donner accès à des personnes non autorisées
- Utiliser le même keystore pour plusieurs apps
- Oublier les mots de passe

### ❌ ÉVITER
- Un seul point de sauvegarde
- Stockage uniquement local
- Pas de documentation
- Pas de test de récupération

---

## 📅 Calendrier de Vérification

### Mensuel
- [ ] Vérifier que les sauvegardes sont accessibles
- [ ] Tester l'accès aux fichiers cloud
- [ ] Confirmer que les mots de passe fonctionnent

### Trimestriel
- [ ] Effectuer un test de restauration complet
- [ ] Mettre à jour la documentation si changements
- [ ] Vérifier les permissions d'accès équipe

### Annuel
- [ ] Auditer tous les emplacements de sauvegarde
- [ ] Renouveler les accès cloud si nécessaire
- [ ] Créer de nouvelles copies de sécurité

---

## 📞 En Cas de Perte Totale

Si vous avez perdu **TOUTES** vos sauvegardes :

### Google Play App Signing (Solution de Secours)

Si vous avez activé **Google Play App Signing**, Google conserve une copie de votre clé.

1. **Vérifier dans Play Console** :
   - Allez dans votre app > Configuration > Intégrité de l'application
   - Vérifiez si "Google Play App Signing" est activé

2. **Si activé** :
   - Vous pouvez continuer à publier des mises à jour
   - Google signera automatiquement avec leur copie

3. **Si NON activé** :
   - ⚠️ **Vous devrez créer une nouvelle application**
   - Nouveau package name requis
   - Perte de tous les utilisateurs et évaluations

### Leçon Apprise
Cette situation souligne l'importance critique des sauvegardes !

---

## 🎯 Actions IMMÉDIATEMENT après avoir lu ce fichier

1. **[ ] MAINTENANT** : Copier le keystore vers au moins 2 emplacements différents
2. **[ ] MAINTENANT** : Noter les mots de passe dans un gestionnaire sécurisé
3. **[ ] AUJOURD'HUI** : Créer une archive chiffrée
4. **[ ] CETTE SEMAINE** : Configurer une sauvegarde cloud automatique
5. **[ ] CE MOIS** : Documenter la procédure pour l'équipe

---

## 📝 Template de Documentation Équipe

```markdown
# Accès Keystore Android - Jubilé Tabernacle

## Informations
- Application : Jubilé Tabernacle
- Package : org.jubiletabernacle.app
- Keystore : upload-keystore.jks
- Alias : upload

## Emplacements des Sauvegardes
1. iCloud Drive : /Backups/JubileTabernacle/
2. Google Drive : /Backups/JubileTabernacle/
3. Disque externe : [Spécifier]
4. Gestionnaire mots de passe : [Spécifier]

## Personnes Autorisées
- [Nom] - [Email] - Administrateur principal
- [Nom] - [Email] - Développeur senior
- [Nom] - [Email] - Backup

## Procédure d'Accès
1. Contacter [Nom administrateur]
2. Vérifier identité
3. Accès accordé via [Méthode]

## Dernière Vérification
- Date : [Date]
- Testé par : [Nom]
- Résultat : ✅ OK
```

---

## 🔗 Ressources

- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Android Keystore Documentation](https://developer.android.com/studio/publish/app-signing)
- [Best Practices for Signing](https://developer.android.com/studio/publish/app-signing#secure-shared-keystore)

---

**Date de création du keystore** : 29 novembre 2024  
**Responsable actuel** : [À compléter]  
**Dernière sauvegarde vérifiée** : [À compléter]

---

**⚠️ N'ATTENDEZ PAS ! SAUVEGARDEZ MAINTENANT ! ⚠️**
