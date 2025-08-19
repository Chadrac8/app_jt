# Guide de Configuration - Domaine app.jubiletabernacle.org

## 🚨 **Problème Identifié**

Le domaine `app.jubiletabernacle.org` pointe actuellement vers **Hostinger/PHP** au lieu de **Firebase Hosting**.

**État actuel :**
- ❌ `app.jubiletabernacle.org` → Serveur Hostinger (PHP/8.2.28)
- ✅ `hjye25u8iwm0i0zls78urffsc0jcgj.web.app` → Application Firebase (fonctionne parfaitement)

---

## 🔧 **Solutions pour Configurer le Domaine**

### **📋 Option 1 : Configuration via Firebase Console (RECOMMANDÉE)**

1. **Accédez à la console Firebase :**
   ```
   https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/hosting
   ```

2. **Ajoutez le domaine personnalisé :**
   - Cliquez sur **"Ajouter un domaine personnalisé"**
   - Entrez : `app.jubiletabernacle.org`
   - Cliquez sur **"Continuer"**

3. **Vérification de propriété :**
   - Firebase vous donnera un enregistrement TXT à ajouter
   - Ajoutez cet enregistrement TXT dans votre DNS
   - Cliquez sur **"Vérifier"**

4. **Configuration finale :**
   - Firebase vous donnera les enregistrements A ou CNAME à configurer
   - Remplacez la configuration Hostinger actuelle par ces enregistrements

### **📋 Option 2 : Configuration DNS Directe**

Si vous préférez configurer directement le DNS :

**Supprimez d'abord :**
- L'enregistrement A actuel pointant vers Hostinger

**Ajoutez :**
```
Type: CNAME
Nom: app
Valeur: hjye25u8iwm0i0zls78urffsc0jcgj.web.app
```

**OU (si CNAME non supporté) :**
```
Type: A
Nom: app
Valeur: 199.36.158.100
```

---

## ⚠️ **Points Importants**

### **1. Suppression de la Configuration Actuelle**
Avant d'ajouter Firebase, vous devez **supprimer** la configuration Hostinger actuelle qui fait pointer `app.jubiletabernacle.org` vers leur serveur PHP.

### **2. Propagation DNS**
- **Délai :** 24-48 heures maximum
- **Vérification :** Utilisez `nslookup app.jubiletabernacle.org`
- **Test :** `curl -I https://app.jubiletabernacle.org`

### **3. Certificat SSL**
Firebase configurera **automatiquement** le certificat SSL pour votre domaine.

---

## 🧪 **Tests de Vérification**

### **Pendant la Configuration :**
```bash
# Vérifier la propagation DNS
nslookup app.jubiletabernacle.org

# Tester l'accessibilité
curl -I https://app.jubiletabernacle.org

# Vérifier que Firebase répond (après configuration)
curl -s https://app.jubiletabernacle.org | grep -i flutter
```

### **Avec nos Scripts :**
```bash
# Diagnostic complet
./fix-domain.sh

# Vérification finale
./verify-jubile.sh
```

---

## 📱 **En Attendant la Configuration**

Votre application est **parfaitement fonctionnelle** sur :
- **URL directe :** https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app

Toutes les fonctionnalités sont disponibles :
- ✅ Gestion des formulaires avec URLs personnalisées
- ✅ Style Apple pour l'AppBar
- ✅ PWA configurée
- ✅ Performance optimisée

---

## 🎯 **Timeline Attendu**

1. **Immédiat :** Configuration du domaine dans Firebase Console
2. **5-15 minutes :** Vérification de propriété
3. **1-6 heures :** Propagation DNS initiale
4. **24-48 heures :** Propagation DNS mondiale complète
5. **Automatique :** Activation du certificat SSL par Firebase

---

## 🔗 **Liens Utiles**

- **Console Firebase :** https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/hosting
- **App actuelle :** https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app
- **Documentation Firebase :** https://firebase.google.com/docs/hosting/custom-domain
- **Test DNS :** https://whatsmydns.net/#CNAME/app.jubiletabernacle.org

---

## 🏛️ **Action Requise**

**Pour résoudre le problème :**
1. Accédez à la console Firebase Hosting
2. Ajoutez `app.jubiletabernacle.org` comme domaine personnalisé
3. Suivez les instructions de vérification DNS
4. Remplacez la configuration Hostinger par Firebase

**Une fois configuré, votre application sera accessible sur `https://app.jubiletabernacle.org` avec tous les avantages de Firebase Hosting !**
