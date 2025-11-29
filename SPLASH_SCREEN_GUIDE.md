# 🎨 Système de Splash Screen Professionnel

## Vue d'ensemble

Le système de splash screen de **Jubilé Tabernacle France** offre une expérience de lancement professionnelle et fluide avec :

- ✅ **Animations fluides** : Fade-in, scale et shimmer effect
- ✅ **Mode clair/sombre** : Adaptation automatique au thème système
- ✅ **Messages contextuels** : Indications précises de l'état de chargement
- ✅ **Design cohérent** : Respecte la charte graphique de l'application
- ✅ **Performance optimisée** : Transitions sans à-coups

## 🎯 Points d'utilisation

### 1. **Lancement initial de l'app**
```dart
// lib/churchflow_splash.dart
ChurchFlowAppWithSplash(firebaseReady: firebaseReady)
```
- Affiche le splash pendant l'initialisation de Firebase
- Message : "Initialisation de Firebase..."

### 2. **Connexion utilisateur**
```dart
// lib/auth/auth_wrapper.dart
ProfessionalSplashScreen(
  message: 'Vérification de l\'authentification...',
  showProgress: true,
)
```
Messages contextuels :
- "Vérification de l'authentification..."
- "Chargement de votre profil..."
- "Préparation de l'interface..."

### 3. **Chargement de profil**
```dart
ProfessionalSplashScreen(
  message: 'Chargement de votre profil...',
  showProgress: true,
)
```

## 🎨 Composants visuels

### Logo avec effets
- **Container circulaire** avec ombre portée
- **Image du logo** : `assets/logo_jt.png`
- **Effet shimmer** : Animation continue subtile
- **Scale animation** : Apparition douce

### Texte d'identité
- **Nom principal** : "Jubilé Tabernacle" (Poppins, 28px, semi-bold)
- **Sous-titre** : "France" (Inter, 16px, letterspacing 2.0)

### Indicateur de chargement
- **CircularProgressIndicator** personnalisé
- **Couleur** : primaryColor (#860505)
- **Stroke width** : 2.5px pour un look moderne

### Particules d'arrière-plan
- **Cercles subtils** positionnés aléatoirement
- **Opacité** : 3% (clair) / 2% (sombre)
- **Effet** : Profondeur et modernité

## 🔧 Configuration

### Android (Splash Natif)

#### Jour
**Fichier** : `android/app/src/main/res/drawable/launch_background.xml`
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launcher_icon" />
    </item>
</layer-list>
```

#### Nuit
**Fichier** : `android/app/src/main/res/drawable-night/launch_background_night.xml`
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#121212" />
        </shape>
    </item>
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launcher_icon" />
    </item>
</layer-list>
```

### iOS (Info.plist)

Le splash iOS est géré via le LaunchScreen.storyboard natif.

## 📱 Couleurs

| Élément | Couleur | Usage |
|---------|---------|-------|
| **Background (Jour)** | `#FFFFFF` → `#EEEEEE` | Gradient subtil blanc |
| **Background (Nuit)** | `#000000` → `#0D0D0D` | Gradient subtil noir |
| **Primary Color** | `#860505` | Logo, indicateur, accents |
| **Texte (Jour)** | `#000000` | Titre principal |
| **Texte (Nuit)** | `#FFFFFF` | Titre principal |
| **Texte secondaire** | 60-70% opacité | Sous-titre et messages |

## ⚡ Animations

### Timeline des animations
```
0ms ────────> Début
   │
300ms ───────> Fade-in commence
   │
800ms ───────> Fade-in terminé
   │
1000ms ──────> Scale terminé
   │
Continue ───> Shimmer en boucle (2s)
```

### Paramètres d'animation
- **Fade duration** : 800ms (easeInOut)
- **Scale duration** : 1000ms (easeOutBack)
- **Shimmer duration** : 2000ms (loop, easeInOut)
- **Fade in image** : 300ms
- **Fade out image** : 100ms

## 🚀 Utilisation avancée

### Avec progression déterminée
```dart
ProfessionalSplashScreen(
  message: 'Téléchargement des données...',
  showProgress: true,
  progress: 0.65, // 65%
)
```

### Sans indicateur
```dart
ProfessionalSplashScreen(
  message: 'Initialisation...',
  showProgress: false,
)
```

### Wrapper d'authentification
```dart
AuthSplashWrapper(
  child: YourMainWidget(),
)
```

## 🎯 Best Practices

1. **Messages courts et clairs** : Max 3-4 mots
2. **Durée appropriée** : 
   - Minimum 500ms pour percevoir l'animation
   - Maximum 3s pour ne pas frustrer l'utilisateur
3. **Transitions fluides** : Toujours avec fade
4. **Feedback visuel** : Toujours montrer un indicateur lors d'opérations > 500ms

## 📦 Dépendances

- `google_fonts` : Polices Poppins et Inter
- `flutter/material.dart` : Animations et widgets

## 🔄 Cycle de vie

```
App Start
    ↓
[Splash Natif Android/iOS]
    ↓
Firebase Init
    ↓
[ProfessionalSplashScreen] "Initialisation Firebase..."
    ↓
Auth Check
    ↓
[ProfessionalSplashScreen] "Vérification connexion..."
    ↓
Profile Load
    ↓
[ProfessionalSplashScreen] "Chargement profil..."
    ↓
UI Ready
    ↓
[Main App]
```

## 🎨 Personnalisation

Pour modifier le splash :

1. **Logo** : Remplacez `assets/logo_jt.png`
2. **Couleurs** : Éditez `AppTheme` dans `theme.dart`
3. **Textes** : Modifiez `lib/widgets/professional_splash_screen.dart`
4. **Animations** : Ajustez les durées dans `initState()`

## 📝 Notes

- Le splash s'adapte automatiquement au mode clair/sombre
- Les animations sont optimisées pour 60 FPS
- Le shimmer est subtil pour ne pas distraire
- Version affichée en bas : `Version 1.0.0`

## ✅ Checklist de déploiement

- [ ] Tester en mode clair
- [ ] Tester en mode sombre
- [ ] Vérifier sur petit écran (< 5")
- [ ] Vérifier sur grand écran (> 6.5")
- [ ] Tester la transition vers l'app
- [ ] Vérifier les messages de chargement
- [ ] Tester la progression (si utilisée)
- [ ] Valider sur Android
- [ ] Valider sur iOS
- [ ] Vérifier les performances (pas de lag)

---

**Créé avec ❤️ pour Jubilé Tabernacle France**
