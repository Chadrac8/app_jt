# 🔥 GUIDE CONFIGURATION XCODE - TOKEN APNS

## 🚨 **PROBLÈME CRITIQUE IDENTIFIÉ**

Votre iPhone ne peut pas obtenir le token APNS nécessaire pour les notifications iOS. Cela indique un problème de configuration au niveau du projet Xcode.

## 🛠️ **ÉTAPES DE RÉSOLUTION**

### 1. **Ouvrir le projet Xcode**
```bash
cd /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle
open ios/Runner.xcworkspace
```

### 2. **Vérifier les Capabilities**
1. Dans Xcode, sélectionner **Runner** (projet principal)
2. Aller dans l'onglet **"Signing & Capabilities"**
3. Vérifier que **"Push Notifications"** est ajouté :
   - Si pas présent → Cliquer **"+ Capability"** → Ajouter **"Push Notifications"**

### 3. **Vérifier les Background Modes**
1. S'assurer que **"Background Modes"** est présent
2. Cocher **"Remote notifications"** si pas déjà fait

### 4. **Vérifier le profil de provisioning**
1. Dans **"Signing & Capabilities"**
2. S'assurer qu'un **Team** est sélectionné
3. Le profil doit supporter les Push Notifications

### 5. **Vérifier le certificat Firebase**
1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionner votre projet
3. **Project Settings** → **Cloud Messaging** → **iOS app configuration**
4. Vérifier que le certificat APNs est correctement uploadé

## 🔧 **CONFIGURATION MANUELLE XCODE**

### Ajouter Push Notifications Capability
```xml
<!-- Cette configuration devrait être automatique après ajout de la capability -->
<key>aps-environment</key>
<string>development</string> <!-- ou 'production' pour release -->
```

### Vérifier le Bundle Identifier
- Doit correspondre exactement à celui configuré dans Firebase Console
- Actuellement : `com.mycompany.Personnes` (à vérifier)

## 📱 **TEST APRÈS CONFIGURATION**

1. **Nettoyer et rebuilder** :
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --debug
   ```

2. **Redéployer sur iPhone** :
   ```bash
   flutter install --debug
   ```

3. **Tester avec la page "🚀 Test ULTIME"** :
   - Bouton rocket 🚀 dans l'interface d'administration
   - Cette page teste TOUTES les méthodes possibles

## 🔍 **VÉRIFICATIONS SUPPLÉMENTAIRES**

### Vérifier le GoogleService-Info.plist
```bash
ls -la ios/Runner/GoogleService-Info.plist
```
Le fichier doit exister et contenir les bonnes clés du projet Firebase.

### Vérifier les permissions iOS
- **Réglages** → **Notifications** → **Votre App**
- Toutes les permissions doivent être activées

### Vérifier le mode développement
- **Réglages** → **Confidentialité et sécurité** → **Mode développeur**
- Doit être activé pour les tests

## 🚨 **SI LE PROBLÈME PERSISTE**

### Option 1 : Mode de fallback
La page "Test ULTIME" peut fonctionner SANS token APNS en mode dégradé.

### Option 2 : Recréer les certificats
1. Supprimer les certificats actuels dans Firebase Console
2. Régénérer un nouveau certificat APNs
3. Reuploader dans Firebase

### Option 3 : Nouveau profil de provisioning
1. Dans Xcode → **"Automatically manage signing"** OFF puis ON
2. Forcer la régénération du profil

## 📊 **ORDRE DE PRIORITÉ DES TESTS**

1. **🚀 Test ULTIME** (essaie toutes les méthodes)
2. **🩹 Test iOS CORRIGÉ** (avec retry APNS)
3. **🐛 Test Simple** (basique)
4. **⚙️ Diagnostic** (permissions)

## 🎯 **RÉSULTAT ATTENDU**

Après configuration correcte, vous devriez voir :
```
✅ Token APNS obtenu: abc123def4...
✅ Token FCM obtenu: xyz789ghi0...
✅ Notification envoyée avec succès!
```

---
*Configuration requise pour résoudre le problème APNS sur iOS*
