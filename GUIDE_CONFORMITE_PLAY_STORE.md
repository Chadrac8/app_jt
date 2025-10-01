# GUIDE CONFORMITÉ PLAY STORE - Jubilé Tabernacle

## 📋 CHECKLIST CONFORMITÉ PLAY STORE

### ✅ CONFIGURATION TECHNIQUE

#### 1. Configuration App Bundle (AAB)
- ✅ Configuration signing release
- ✅ Target API Level 34 minimum (Android 14)
- ✅ Version format correcte (1.0.0+1)

#### 2. Permissions et Sécurité
- ✅ Permissions justifiées et documentées
- ✅ HTTPS obligatoire
- ✅ Déclarations de données utilisateur

#### 3. Métadonnées App
- ✅ Nom d'application approprié
- ✅ Description complète
- ✅ Icônes haute résolution
- ✅ Captures d'écran conformes

### ✅ CONTENU ET POLITIQUE

#### 1. Politique de Confidentialité
- ✅ URL publique accessible : https://chadrac8.github.io/app_jt/
- ✅ Conformité RGPD
- ✅ Collecte des données expliquée

#### 2. Classification du Contenu
- ✅ Classification "Tout public" appropriée
- ✅ Contenu religieux/spirituel déclaré
- ✅ Pas de contenu sensible

### ✅ FONCTIONNALITÉS REQUISES

#### 1. API Target Level
- ✅ compileSdkVersion 34
- ✅ targetSdkVersion 34
- ✅ minSdkVersion 21

#### 2. App Bundle
- ✅ Configuration AAB pour Play Store
- ✅ Proguard activé pour la release
- ✅ Signature de release configurée

## 🔧 MODIFICATIONS TECHNIQUES APPLIQUÉES

### 1. build.gradle - API Level et Configuration
```gradle
android {
    compileSdk = 34
    
    defaultConfig {
        targetSdkVersion = 34
        minSdkVersion = 21
    }
    
    buildTypes {
        release {
            minifyEnabled = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. AndroidManifest.xml - Permissions et Métadonnées
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<application
    android:label="Jubilé Tabernacle"
    android:requestLegacyExternalStorage="false"
    android:allowBackup="true"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules">
```

### 3. Déclarations de Données (Data Safety)
- Collecte de données : Email, préférences utilisateur
- Utilisation : Authentification, personnalisation
- Partage : Firebase (Google)
- Chiffrement : En transit et au repos

## 📱 CAPTURES D'ÉCRAN PLAY STORE

### Formats Requis
- Phone : 1080 x 1920 pixels (16:9)
- Tablet : 1200 x 1920 pixels
- Format JPG ou PNG
- Minimum 2, maximum 8 captures

### Contenu Recommandé
1. Écran d'accueil avec menu principal
2. Section Pain Quotidien
3. Lecteur audio sermon
4. Calendrier événements
5. Interface prière communautaire

## 🚀 DÉPLOIEMENT PLAY STORE

### 1. Génération AAB
```bash
flutter build appbundle --release
```

### 2. Test Internal/Alpha
- Upload sur Play Console
- Test avec utilisateurs internes
- Vérification des APIs

### 3. Publication Production
- Remplir tous les champs obligatoires
- Ajouter captures d'écran
- Configuration prix et distribution
- Soumission pour révision

## ⚠️ POINTS D'ATTENTION

### 1. Révision Google
- Délai : 1-3 jours ouvrés
- Possible rejet pour contenu religieux mal classifié
- Vérification politique de confidentialité

### 2. Mises à jour
- Target API obligatoire mise à jour annuelle
- Nouvelles permissions = nouvelle révision
- AAB obligatoire depuis août 2021

### 3. Conformité Continue
- Monitoring des nouvelles politiques
- Mise à jour politique confidentialité
- Respect des guidelines contenu

## 📞 SUPPORT

En cas de rejet :
1. Lire attentivement les commentaires Google
2. Corriger les points mentionnés
3. Re-soumettre avec notes explicatives
4. Contacter support Play Console si nécessaire

---
*Guide généré le 1er octobre 2025 - Version 1.0*
*Application : Jubilé Tabernacle France*