# 📱 GÉNÉRATEUR DE CAPTURES D'ÉCRAN
## Jubilé Tabernacle - App Store & Play Store

### 🚀 UTILISATION RAPIDE

```bash
# 1. Prendre vos captures manuellement et les placer dans captures_raw/
# 2. Lancer la génération automatique
./master_screenshots.sh
```

C'est tout ! Le script fait le reste automatiquement.

---

### 📋 PRÉREQUIS

#### Outils requis :
```bash
# Flutter (pour l'application)
flutter --version

# ImageMagick (pour le redimensionnement)
brew install imagemagick

# Optionnel: ExifTool (pour les métadonnées)
brew install exiftool
```

#### Structure attendue :
```
app_jubile_tabernacle/
├── captures_raw/           # VOS CAPTURES ICI
│   ├── 01_accueil.png
│   ├── 02_bible.png
│   └── ...
├── master_screenshots.sh   # Script principal
├── resize_screenshots.sh   # Redimensionnement
├── add_marketing_text.sh   # Texte marketing
└── manual_screenshots_guide.md  # Guide manuel
```

---

### 📸 COMMENT PRENDRE LES CAPTURES

#### 1. Préparer votre appareil :
- ⏰ Heure : 9:41 (standard)
- 🔋 Batterie : 100%
- 📶 Signal : Complet
- 🔕 Notifications : Supprimées

#### 2. Lancer votre app :
```bash
flutter run -d "votre-device-id"
```

#### 3. Prendre 6-8 captures :
1. **01_accueil.png** - Page d'accueil principale
2. **02_bible.png** - Module Bible & Message
3. **03_vie_eglise.png** - Module Vie de l'Église
4. **04_pain_quotidien.png** - Pain Quotidien
5. **05_prieres.png** - Prières & Témoignages (filtres optimisés)
6. **06_pour_vous.png** - Module Pour Vous
7. **07_config.png** - Configuration (optionnel)
8. **08_profil.png** - Profil utilisateur (optionnel)

#### 4. Placer dans captures_raw/ :
```bash
mkdir -p captures_raw
# Copier vos captures PNG dans ce dossier
```

---

### 🛠️ SCRIPTS DISPONIBLES

#### **master_screenshots.sh** (Principal)
Génération automatique complète :
```bash
./master_screenshots.sh
```
✅ Vérifie les prérequis  
✅ Redimensionne pour tous formats  
✅ Ajoute texte marketing (optionnel)  
✅ Génère rapport et aperçu HTML  

#### **resize_screenshots.sh** (Redimensionnement)
Redimensionnement uniquement :
```bash
./resize_screenshots.sh captures_raw captures_final
```

#### **add_marketing_text.sh** (Marketing)
Ajout de texte marketing :
```bash
./add_marketing_text.sh captures_final captures_marketing
```

---

### 📐 FORMATS GÉNÉRÉS

#### **iOS App Store :**
- 📱 iPhone 6.7" : 1290 x 2796 px (iPhone 15 Pro Max)
- 📱 iPhone 6.5" : 1242 x 2688 px (iPhone 15)
- 📱 iPad 12.9" : 2048 x 2732 px (iPad Pro)
- 📱 iPad 11" : 1668 x 2388 px (iPad Pro)

#### **Android Play Store :**
- 📱 Phone : 1080 x 1920 px (Standard)
- 📱 Tablet : 1200 x 1920 px (7-10 pouces)

---

### 📂 STRUCTURE DE SORTIE

```
captures_final/          # Images pour stores
├── ios/
│   ├── iphone_67/      # iPhone Pro Max
│   ├── iphone_65/      # iPhone Standard  
│   ├── ipad_129/       # iPad Pro 12.9"
│   └── ipad_11/        # iPad Pro 11"
└── android/
    ├── phone/          # Téléphones Android
    └── tablet/         # Tablettes Android

captures_marketing/      # Images avec texte (optionnel)
├── ios/...
├── android/...
├── clean/              # Versions sans texte
└── apercu.html         # Aperçu web
```

---

### 🎨 TEXTES MARKETING AUTOMATIQUES

Les textes suivants sont ajoutés automatiquement :

| Capture | Titre | Description |
|---------|-------|-------------|
| 01_accueil | Jubilé Tabernacle | Votre compagnon spirituel quotidien |
| 02_bible | Bible Interactive | Étudiez la Parole avec des outils modernes |
| 03_vie_eglise | Vie de l'Église | Connectez-vous avec votre communauté |
| 04_pain_quotidien | Pain Quotidien | Inspiration spirituelle chaque jour |
| 05_prieres | Prières & Témoignages | Interface optimisée, plus d'espace |
| 06_pour_vous | Pour Vous | Fonctionnalités personnalisées |

---

### 🔧 DÉPANNAGE

#### ❌ "ImageMagick n'est pas installé"
```bash
brew install imagemagick
```

#### ❌ "Aucune capture trouvée"
Vérifiez que vos fichiers PNG sont dans `captures_raw/`

#### ❌ "Flutter n'est pas installé"
Installez Flutter : https://flutter.dev/docs/get-started/install

#### ⚠️ Qualité d'image faible
Augmentez la qualité dans `resize_screenshots.sh` :
```bash
QUALITY=95  # Au lieu de 90
```

#### 🎨 Personnaliser les textes marketing
Modifiez le tableau `MARKETING_TEXTS` dans `add_marketing_text.sh`

---

### 📊 VALIDATION FINALE

#### Avant publication :
- [ ] ✅ Toutes les tailles générées
- [ ] ✅ Qualité d'image optimale
- [ ] ✅ Textes lisibles
- [ ] ✅ Contenu représentatif
- [ ] ✅ Métadonnées ajoutées

#### Test sur stores :
- [ ] 📱 Prévisualisation App Store Connect
- [ ] 📱 Prévisualisation Google Play Console
- [ ] 📱 Test affichage différents appareils

---

### 🎯 RÉSULTATS ATTENDUS

**Avec ce système, vous obtenez :**
- ✅ **36 images** optimisées (6 captures × 6 formats)
- ✅ **Qualité professionnelle** pour stores
- ✅ **Conformité** aux spécifications iOS/Android
- ✅ **Versions marketing** pour publicités
- ✅ **Rapport détaillé** de génération
- ✅ **Aperçu HTML** interactif

---

### 💡 CONSEILS AVANCÉS

#### Pour de meilleures captures :
- 🌟 Utilisez des données attractives (pas de Lorem Ipsum)
- 🎨 Assurez-vous que l'interface est complètement chargée
- 📱 Testez sur différents appareils avant de capturer
- 🔄 Prenez plusieurs versions et choisissez les meilleures

#### Pour optimiser les téléchargements :
- 📈 Première capture = accrocheuse (conversions)
- 🎯 Montrez les fonctionnalités principales
- 👥 Incluez éléments de communauté
- ⭐ Mettez en avant les nouveautés (filtres optimisés)

---

**🏁 Votre application Jubilé Tabernacle est maintenant prête pour conquérir l'App Store et le Play Store !**
