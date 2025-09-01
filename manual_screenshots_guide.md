# SCRIPT MANUEL DE CAPTURES D'ÉCRAN
## Jubilé Tabernacle - Guide Pratique

### 🚀 PRÉPARATION

#### 1. Configuration de l'appareil
```bash
# Configurer l'heure et la batterie
# iOS : Réglages > Général > Date et heure > 9:41
# Android : Réglages > Système > Date et heure > 9:41

# Batterie à 100%
# Signal réseau complet
# Mode avion OFF
# Notifications effacées
```

#### 2. Lancement de l'application
```bash
# Compiler en mode release
flutter build ios --release
flutter build apk --release

# Ou lancer en debug pour tests
flutter run -d "device-id"
```

### 📱 SÉQUENCE DE CAPTURES

#### CAPTURE 1 : Écran d'accueil
- **Navigation :** Page principale après connexion
- **Éléments visibles :**
  - Logo Jubilé Tabernacle
  - 4 modules principaux
  - Interface moderne
  - Menu de navigation
- **Action :** Capture immédiate
- **Nom fichier :** `01_accueil_principal.png`

#### CAPTURE 2 : Bible & Message  
- **Navigation :** Taper sur "Bible & Message"
- **Éléments visibles :**
  - Interface de lecture biblique
  - Outils d'étude
  - Pépites d'or
  - Favoris et signets
- **Action :** Attendre 2s puis capture
- **Nom fichier :** `02_bible_message.png`

#### CAPTURE 3 : Vie de l'Église
- **Navigation :** Retour > "Vie de l'Église"
- **Éléments visibles :**
  - Onglets (Sermons, Prières, etc.)
  - Contenu communautaire
  - Design moderne
- **Action :** Capture de la vue d'ensemble
- **Nom fichier :** `03_vie_eglise.png`

#### CAPTURE 4 : Pain Quotidien
- **Navigation :** Retour > "Pain Quotidien"
- **Éléments visibles :**
  - Citation du jour
  - Date actuelle
  - Citation de William Branham
  - Interface inspirante
- **Action :** Capture avec contenu du jour
- **Nom fichier :** `04_pain_quotidien.png`

#### CAPTURE 5 : Prières & Témoignages (OPTIMISÉ)
- **Navigation :** "Vie de l'Église" > Onglet "Prières"
- **Éléments visibles :**
  - Filtres compacts (NOUVEAUX)
  - Mur de prière
  - Interface épurée (SANS CONTENEURS)
  - Témoignages
- **Action :** Montrer les filtres optimisés
- **Nom fichier :** `05_prieres_optimise.png`

#### CAPTURE 6 : Pour Vous
- **Navigation :** Retour > "Pour Vous"
- **Éléments visibles :**
  - Services personnalisés
  - Fonctionnalités avancées
  - Actions rapides
- **Action :** Capture des fonctionnalités
- **Nom fichier :** `06_pour_vous.png`

### 🎯 COMMANDES AUTOMATISÉES

#### iOS Simulator
```bash
# Démarrer le simulateur
open -a Simulator

# Sélectionner l'appareil
xcrun simctl list devices

# Prendre captures
xcrun simctl io booted screenshot capture_01.png

# Ou avec raccourci
Cmd + S dans Simulator
```

#### Android Emulator
```bash
# Démarrer émulateur
emulator -avd Pixel_4_API_31

# Prendre capture via ADB
adb shell screencap -p /sdcard/capture.png
adb pull /sdcard/capture.png

# Ou via Android Studio
Extended Controls > Camera > Screenshot
```

### 📐 REDIMENSIONNEMENT

#### Commandes ImageMagick
```bash
# Installer ImageMagick
brew install imagemagick

# iPhone 6.7" (1290x2796)
convert input.png -resize 1290x2796 output_iphone_67.png

# iPhone 6.5" (1242x2688)  
convert input.png -resize 1242x2688 output_iphone_65.png

# Android Phone (1080x1920)
convert input.png -resize 1080x1920 output_android_phone.png

# Optimiser qualité
convert input.png -quality 90 -strip output.png
```

#### Script de redimensionnement automatique
```bash
#!/bin/bash

INPUT_DIR="captures_raw"
OUTPUT_DIR="captures_final"

# Créer dossiers de sortie
mkdir -p $OUTPUT_DIR/{ios/{iphone_67,iphone_65,ipad_129,ipad_11},android/{phone,tablet}}

# Redimensionner pour chaque format
for image in $INPUT_DIR/*.png; do
    filename=$(basename "$image" .png)
    
    # iOS iPhone 6.7"
    convert "$image" -resize 1290x2796 "$OUTPUT_DIR/ios/iphone_67/${filename}_1290x2796.png"
    
    # iOS iPhone 6.5"
    convert "$image" -resize 1242x2688 "$OUTPUT_DIR/ios/iphone_65/${filename}_1242x2688.png"
    
    # iOS iPad 12.9"
    convert "$image" -resize 2048x2732 "$OUTPUT_DIR/ios/ipad_129/${filename}_2048x2732.png"
    
    # iOS iPad 11"
    convert "$image" -resize 1668x2388 "$OUTPUT_DIR/ios/ipad_11/${filename}_1668x2388.png"
    
    # Android Phone
    convert "$image" -resize 1080x1920 "$OUTPUT_DIR/android/phone/${filename}_1080x1920.png"
    
    # Android Tablet
    convert "$image" -resize 1200x1920 "$OUTPUT_DIR/android/tablet/${filename}_1200x1920.png"
done

echo "✅ Redimensionnement terminé"
```

### 🎨 AJOUT DE TEXTE MARKETING

#### Script avec textes
```bash
#!/bin/bash

# Ajouter titre et description aux captures
add_marketing_text() {
    local input=$1
    local title=$2
    local description=$3
    local output=$4
    
    convert "$input" \
        -gravity North -pointsize 60 -fill "#6B73FF" \
        -annotate +0+50 "$title" \
        -gravity North -pointsize 30 -fill "#333333" \
        -annotate +0+150 "$description" \
        "$output"
}

# Appliquer à chaque capture
add_marketing_text "01_accueil.png" "Jubilé Tabernacle" "Votre compagnon spirituel quotidien" "01_accueil_marketing.png"

add_marketing_text "02_bible.png" "Bible Interactive" "Étudiez la Parole avec des outils modernes" "02_bible_marketing.png"

add_marketing_text "05_prieres.png" "Prières Optimisées" "Interface épurée pour plus d'espace" "05_prieres_marketing.png"
```

### 📋 CHECKLIST FINALE

#### Avant publication
- [ ] 6-8 captures par plateforme
- [ ] Tailles exactes respectées
- [ ] Qualité optimale (90%+)
- [ ] Textes lisibles et corrects
- [ ] Contenu représentatif
- [ ] Ordre logique des captures
- [ ] Métadonnées ajoutées

#### Validation stores
- [ ] Prévisualisation App Store Connect
- [ ] Prévisualisation Google Play Console
- [ ] Test sur différents appareils
- [ ] Vérification des ratios d'aspect
- [ ] Optimisation des couleurs

### 🎯 RÉSULTAT ATTENDU

```
screenshots_final/
├── ios/
│   ├── iphone_67/        # 6 captures 1290x2796
│   ├── iphone_65/        # 6 captures 1242x2688
│   ├── ipad_129/         # 6 captures 2048x2732
│   └── ipad_11/          # 6 captures 1668x2388
└── android/
    ├── phone/            # 6 captures 1080x1920
    └── tablet/           # 6 captures 1200x1920
```

**Total :** 36 captures d'écran optimisées pour tous les appareils et stores !

---

**Note :** Suivez cette séquence méthodiquement pour obtenir des captures d'écran professionnelles qui maximiseront les téléchargements de Jubilé Tabernacle.
